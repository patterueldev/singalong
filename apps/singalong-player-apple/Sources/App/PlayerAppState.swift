import SwiftUI
import Foundation

/// Simplified app state for routing and global app configuration
@MainActor
class PlayerAppState: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Current player ID (persisted across app launches)
    @Published var playerId: String? = nil
    
    /// Current screen to display
    @Published var currentScreen: PlayerScreen = .idle
    
    /// Session code and token when player is in active session
    @Published var lockedSessionCode: String? = nil
    @Published var lockedSessionToken: String? = nil
    
    /// Dependency injection container
    private let dependencyContainer = DependencyContainer.shared
    
    // MARK: - Initialization
    
    init() {
        // Restore persisted player ID if available
        if let savedPlayerId = UserDefaults.standard.string(forKey: "player_id") {
            self.playerId = savedPlayerId
        }
    }
    
    // MARK: - Screen Navigation
    
    /// Transition to the idle screen (node discovery phase)
    func transitionToIdleScreen() {
        currentScreen = .idle
        lockedSessionCode = nil
        lockedSessionToken = nil
    }
    
    /// Transition to the main screen (session active phase)
    func transitionToMainScreen(sessionCode: String, sessionToken: String) {
        lockedSessionCode = sessionCode
        lockedSessionToken = sessionToken
        currentScreen = .main
    }
    
    /// Set the player ID (persisted to UserDefaults)
    func setPlayerId(_ id: String) {
        playerId = id
        UserDefaults.standard.set(id, forKey: "player_id")
    }
}

// MARK: - Enums

enum PlayerScreen {
    case idle
    case main
}
