import SwiftUI
import Foundation

/// Simplified app state for routing and global app configuration
@MainActor
class PlayerAppState: ObservableObject {
    
    // MARK: - UserDefaults Keys
    
    private enum Keys {
        static let playerId = "player_id"
        static let sessionCode = "locked_session_code"
        static let sessionToken = "locked_session_token"
        static let nodeBaseUrl = "locked_node_base_url"
    }
    
    // MARK: - Published Properties
    
    /// Current player ID (persisted across app launches)
    @Published var playerId: String? = nil
    
    /// Current screen to display
    @Published var currentScreen: PlayerScreen = .idle
    
    /// Session code and token when player is in active session
    @Published var lockedSessionCode: String? = nil
    @Published var lockedSessionToken: String? = nil
    
    /// Base WebSocket URL of the node the player is locked to (e.g. ws://192.168.1.5:8080)
    @Published var lockedNodeBaseUrl: String? = nil
    
    // MARK: - Initialization
    
    init() {
        let defaults = UserDefaults.standard
        
        if let savedPlayerId = defaults.string(forKey: Keys.playerId) {
            self.playerId = savedPlayerId
        }
        
        // Restore active session if one was persisted (e.g. after app restart).
        // Only validate structural correctness here — whether the session is still
        // live on the server is determined when the session WS actually connects.
        // Never silently clear data at startup; let the connection result decide.
        if let code = defaults.string(forKey: Keys.sessionCode),
           let token = defaults.string(forKey: Keys.sessionToken),
           let nodeUrl = defaults.string(forKey: Keys.nodeBaseUrl),
           !code.isEmpty,
           !token.isEmpty,
           nodeUrl.hasPrefix("ws://") {
            self.lockedSessionCode = code
            self.lockedSessionToken = token
            self.lockedNodeBaseUrl = nodeUrl
            self.currentScreen = .main
            print("[PlayerAppState] Restored session from UserDefaults: \(code) @ \(nodeUrl)")
        }
    }
    
    // MARK: - Screen Navigation
    
    /// Transition to the idle screen (node discovery phase)
    func transitionToIdleScreen() {
        currentScreen = .idle
        lockedSessionCode = nil
        lockedSessionToken = nil
        lockedNodeBaseUrl = nil
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: Keys.sessionCode)
        defaults.removeObject(forKey: Keys.sessionToken)
        defaults.removeObject(forKey: Keys.nodeBaseUrl)
    }
    
    /// Transition to the main screen (session active phase)
    func transitionToMainScreen(sessionCode: String, sessionToken: String, nodeBaseUrl: String) {
        lockedSessionCode = sessionCode
        lockedSessionToken = sessionToken
        lockedNodeBaseUrl = nodeBaseUrl
        currentScreen = .main
        let defaults = UserDefaults.standard
        defaults.set(sessionCode, forKey: Keys.sessionCode)
        defaults.set(sessionToken, forKey: Keys.sessionToken)
        defaults.set(nodeBaseUrl, forKey: Keys.nodeBaseUrl)
        print("[PlayerAppState] Persisted session: \(sessionCode) @ \(nodeBaseUrl)")
    }
    
    /// Set the player ID (persisted to UserDefaults)
    func setPlayerId(_ id: String) {
        playerId = id
        UserDefaults.standard.set(id, forKey: Keys.playerId)
    }
}

// MARK: - Enums

enum PlayerScreen {
    case idle
    case main
}
