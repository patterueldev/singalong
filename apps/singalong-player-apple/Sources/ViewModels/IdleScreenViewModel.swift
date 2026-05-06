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
    
    init(discoveryCoordinator: DiscoveryCoordinator, dependencyContainer: DependencyContainer) {
        self.discoveryCoordinator = discoveryCoordinator
        self.dependencyContainer = dependencyContainer
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
        discoveryCoordinator.onPlayerLocked = { [weak self] sessionCode, token in
            print("[IdleScreenViewModel] 🔔 PLAYER LOCKED CALLBACK: sessionCode=\(sessionCode)")
            guard let self = self else {
                print("[IdleScreenViewModel] ⚠️ Self was deallocated, callback not executed")
                return
            }
            
            // Store session info for playback phase
            print("[IdleScreenViewModel] Storing session code and token for playback phase")
            
            // Find the connected node ID to send acknowledgment
            // For now, find the first (and should be only) connected node
            if let connectedNodeId = self.activeConnections.first(where: { $0.value == .waiting })?.key {
                print("[IdleScreenViewModel] Sending acknowledgment for node: \(connectedNodeId)")
                Task {
                    await self.discoveryCoordinator.acknowledgePlayerLocked(
                        nodeId: connectedNodeId,
                        sessionCode: sessionCode
                    )
                }
            }
            
            // Transition to locked phase
            self.currentPhase = .locked
            print("[IdleScreenViewModel] ✓ Player locked to session: \(sessionCode)")
        }
        
        print("[IdleScreenViewModel] ✓ Callback setup complete")
    }
    
    func startDiscovery() {
        guard !isDiscovering else { return }
        isDiscovering = true
        errorMessage = nil
        
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
                    self.errorMessage = "Auto-connect failed: \(error.localizedDescription)"
                }
            }
        } else {
            print("[IdleScreenViewModel] Node already in list, skipping: \(node.name)")
        }
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
