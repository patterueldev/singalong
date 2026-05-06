import Foundation

/// Central dependency injection container
/// Provides all services to the app with clear dependencies
@MainActor
class DependencyContainer {
    
    // MARK: - Singleton
    
    static let shared = DependencyContainer(
        mdnsService: MDNSDiscoveryService.shared,
        webSocketDiscoveryManager: WebSocketDiscoveryManager.shared
    )
    
    // MARK: - Singleton Services
    
    let mdnsService: MDNSDiscoveryService
    let webSocketDiscoveryManager: WebSocketDiscoveryManager
    let discoveryCoordinator: DiscoveryCoordinator
    
    // Player session manager (created when needed)
    private(set) var playerSessionManager: WebSocketPlayerSessionManager?
    
    // MARK: - Initialization
    
    init(
        mdnsService: MDNSDiscoveryService = MDNSDiscoveryService.shared,
        webSocketDiscoveryManager: WebSocketDiscoveryManager = WebSocketDiscoveryManager.shared
    ) {
        self.mdnsService = mdnsService
        self.webSocketDiscoveryManager = webSocketDiscoveryManager
        self.discoveryCoordinator = DiscoveryCoordinator(
            mdnsService: mdnsService,
            webSocketManager: webSocketDiscoveryManager
        )
        
        print("[DependencyContainer] Initialized with default services")
    }
    
    // MARK: - Factory Methods
    
    func createPlayerSessionManager() -> WebSocketPlayerSessionManager {
        let manager = WebSocketPlayerSessionManager()
        self.playerSessionManager = manager
        return manager
    }
}
