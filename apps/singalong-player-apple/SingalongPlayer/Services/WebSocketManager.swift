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
enum ConnectionStatus: String, Sendable {
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

/// WebSocket-related errors
enum WebSocketError: LocalizedError, Sendable {
    case invalidURL
    case connectionFailed(String)
    case messageSendFailed(String)
    case messageReceiveFailed(String)
    case decodingFailed(String)
    case encodingFailed(String)
    case disconnected
    case timeout
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid WebSocket URL"
        case .connectionFailed(let msg):
            return "Connection failed: \(msg)"
        case .messageSendFailed(let msg):
            return "Failed to send message: \(msg)"
        case .messageReceiveFailed(let msg):
            return "Failed to receive message: \(msg)"
        case .decodingFailed(let msg):
            return "Failed to decode message: \(msg)"
        case .encodingFailed(let msg):
            return "Failed to encode message: \(msg)"
        case .disconnected:
            return "WebSocket disconnected"
        case .timeout:
            return "Connection timeout"
        }
    }
}
