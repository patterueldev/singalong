import Foundation

/// WebSocket manager for player session phase (after player is locked)
/// Handles connection to /ws/player/session/{code} and communicates with Node
class WebSocketPlayerSessionManager: NSObject {
    
    // MARK: - Properties
    
    private var isConnected = false
    private var sessionCode: String = ""
    private var token: String = ""
    
    var onConnectionStatusChanged: ((ConnectionStatus) -> Void)?
    var onError: ((WebSocketError) -> Void)?
    
    // MARK: - Methods
    
    func connect(sessionCode: String) async throws {
        self.sessionCode = sessionCode
        // Will construct WebSocket URL from sessionCode
        // e.g., ws://node:5002/ws/player/session/{code}
        isConnected = true
        onConnectionStatusChanged?(.connected)
    }
    
    func disconnect() async throws {
        isConnected = false
        onConnectionStatusChanged?(.disconnected)
    }
    
    func send(_ message: PlayerSessionMessage) async throws {
        guard isConnected else {
            throw WebSocketError.notConnected
        }
        // Placeholder: Will implement message sending to WebSocket
    }
    
    func receiveMessages(handler: @escaping (NodeSessionMessage) -> Void) async throws {
        // Placeholder: Will implement session message receiving
        while isConnected {
            // Simulate receiving messages
            try? await Task.sleep(nanoseconds: 1_000_000_000)
        }
    }
}
