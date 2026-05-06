import Foundation

/// Coordinates the discovery phase lifecycle
/// Owns mDNS service and WebSocket discovery connections
/// Extracted from PlayerAppState to follow SRP
@MainActor
class DiscoveryCoordinator {
    
    // MARK: - Properties
    
    private let mdnsService: MDNSDiscoveryService
    private let webSocketManager: WebSocketDiscoveryManager
    
    // State published through callbacks
    var onNodesUpdated: (([DiscoveredNode]) -> Void)?
    var onConnectionStatusChanged: ((String, NodeConnectionStatus) -> Void)?
    var onMessageReceived: ((String, NodeMessage) -> Void)?
    var onConnectionClosed: ((String) -> Void)?
    
    // MARK: - Initialization
    
    init(
        mdnsService: MDNSDiscoveryService = MDNSDiscoveryService.shared,
        webSocketManager: WebSocketDiscoveryManager = WebSocketDiscoveryManager.shared
    ) {
        self.mdnsService = mdnsService
        self.webSocketManager = webSocketManager
        setupCallbacks()
        print("[DiscoveryCoordinator] Initialized")
    }
    
    // MARK: - Lifecycle Management
    
    /// Start the discovery process (mDNS + WebSocket connections)
    func startDiscovery() async {
        print("[DiscoveryCoordinator] Starting discovery")
        
        // Start mDNS scanning
        await mdnsService.startDiscovery()
        
        print("[DiscoveryCoordinator] Discovery started")
    }
    
    /// Stop the discovery process
    func stopDiscovery() async {
        print("[DiscoveryCoordinator] Stopping discovery")
        
        // Stop mDNS scanning
        await mdnsService.stopDiscovery()
        
        // Close all WebSocket connections
        let nodeIds = Array(webSocketManager.activeConnections.keys)
        for nodeId in nodeIds {
            await webSocketManager.disconnect(fromNodeId: nodeId)
        }
        
        print("[DiscoveryCoordinator] Discovery stopped")
    }
    
    // MARK: - Node Selection
    
    /// Select a node and establish WebSocket connection
    func selectNode(_ node: DiscoveredNode) async throws {
        print("[DiscoveryCoordinator] Selecting node: \(node.name)")
        
        do {
            try await webSocketManager.connect(to: node)
            print("[DiscoveryCoordinator] Connected to node: \(node.name)")
        } catch {
            print("[DiscoveryCoordinator] ✗ Failed to connect to node: \(error)")
            throw error
        }
    }
    
    /// Deselect a node and close its connection
    func deselectNode(_ nodeId: String) async {
        print("[DiscoveryCoordinator] Deselecting node: \(nodeId)")
        await webSocketManager.disconnect(fromNodeId: nodeId)
    }
    
    // MARK: - Private: Callback Setup
    
    private func setupCallbacks() {
        // Set up mDNS callbacks
        mdnsService.onNodesUpdated = { [weak self] nodes in
            DispatchQueue.main.async {
                self?.onNodesUpdated?(nodes)
            }
        }
        
        mdnsService.onNodeAdded = { [weak self] node in
            print("[DiscoveryCoordinator] Node added: \(node.name)")
        }
        
        mdnsService.onNodeRemoved = { [weak self] nodeId in
            print("[DiscoveryCoordinator] Node removed: \(nodeId)")
        }
        
        // Set up WebSocket callbacks will be done via setCallback methods
        print("[DiscoveryCoordinator] Callbacks configured")
    }
    
    /// Configure WebSocket callbacks from external source
    func setWebSocketCallbacks(
        onStatusChanged: @escaping (String, NodeConnectionStatus) -> Void,
        onMessageReceived: @escaping (String, NodeMessage) -> Void,
        onConnectionClosed: @escaping (String) -> Void
    ) async {
        self.onConnectionStatusChanged = onStatusChanged
        self.onMessageReceived = onMessageReceived
        self.onConnectionClosed = onConnectionClosed
        
        // Configure WebSocket manager with these callbacks
        await webSocketManager.setCallback(onConnectionStatusChanged: onStatusChanged)
        await webSocketManager.setCallback(onMessageReceived: onMessageReceived)
        await webSocketManager.setCallback(onConnectionClosed: onConnectionClosed)
        
        print("[DiscoveryCoordinator] WebSocket callbacks configured")
    }
}
