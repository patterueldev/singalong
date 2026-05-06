import Foundation

/// Manages persistent player identity across app sessions
/// Generates and stores a unique player ID on first launch, reuses it thereafter
class PlayerIdentityService {
    static let shared = PlayerIdentityService()
    
    private let userDefaults = UserDefaults.standard
    private let playerIdKey = "singalong_player_id"
    
    /// Get or generate the persistent player ID for this device
    var playerId: String {
        // Try to load existing ID
        if let existingId = userDefaults.string(forKey: playerIdKey) {
            print("[PlayerIdentity] ✓ Loaded existing player ID: \(existingId)")
            return existingId
        }
        
        // Generate new ID if not found
        let newId = UUID().uuidString
        userDefaults.set(newId, forKey: playerIdKey)
        print("[PlayerIdentity] ✓ Generated new player ID: \(newId)")
        return newId
    }
    
    /// Reset player ID (for testing only)
    func resetPlayerId() {
        userDefaults.removeObject(forKey: playerIdKey)
        print("[PlayerIdentity] ✓ Player ID reset")
    }
}
