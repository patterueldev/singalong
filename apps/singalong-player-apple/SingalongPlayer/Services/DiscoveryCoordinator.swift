import Foundation

/// Coordinates the discovery phase lifecycle
/// Manages mDNS discovery and WebSocket connections to nodes
class DiscoveryCoordinator {
    
    // MARK: - Properties
    
    private let mdnsService: MDNSDiscoveryService
    private let webSocketManager: WebSocketDiscoveryManager
    
    var onNodeDiscovered: ((DiscoveredNode) -> Void)?
    var onNodeSelected: (() -> Void)?
    
    // MARK: - Initialization
    
    init(mdnsService: MDNSDiscoveryService, webSocketManager: WebSocketDiscoveryManager) {
        self.mdnsService = mdnsService
        self.webSocketManager = webSocketManager
    }
    
    // MARK: - Discovery Lifecycle
    
    func startDiscovery(onNodeDiscovered: @escaping (DiscoveredNode) -> Void) async throws {
        self.onNodeDiscovered = onNodeDiscovered
        try await mdnsService.startDiscovery()
    }
    
    func stopDiscovery() async {
        await mdnsService.stopDiscovery()
    }
    
    func selectNode(_ node: DiscoveredNode) async throws {
        // Connect to the selected node via WebSocket
        try await webSocketManager.connect(to: node)
    }
    
    func deselectNode() async {
        // Disconnect from current node
        await webSocketManager.disconnectAll()
    }
}
