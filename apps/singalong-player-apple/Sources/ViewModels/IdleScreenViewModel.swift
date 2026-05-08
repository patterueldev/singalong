import Foundation

/// ViewModel for the Idle Screen (player discovery phase)
@MainActor
final class IdleScreenViewModel: ObservableObject {
    
    @Published private(set) var discoveredNodes: [DiscoveredNode] = []
    @Published private(set) var activeConnections: [String: NodeConnectionStatus] = [:]
    @Published private(set) var isDiscovering = false
    @Published private(set) var errorMessage: String?
    
    var currentPhase: PlayerPhase = .idle
    
    private let discoveryCoordinator: DiscoveryCoordinator
    private let dependencyContainer: DependencyContainer
    private let appState: PlayerAppState
    
    init(discoveryCoordinator: DiscoveryCoordinator, dependencyContainer: DependencyContainer, appState: PlayerAppState) {
        self.discoveryCoordinator = discoveryCoordinator
        self.dependencyContainer = dependencyContainer
        self.appState = appState
        setupCallbacks()
    }
    
    private func setupCallbacks() {
        print("[IdleScreenViewModel] Setting up onConnectionStatusChanged callback...")
        discoveryCoordinator.onConnectionStatusChanged = { [weak self] nodeId, status in
            print("[IdleScreenViewModel] 🔔 CALLBACK FIRED: nodeId=\(nodeId), status=\(status)")
            guard let self = self else {
                print("[IdleScreenViewModel] ⚠️ Self was deallocated, callback not executed")
                return
            }
            print("[IdleScreenViewModel] Current activeConnections before update: \(self.activeConnections)")
            
            // Must reassign the entire dictionary to trigger @Published notification
            // (direct mutations don't notify subscribers)
            var updated = self.activeConnections
            updated[nodeId] = status
            print("[IdleScreenViewModel] Updated activeConnections: \(updated)")
            
            self.activeConnections = updated
            print("[IdleScreenViewModel] ✓ @Published property reassigned, UI should update")
        }
        
        print("[IdleScreenViewModel] Setting up onPlayerLocked callback...")
        discoveryCoordinator.onPlayerLocked = { [weak self] sessionCode, token, nodeBaseUrl in
            print("[IdleScreenViewModel] 🔔 PLAYER LOCKED CALLBACK: sessionCode=\(sessionCode) nodeUrl=\(nodeBaseUrl)")
            guard let self = self else {
                print("[IdleScreenViewModel] ⚠️ Self was deallocated, callback not executed")
                return
            }
            
            if let connectedNodeId = self.activeConnections.first(where: { $0.value == .waiting })?.key {
                print("[IdleScreenViewModel] Sending acknowledgment for node: \(connectedNodeId)")
                Task {
                    await self.discoveryCoordinator.acknowledgePlayerLocked(
                        nodeId: connectedNodeId,
                        sessionCode: sessionCode
                    )
                }
            }
            
            self.currentPhase = .locked
            print("[IdleScreenViewModel] ✓ Player locked to session: \(sessionCode)")
            
            print("[IdleScreenViewModel] Transitioning to main screen for session: \(sessionCode)")
            self.appState.transitionToMainScreen(sessionCode: sessionCode, sessionToken: token, nodeBaseUrl: nodeBaseUrl)
            print("[IdleScreenViewModel] ✓ App transitioned to main screen")
        }
        
        print("[IdleScreenViewModel] ✓ Callback setup complete")
    }
    
    func startDiscovery() {
        guard !isDiscovering else { return }
        isDiscovering = true
        errorMessage = nil
        // Reset state so nodes discovered in a previous session don't block auto-connect
        discoveredNodes = []
        activeConnections = [:]
        
        Task {
            do {
                try await discoveryCoordinator.startDiscovery { [weak self] node in
                    self?.handleNodeDiscovered(node)
                }
            } catch {
                self.isDiscovering = false
                self.errorMessage = "Discovery failed: \(error.localizedDescription)"
            }
        }
    }
    
    func stopDiscovery() {
        guard isDiscovering else { return }
        isDiscovering = false
        
        Task {
            await discoveryCoordinator.stopDiscovery()
        }
    }
    
    func selectNode(_ node: DiscoveredNode) {
        print("[IdleScreenViewModel] selectNode() called for node: \(node.name)")
        errorMessage = nil
        
        Task {
            print("[IdleScreenViewModel] selectNode Task started, calling coordinator.selectNode()...")
            do {
                print("[IdleScreenViewModel] About to await discoveryCoordinator.selectNode(node)")
                try await discoveryCoordinator.selectNode(node)
                print("[IdleScreenViewModel] ✓ selectNode completed successfully")
            } catch {
                print("[IdleScreenViewModel] ✗ selectNode failed with error: \(error)")
                print("[IdleScreenViewModel]   Error description: \(error.localizedDescription)")
                self.errorMessage = "Failed to select node: \(error.localizedDescription)"
            }
        }
        print("[IdleScreenViewModel] selectNode() exiting (Task scheduled)")
    }
    
    func deselectNode() {
        Task {
            await discoveryCoordinator.deselectNode()
        }
    }
    
    private func handleNodeDiscovered(_ node: DiscoveredNode) {
        print("[IdleScreenViewModel] handleNodeDiscovered() called for: \(node.name)")
        
        if !discoveredNodes.contains(where: { $0.id == node.id }) {
            print("[IdleScreenViewModel] Node is new, adding to list: \(node.name)")
            discoveredNodes.append(node)
            
            // Automatically connect to discovered node via WebSocket
            print("[IdleScreenViewModel] Automatically connecting to discovered node...")
            Task {
                do {
                    print("[IdleScreenViewModel] Auto-connecting to: \(node.name)")
                    try await discoveryCoordinator.selectNode(node)
                    print("[IdleScreenViewModel] ✓ Auto-connection to \(node.name) initiated")
                } catch {
                    print("[IdleScreenViewModel] ✗ Auto-connection failed: \(error)")
                    // Discovery WS may be locked (player already assigned to a session)
                    // Try HTTP reconnect to check if this player has an active session
                    await tryReconnectViaHTTP(node: node)
                }
            }
        } else {
            print("[IdleScreenViewModel] Node already in list, skipping: \(node.name)")
        }
    }
    
    /// Called when discovery WS is rejected (e.g., locked because a player is already assigned).
    /// Checks via HTTP if this player is that assigned player and restores the session if so.
    private func tryReconnectViaHTTP(node: DiscoveredNode) async {
        guard let playerId = appState.playerId,
              let httpBase = node.nodeHTTPBaseURL,
              let nodeBaseURL = node.nodeBaseURL,
              let url = URL(string: "\(httpBase)/api/players/reconnect") else {
            errorMessage = "Cannot connect to node"
            return
        }
        
        print("[IdleScreenViewModel] Attempting HTTP reconnect: playerId=\(playerId) url=\(url)")
        
        let body: [String: Any] = [
            "player_id": playerId,
            "name": getDeviceName(),
            "platform": getPlatformName(),
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                errorMessage = "Cannot connect to node"
                return
            }
            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                errorMessage = "Cannot connect to node"
                return
            }
            
            let status = json["status"] as? String
            if status == "reconnected",
               let sessionCode = json["session_code"] as? String,
               let sessionToken = json["session_token"] as? String {
                print("[IdleScreenViewModel] ✓ Reconnected to session \(sessionCode) via HTTP")
                appState.transitionToMainScreen(
                    sessionCode: sessionCode,
                    sessionToken: sessionToken,
                    nodeBaseUrl: nodeBaseURL
                )
            } else {
                // Node is locked to another player — just wait
                print("[IdleScreenViewModel] Node is locked to another player, waiting...")
                errorMessage = "Node is busy with another session"
            }
        } catch {
            print("[IdleScreenViewModel] ✗ HTTP reconnect failed: \(error)")
            errorMessage = "Cannot reach node: \(error.localizedDescription)"
        }
    }
    
    private func getDeviceName() -> String {
        #if os(macOS)
        return (try? Host.current().localizedName) ?? "Mac Player"
        #elseif os(iOS) || os(tvOS)
        return UIDevice.current.name
        #else
        return "Singalong Player"
        #endif
    }
    
    private func getPlatformName() -> String {
        #if os(macOS)
        return "macos"
        #elseif os(iOS)
        return UIDevice.current.userInterfaceIdiom == .pad ? "ipados" : "ios"
        #elseif os(tvOS)
        return "tvos"
        #else
        return "unknown"
        #endif
    }
    
    deinit {
        Task {
            await discoveryCoordinator.stopDiscovery()
        }
    }
}

enum PlayerPhase {
    case idle
    case locked
    case session
}
