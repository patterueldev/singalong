import Foundation

/// Coordinates the discovery phase lifecycle
/// Manages mDNS discovery and WebSocket connections to nodes
class DiscoveryCoordinator {
    
    // MARK: - Properties
    
    private let mdnsService: MDNSDiscoveryService
    private let webSocketManager: WebSocketDiscoveryManager
    
    var onNodeDiscovered: ((DiscoveredNode) -> Void)?
    var onNodeSelected: (() -> Void)?
    var onConnectionStatusChanged: ((String, NodeConnectionStatus) -> Void)?
    var onPlayerLocked: ((String, String, String) -> Void)?  // (sessionCode, token, nodeBaseUrl)
    
    private var nodeBaseUrls: [String: String] = [:]
    
    // MARK: - Initialization
    
    init(mdnsService: MDNSDiscoveryService, webSocketManager: WebSocketDiscoveryManager) {
        self.mdnsService = mdnsService
        self.webSocketManager = webSocketManager
        setupWebSocketCallbacks()
    }
    
    // MARK: - Setup
    
    private func setupWebSocketCallbacks() {
        Task {
            await webSocketManager.setOnConnectionStatusChanged { [weak self] nodeId, status in
                self?.onConnectionStatusChanged?(nodeId, status)
            }
            
            // Set up message callback to handle lock messages
            await webSocketManager.setCallback(onMessageReceived: { [weak self] nodeId, message in
                print("[DiscoveryCoordinator] Received message from \(nodeId): \(message)")
                
                if case .lock(let sessionCode, let token) = message {
                    print("[DiscoveryCoordinator] Player locked to session: \(sessionCode)")
                    let nodeUrl = self?.nodeBaseUrls[nodeId] ?? ""
                    self?.onPlayerLocked?(sessionCode, token, nodeUrl)
                }
            })
        }
    }
    
    // MARK: - Discovery Lifecycle
    
    func startDiscovery(onNodeDiscovered: @escaping (DiscoveredNode) -> Void) async throws {
        self.onNodeDiscovered = onNodeDiscovered
        
        // Bridge mDNS onNodeAdded callback to the view model callback
        await mdnsService.setCallback(onNodeAdded: onNodeDiscovered)
        
        try await mdnsService.startDiscovery()
    }
    
    func stopDiscovery() async {
        await mdnsService.stopDiscovery()
    }
    
    func selectNode(_ node: DiscoveredNode) async throws {
        print("[DiscoveryCoordinator] selectNode() called for: \(node.name)")
        print("[DiscoveryCoordinator]   Node ID: \(node.id)")
        print("[DiscoveryCoordinator]   Node Host: \(node.host)")
        print("[DiscoveryCoordinator]   Node IP: \(node.ipAddress ?? "nil")")
        print("[DiscoveryCoordinator]   Node Port: \(node.port)")
        
        // Store base URL so we can pass it through the lock callback later
        if let base = node.nodeBaseURL {
            nodeBaseUrls[node.id] = base
            print("[DiscoveryCoordinator]   Node Base URL: \(base)")
        }
        
        print("[DiscoveryCoordinator] About to call webSocketManager.connect(to:)...")
        try await webSocketManager.connect(to: node)
        print("[DiscoveryCoordinator] ✓ webSocketManager.connect() completed")
    }
    
    func acknowledgePlayerLocked(nodeId: String, sessionCode: String) async {
        print("[DiscoveryCoordinator] Acknowledging player locked for session: \(sessionCode)")
        
        let playerId = PlayerIdentityService.shared.playerId
        do {
            let message = PlayerMessage.locked(playerId: playerId)
            try await webSocketManager.send(message: message, toNodeId: nodeId)
            print("[DiscoveryCoordinator] ✓ Sent locked acknowledgment")
            
            // Close discovery connection after acknowledgment
            await closeDiscoveryConnection(for: nodeId)
        } catch {
            print("[DiscoveryCoordinator] ✗ Failed to send locked acknowledgment: \(error)")
        }
    }
    
    private func closeDiscoveryConnection(for nodeId: String) async {
        print("[DiscoveryCoordinator] Closing discovery connection for: \(nodeId)")
        await webSocketManager.disconnect(fromNodeId: nodeId)
    }
    
    func deselectNode() async {
        // Disconnect from current node
        await webSocketManager.disconnectAll()
    }
}
