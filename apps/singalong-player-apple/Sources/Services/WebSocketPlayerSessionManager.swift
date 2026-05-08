import Foundation

/// WebSocket manager for player session phase
/// Handles player ↔ node bidirectional communication after player is locked to a session
class WebSocketPlayerSessionManager {
    
    // MARK: - Properties
    
    private var webSocketTask: URLSessionWebSocketTask?
    private let session = URLSession(configuration: .default)
    
    private var sessionCode: String?
    private var token: String?
    private var nodeBaseUrl: String?
    private var isConnected = false
    private var retryCount = 0
    private let maxRetries = 5
    private let maxBackoffSeconds: Double = 16
    
    // Message handlers registry
    var onAuthenticated: (() -> Void)?
    var onDisconnect: (() -> Void)?
    var onQueueUpdated: (([String]) -> Void)? // Song IDs
    var onPlay: ((String, String) -> Void)? // songId, url
    var onPause: (() -> Void)?
    var onSeek: ((Int) -> Void)? // seconds
    var onVolume: ((Float) -> Void)?
    var onAttendees: ((Int) -> Void)? // count
    var onSessionMessage: ((String) -> Void)?
    var onSessionEnded: (() -> Void)?
    var onError: ((Error) -> Void)?
    
    // MARK: - Public Methods
    
    /// Connect to player session WebSocket
    func connect(to sessionCode: String, token: String, nodeBaseUrl: String) async throws {
        // Cancel any existing connection first
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
        isConnected = false
        
        self.sessionCode = sessionCode
        self.token = token
        self.nodeBaseUrl = nodeBaseUrl
        
        print("[PlayerSession] Connecting to session \(sessionCode) at \(nodeBaseUrl)")
        
        guard let url = URL(string: "\(nodeBaseUrl)/ws/player/session/\(sessionCode)") else {
            throw WebSocketError.invalidURL
        }
        
        webSocketTask = session.webSocketTask(with: url)
        webSocketTask?.resume()
        isConnected = true
        retryCount = 0
        
        print("[PlayerSession] WebSocket task started for \(sessionCode)")
        
        // Start listening for messages
        startReceivingMessages()
        
        // Send auth message
        let authMessage = PlayerSessionMessage.auth(sessionCode: sessionCode, token: token)
        try await send(authMessage)
    }
    
    /// Disconnect from player session WebSocket
    func disconnect() async throws {
        print("[PlayerSession] Disconnecting from session \(sessionCode ?? "unknown")")
        
        guard let task = webSocketTask else {
            print("[PlayerSession] No active WebSocket task to disconnect")
            return
        }
        
        isConnected = false
        
        // Send ended message with dummy song ID (not used)
        try? await send(.ended(songId: ""))
        
        task.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
    }
    
    /// Send a message to the node
    func send(_ message: PlayerSessionMessage) async throws {
        guard let task = webSocketTask, isConnected else {
            throw WebSocketError.notConnected
        }
        
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        
        let data = try encoder.encode(message)
        guard let jsonString = String(data: data, encoding: .utf8) else {
            throw WebSocketError.encodingFailed
        }
        // Send as text frame — server uses receive_text(), binary frames cause KeyError
        try await task.send(.string(jsonString))
        print("[PlayerSession] ✓ Sent message: \(message)")
    }
    
    /// Receive messages as async stream
    func receiveStream() -> AsyncStream<NodeSessionMessage> {
        return AsyncStream { continuation in
            Task {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                
                while isConnected, let task = webSocketTask {
                    do {
                        let message = try await task.receive()
                        
                        let data: Data?
                        switch message {
                        case .data(let bytes):
                            data = bytes
                        case .string(let string):
                            data = string.data(using: .utf8)
                        @unknown default:
                            print("[PlayerSession] Unknown message frame type")
                            data = nil
                        }
                        
                        if let data = data,
                           let nodeMessage = try? decoder.decode(NodeSessionMessage.self, from: data) {
                            continuation.yield(nodeMessage)
                            handleMessage(nodeMessage)
                        } else {
                            print("[PlayerSession] ✗ Failed to decode message")
                        }
                    } catch {
                        if isConnected {
                            print("[PlayerSession] ✗ Receive error: \(error)")
                            await attemptReconnect()
                        }
                        continuation.finish()
                        break
                    }
                }
                continuation.finish()
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func startReceivingMessages() {
        Task {
            for await message in receiveStream() {
                // Handler called via handleMessage
            }
        }
    }
    
    private func handleMessage(_ message: NodeSessionMessage) {
        print("[PlayerSession] Received: \(message)")
        
        switch message {
        case .authenticated:
            print("[PlayerSession] ✓ Authenticated with node")
            DispatchQueue.main.async { self.onAuthenticated?() }
            
        case .disconnect(let reason):
            print("[PlayerSession] ⚠ Disconnect: \(reason)")
            DispatchQueue.main.async { self.onDisconnect?() }
            
        case .queueUpdated(let songs):
            print("[PlayerSession] Queue updated: \(songs.count) items")
            DispatchQueue.main.async { self.onQueueUpdated?(songs) }
            
        case .play(let songId, let url):
            print("[PlayerSession] Play: \(songId) - \(url)")
            DispatchQueue.main.async { self.onPlay?(songId, url) }
            
        case .pause:
            print("[PlayerSession] Pause command")
            DispatchQueue.main.async { self.onPause?() }
            
        case .seek(let seconds):
            print("[PlayerSession] Seek to \(seconds)s")
            DispatchQueue.main.async { self.onSeek?(seconds) }
            
        case .volume(let level):
            print("[PlayerSession] Volume: \(level)")
            DispatchQueue.main.async { self.onVolume?(level) }
            
        case .attendees(let count):
            print("[PlayerSession] Attendees: \(count)")
            DispatchQueue.main.async { self.onAttendees?(count) }
            
        case .sessionMessage(let text):
            print("[PlayerSession] Message: \(text)")
            DispatchQueue.main.async { self.onSessionMessage?(text) }
            
        case .sessionEnded(let reason):
            print("[PlayerSession] Session ended: \(reason)")
            DispatchQueue.main.async { self.onSessionEnded?() }
            
        case .pong:
            print("[PlayerSession] Pong received")
            
        case .error(let code, let msg):
            print("[PlayerSession] ✗ Error (\(code)): \(msg)")
            let error = NSError(domain: "PlayerSessionError", code: -1, userInfo: [NSLocalizedDescriptionKey: msg])
            DispatchQueue.main.async { self.onError?(error) }
        }
    }
    
    private func attemptReconnect() async {
        guard retryCount < maxRetries else {
            print("[PlayerSession] ✗ Max retries reached, giving up")
            isConnected = false
            DispatchQueue.main.async { self.onDisconnect?() }
            return
        }
        
        retryCount += 1
        let backoffSeconds = min(Double(1 << retryCount), maxBackoffSeconds) // 2^n, max 16s
        
        print("[PlayerSession] Reconnecting in \(backoffSeconds)s (attempt \(retryCount)/\(maxRetries))")
        
        try? await Task.sleep(nanoseconds: UInt64(backoffSeconds * 1_000_000_000))
        
        guard let code = sessionCode, let tok = token, let nodeUrl = nodeBaseUrl else {
            print("[PlayerSession] ✗ Missing session code, token, or node URL for reconnect")
            return
        }
        
        do {
            try await connect(to: code, token: tok, nodeBaseUrl: nodeUrl)
            print("[PlayerSession] ✓ Reconnected successfully")
        } catch {
            print("[PlayerSession] ✗ Reconnect failed: \(error)")
            await attemptReconnect()
        }
    }
}
