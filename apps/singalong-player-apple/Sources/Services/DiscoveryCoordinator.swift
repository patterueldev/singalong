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
    
    // MARK: - Initialization
    
    init(mdnsService: MDNSDiscoveryService, webSocketManager: WebSocketDiscoveryManager) {
        self.mdnsService = mdnsService
        self.webSocketManager = webSocketManager
        setupWebSocketCallbacks()
    }
    
    // MARK: - Setup
    
    private func setupWebSocketCallbacks() {
        webSocketManager.onConnectionStatusChanged = { [weak self] nodeId, status in
            self?.onConnectionStatusChanged?(nodeId, status)
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
        
        print("[DiscoveryCoordinator] About to call webSocketManager.connect(to:)...")
        // Connect to the selected node via WebSocket
        try await webSocketManager.connect(to: node)
        print("[DiscoveryCoordinator] ✓ webSocketManager.connect() completed")
    }
    
    func deselectNode() async {
        // Disconnect from current node
        await webSocketManager.disconnectAll()
    }
}
