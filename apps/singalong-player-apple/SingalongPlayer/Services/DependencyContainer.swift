import Foundation

/// Central dependency injection container
/// Provides all services to the app with clear dependencies
@MainActor
class DependencyContainer {
    
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
    
    // MARK: - Player Session Manager Factory
    
    /// Create and store a player session manager
    /// Called when player transitions from discovery to session phase
    func createPlayerSessionManager() -> WebSocketPlayerSessionManager {
        let manager = WebSocketPlayerSessionManager.shared
        self.playerSessionManager = manager
        print("[DependencyContainer] Created player session manager")
        return manager
    }
    
    /// Clear player session manager
    /// Called when player disconnects
    func clearPlayerSessionManager() {
        self.playerSessionManager = nil
        print("[DependencyContainer] Cleared player session manager")
    }
}

/// Global app container instance
/// Accessed via dependency injection where possible, but can be referenced globally if needed
let appContainer = DependencyContainer()
