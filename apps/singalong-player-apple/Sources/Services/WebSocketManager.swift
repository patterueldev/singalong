import Foundation

/// Generic protocol for WebSocket connection management
/// Implemented by both discovery and player session managers
protocol WebSocketManager: AnyObject, Sendable {
    associatedtype MessageType: Codable
    
    /// Connect to the WebSocket server
    func connect(url: URL) async throws
    
    /// Disconnect from the WebSocket server
    func disconnect() async throws
    
    /// Send a message to the server
    func send(_ message: MessageType) async throws
    
    /// Receive messages as an async stream
    func receive() -> AsyncStream<MessageType>
    
    /// Called when connection status changes
    var onConnectionStatusChanged: ((ConnectionStatus) -> Void)? { get set }
    
    /// Called when an error occurs
    var onError: ((WebSocketError) -> Void)? { get set }
}

/// Connection status for any WebSocket connection
enum ConnectionStatus: Sendable {
    case disconnected
    case connecting
    case connected
    case reconnecting(attemptNumber: Int)
    case disconnecting
    case error(String)
    
    var displayText: String {
        switch self {
        case .disconnected:
            return "Disconnected"
        case .connecting:
            return "Connecting..."
        case .connected:
            return "Connected"
        case .reconnecting(let attempt):
            return "Reconnecting (\(attempt))..."
        case .disconnecting:
            return "Disconnecting..."
        case .error(let message):
            return "Error: \(message)"
        }
    }
}
