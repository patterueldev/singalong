import Foundation

/// Manages WebSocket connection to player session endpoint
/// Handles player control commands and state updates after player is locked to a session
actor WebSocketPlayerSessionManager {
    
    static let shared = WebSocketPlayerSessionManager()
    
    private var sessionWebSocketTask: URLSessionWebSocketTask?
    private var isConnected = false
    
    // MARK: - Callbacks
    
    var onMessageReceived: ((NodeSessionMessage) -> Void)?
    var onConnectionStatusChanged: ((ConnectionStatus) -> Void)?
    var onConnectionClosed: (() -> Void)?
    var onError: ((WebSocketError) -> Void)?
    
    private let maxRetryAttempts = 5
    private let initialBackoffSeconds: Double = 1.0
    
    nonisolated init() {
        print("[PlayerSessionManager] Initialized")
    }
    
    // MARK: - Connection Management
    
    func connect(sessionCode: String, token: String) async throws {
        print("[PlayerSessionManager] Connecting to session: \(sessionCode)")
        
        // Build WebSocket URL
        let wsURL = URL(string: "ws://localhost:5002/ws/player/session/\(sessionCode)")!
        
        let urlSession = URLSession(configuration: .default)
        let webSocketTask = urlSession.webSocketTask(with: wsURL)
        
        self.sessionWebSocketTask = webSocketTask
        
        // Start connection
        webSocketTask.resume()
        
        // Update status
        await MainActor.run {
            self.onConnectionStatusChanged?(.connecting)
        }
        
        // Send authentication message
        let authMessage = PlayerSessionMessage.auth(sessionCode: sessionCode, token: token)
        do {
            try await send(message: authMessage)
            print("[PlayerSessionManager] ✓ Auth message sent")
        } catch {
            print("[PlayerSessionManager] ✗ Failed to send auth: \(error)")
            throw error
        }
        
        // Start receiving messages
        await receiveMessages()
    }
    
    func disconnect() async {
        print("[PlayerSessionManager] Disconnecting from session")
        
        if let task = sessionWebSocketTask {
            try? await task.send(.string("{\"type\": \"disconnect\"}"))
            task.cancel(with: .goingAway, reason: nil)
        }
        
        sessionWebSocketTask = nil
        isConnected = false
        
        await MainActor.run {
            self.onConnectionClosed?()
        }
        
        print("[PlayerSessionManager] Disconnected")
    }
    
    // MARK: - Message Sending
    
    private func send(message: PlayerSessionMessage) async throws {
        guard let task = sessionWebSocketTask else {
            throw WebSocketError.disconnected
        }
        
        let encoder = JSONEncoder()
        let jsonData = try encoder.encode(message)
        let jsonString = String(data: jsonData, encoding: .utf8) ?? ""
        
        print("[PlayerSessionManager] Sending message: \(jsonString)")
        
        try await task.send(.string(jsonString))
    }
    
    // MARK: - Message Receiving
    
    private func receiveMessages() async {
        guard let task = sessionWebSocketTask else {
            print("[PlayerSessionManager] No WebSocket task available")
            return
        }
        
        isConnected = true
        
        await MainActor.run {
            self.onConnectionStatusChanged?(.connected)
        }
        
        do {
            while isConnected {
                let message = try await task.receive()
                
                switch message {
                case .string(let text):
                    if let jsonData = text.data(using: .utf8) {
                        do {
                            let decoder = JSONDecoder()
                            let nodeMessage = try decoder.decode(NodeSessionMessage.self, from: jsonData)
                            
                            print("[PlayerSessionManager] Received message: \(text)")
                            
                            // Dispatch message to callback on main thread
                            await MainActor.run {
                                self.onMessageReceived?(nodeMessage)
                            }
                        } catch {
                            print("[PlayerSessionManager] ✗ Failed to decode message: \(error)")
                            await MainActor.run {
                                self.onError?(.decodingFailed(error.localizedDescription))
                            }
                        }
                    }
                    
                case .data(let data):
                    print("[PlayerSessionManager] Received binary data: \(data.count) bytes")
                    
                @unknown default:
                    print("[PlayerSessionManager] Received unknown message type")
                }
            }
        } catch {
            print("[PlayerSessionManager] ✗ WebSocket error: \(error)")
            isConnected = false
            
            await MainActor.run {
                self.onConnectionStatusChanged?(.disconnected)
                self.onError?(.messageReceiveFailed(error.localizedDescription))
            }
        }
    }
}
