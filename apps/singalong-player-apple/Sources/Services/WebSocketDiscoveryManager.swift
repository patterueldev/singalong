import Foundation
#if os(iOS) || os(tvOS)
import UIKit
#endif

/// Manages WebSocket connections to discovered nodes in the discovery phase
actor WebSocketDiscoveryManager {
    
    static let shared = WebSocketDiscoveryManager()
    
    var activeConnections: [String: DiscoveryWebSocketConnection] = [:]
    private let maxRetryAttempts = 10
    private let initialBackoffSeconds: Double = 1.0
    
    // MARK: - Callbacks
    var onMessageReceived: ((String, NodeMessage) -> Void)?
    var onConnectionStatusChanged: ((String, NodeConnectionStatus) -> Void)?
    var onConnectionClosed: ((String) -> Void)?
    
    // MARK: - Callback Setup (actor-safe)
    
    func setOnConnectionStatusChanged(_ callback: @escaping (String, NodeConnectionStatus) -> Void) {
        self.onConnectionStatusChanged = callback
    }
    
    // MARK: - Helper Methods
    
    /// Dispatch callback to main thread (actor runs on background thread)
    private func dispatchToMain(_ callback: @escaping () -> Void) {
        DispatchQueue.main.async(execute: callback)
    }
    
    // MARK: - Public Methods
    
    /// Connect to a discovered node's discovery WebSocket endpoint
    func connect(to node: DiscoveredNode) async throws {
        print("[WS Discovery] ===== ATTEMPT TO CONNECT TO NODE =====")
        print("[WS Discovery] Node ID: \(node.id)")
        print("[WS Discovery] Node Name: \(node.name)")
        print("[WS Discovery] Node Host: \(node.host)")
        print("[WS Discovery] Node IP: \(node.ipAddress ?? "nil")")
        print("[WS Discovery] Node Port: \(node.port)")
        
        guard let wsURL = node.discoveryWSURL else {
            print("[WS Discovery] ✗ FAILED: Could not create WebSocket URL for \(node.name)")
            print("[WS Discovery]   IP: \(node.ipAddress ?? "nil")")
            print("[WS Discovery]   Port: \(node.port)")
            print("[WS Discovery]   Host: \(node.host)")
            throw WebSocketError.invalidURL
        }
        
        print("[WS Discovery] ✓ WebSocket URL created successfully")
        print("[WS Discovery] URL: \(wsURL.absoluteString)")
        print("[WS Discovery] URL Scheme: \(wsURL.scheme ?? "nil")")
        print("[WS Discovery] URL Host: \(wsURL.host ?? "nil")")
        print("[WS Discovery] URL Port: \(wsURL.port ?? -1)")
        print("[WS Discovery] URL Path: \(wsURL.path)")
        
        print("[WS Discovery] Creating URLSession with default configuration...")
        let urlSession = URLSession(configuration: .default)
        
        print("[WS Discovery] Creating WebSocket task...")
        let webSocketTask = urlSession.webSocketTask(with: wsURL)
        print("[WS Discovery] ✓ WebSocket task created")
        
        let connection = DiscoveryWebSocketConnection(
            nodeId: node.id,
            nodeName: node.name,
            webSocketTask: webSocketTask,
            maxRetryAttempts: maxRetryAttempts,
            initialBackoffSeconds: initialBackoffSeconds
        )
        
        activeConnections[node.id] = connection
        print("[WS Discovery] Connection object stored in activeConnections")
        
        // Start connection
        print("[WS Discovery] Calling webSocketTask.resume()...")
        webSocketTask.resume()
        print("[WS Discovery] ✓ WebSocket task resumed, connection should be establishing...")
        
        // Update status
        print("[WS Discovery] Updating connection status to .connecting...")
        dispatchToMain {
            self.onConnectionStatusChanged?(node.id, .connecting)
        }
        
        // Send registration message
        let playerName = getDeviceName()
        let platform = getPlatformName()
        let playerId = PlayerIdentityService.shared.playerId
        print("[WS Discovery] Preparing registration message...")
        print("[WS Discovery]   Player ID: \(playerId)")
        print("[WS Discovery]   Player Name: \(playerName)")
        print("[WS Discovery]   Platform: \(platform)")
        let registerMessage = PlayerMessage.register(playerId: playerId, name: playerName, platform: platform)
        
        do {
            print("[WS Discovery] Attempting to send registration message...")
            try await send(message: registerMessage, toNodeId: node.id)
            print("[WS Discovery] ✓ Registration message sent successfully")
        } catch {
            print("[WS Discovery] ✗ FAILED to send registration message")
            print("[WS Discovery]   Error: \(error)")
            print("[WS Discovery]   Error description: \(error.localizedDescription)")
            throw error
        }
        
        // Start receiving messages
        print("[WS Discovery] Starting message receive loop...")
        await receiveMessages(fromNodeId: node.id)
        print("[WS Discovery] Message receive loop ended")
    }
    
    /// Disconnect from a node
    func disconnect(fromNodeId nodeId: String) async {
        if let connection = activeConnections.removeValue(forKey: nodeId) {
            connection.webSocketTask.cancel(with: .goingAway, reason: nil)
            print("[WS Discovery] Disconnected from \(connection.nodeName)")
            onConnectionClosed?(nodeId)
        }
    }
    
    /// Disconnect from all nodes
    func disconnectAll() async {
        for (nodeId, _) in activeConnections {
            await disconnect(fromNodeId: nodeId)
        }
    }
    
    /// Send message to specific node
    func send(message: PlayerMessage, toNodeId nodeId: String) async throws {
        print("[WS Discovery] send() called")
        print("[WS Discovery]   Target Node ID: \(nodeId)")
        print("[WS Discovery]   Message type: \(message)")
        
        guard let connection = activeConnections[nodeId] else {
            print("[WS Discovery] ✗ send() failed: No connection found for nodeId=\(nodeId)")
            print("[WS Discovery]   Active connections count: \(activeConnections.count)")
            print("[WS Discovery]   Available node IDs: \(activeConnections.keys.joined(separator: ", "))")
            throw WebSocketError.notConnected
        }
        
        print("[WS Discovery] Connection found, encoding message...")
        let encoder = JSONEncoder()
        let jsonData = try encoder.encode(message)
        let jsonString = String(data: jsonData, encoding: .utf8) ?? ""
        
        print("[WS Discovery] JSON message: \(jsonString)")
        print("[WS Discovery] Sending via WebSocket task...")
        
        do {
            try await connection.webSocketTask.send(.string(jsonString))
            print("[WS Discovery] ✓ Message sent successfully to \(connection.nodeName)")
        } catch {
            print("[WS Discovery] ✗ Failed to send message: \(error)")
            print("[WS Discovery]   Error description: \(error.localizedDescription)")
            throw error
        }
    }
    
    /// Get connection status
    func getStatus(forNodeId nodeId: String) -> NodeConnectionStatus {
        if let connection = activeConnections[nodeId] {
            return connection.status
        }
        return .connecting
    }
    
    /// Set the onConnectionStatusChanged callback
    func setCallback(onConnectionStatusChanged: @escaping (String, NodeConnectionStatus) -> Void) {
        self.onConnectionStatusChanged = onConnectionStatusChanged
    }
    
    /// Set the onMessageReceived callback
    func setCallback(onMessageReceived: @escaping (String, NodeMessage) -> Void) {
        self.onMessageReceived = onMessageReceived
    }
    
    /// Set the onConnectionClosed callback
    func setCallback(onConnectionClosed: @escaping (String) -> Void) {
        self.onConnectionClosed = onConnectionClosed
    }
    
    // MARK: - Private Methods
    
    private func receiveMessages(fromNodeId nodeId: String) async {
        print("[WS Discovery] receiveMessages() starting for nodeId: \(nodeId)")
        
        guard activeConnections[nodeId] != nil else { 
            print("[WS Discovery] ✗ receiveMessages() failed: Connection not found for nodeId: \(nodeId)")
            return 
        }
        
        print("[WS Discovery] Entering receive message loop...")
        let decoder = JSONDecoder()
        
        while let connection = activeConnections[nodeId] {
            print("[WS Discovery] Calling webSocketTask.receive()...")
            do {
                let message = try await connection.webSocketTask.receive()
                print("[WS Discovery] ✓ Received message from \(connection.nodeName)")
                
                switch message {
                case .string(let jsonString):
                    print("[WS Discovery] ✓ Received string message (length: \(jsonString.count) bytes)")
                    print("[WS Discovery] Message content: \(jsonString)")
                    if let jsonData = jsonString.data(using: .utf8) {
                        do {
                            let nodeMessage = try decoder.decode(NodeMessage.self, from: jsonData)
                            print("[WS Discovery] ✓ Decoded message type: \(nodeMessage)")
                            
                            // Update connection status based on message type
                            if case .registered = nodeMessage {
                                activeConnections[nodeId]?.status = .waiting
                                print("[WS Discovery] Message is 'registered', updating status to .waiting")
                                print("[WS Discovery] Calling onConnectionStatusChanged callback with nodeId=\(nodeId), status=.waiting")
                                dispatchToMain {
                                    self.onConnectionStatusChanged?(nodeId, .waiting)
                                }
                                print("[WS Discovery] ✓ Player registered successfully - now waiting for admin selection")
                            }
                            
                            onMessageReceived?(nodeId, nodeMessage)
                        } catch {
                            print("[WS Discovery] ✗ Failed to decode message: \(error)")
                            print("[WS Discovery]   Raw JSON: \(jsonString)")
                        }
                    }
                case .data(let data):
                    print("[WS Discovery] ✓ Received data message (length: \(data.count) bytes)")
                    if let jsonString = String(data: data, encoding: .utf8) {
                        print("[WS Discovery] Message content: \(jsonString)")
                        if let jsonData = jsonString.data(using: .utf8) {
                            do {
                                let nodeMessage = try decoder.decode(NodeMessage.self, from: jsonData)
                                onMessageReceived?(nodeId, nodeMessage)
                            } catch {
                                print("[WS Discovery] ✗ Failed to decode data message: \(error)")
                            }
                        }
                    }
                @unknown default:
                    print("[WS Discovery] ⚠ Received unknown message type")
                    break
                }
            } catch {
                print("[WS Discovery] ✗ Error in receive loop: \(error)")
                if let urlError = error as? URLError {
                    print("[WS Discovery]   URLError code: \(urlError.code.rawValue)")
                    print("[WS Discovery]   Error description: \(urlError.localizedDescription)")
                }
                
                // Attempt retry
                if let connection = activeConnections[nodeId],
                   connection.retryAttempt < connection.maxRetryAttempts {
                    print("[WS Discovery] Will attempt retry...")
                    await retryConnection(nodeId: nodeId)
                    return  // Exit after retry is handled (retryConnection continues the loop)
                } else {
                    print("[WS Discovery] Max retries exceeded or connection not found")
                    activeConnections[nodeId]?.status = .reconnecting(attemptNumber: activeConnections[nodeId]?.retryAttempt ?? 0)
                    dispatchToMain {
                        self.onConnectionStatusChanged?(nodeId, .reconnecting(attemptNumber: self.activeConnections[nodeId]?.retryAttempt ?? 0))
                        self.onConnectionClosed?(nodeId)
                    }
                    activeConnections.removeValue(forKey: nodeId)
                    return  // Exit when max retries exceeded
                }
            }
        }
        print("[WS Discovery] Exited receive message loop for nodeId: \(nodeId)")
    }
    
    private func retryConnection(nodeId: String) async {
        guard let connection = activeConnections[nodeId] else {
            print("[WS Discovery] Node \(nodeId) already removed from activeConnections, cancelling retry")
            return
        }
        
        let nextAttempt = connection.retryAttempt + 1
        activeConnections[nodeId]?.retryAttempt = nextAttempt
        
        // Calculate exponential backoff: 1s, 2s, 4s, then stay at 4s
        let backoffDelay = connection.initialBackoffSeconds * pow(2.0, Double(nextAttempt - 1))
        let maxBackoff = 4.0  // Cap at 4 seconds
        let actualDelay = min(backoffDelay, maxBackoff)
        
        print("[WS Discovery] Retrying connection to \(connection.nodeName) (attempt \(nextAttempt)/\(connection.maxRetryAttempts)) in \(String(format: "%.1f", actualDelay))s")
        
        dispatchToMain {
            self.onConnectionStatusChanged?(nodeId, .reconnecting(attemptNumber: nextAttempt))
        }
        
        // Wait before retrying
        try? await Task.sleep(nanoseconds: UInt64(actualDelay * 1_000_000_000))
        
        // Check if node still exists after sleep (might have been removed)
        guard let connection = activeConnections[nodeId] else {
            print("[WS Discovery] Node \(nodeId) was removed during retry sleep, cancelling")
            return
        }
        
        // Build WebSocket URL - need to reconstruct since we don't have the DiscoveredNode anymore
        guard let originalURL = connection.webSocketTask.currentRequest?.url else {
            print("[WS Discovery] ✗ Cannot retry: missing URL from current request")
            activeConnections[nodeId]?.status = .reconnecting(attemptNumber: nextAttempt)
            dispatchToMain {
                self.onConnectionStatusChanged?(nodeId, .reconnecting(attemptNumber: nextAttempt))
            }
            activeConnections.removeValue(forKey: nodeId)
            return
        }
        
        // Convert http/https schemes to ws/wss for WebSocket task
        var wsURL = originalURL
        if originalURL.scheme == "http" {
            var components = URLComponents(url: originalURL, resolvingAgainstBaseURL: false)
            components?.scheme = "ws"
            wsURL = components?.url ?? originalURL
        } else if originalURL.scheme == "https" {
            var components = URLComponents(url: originalURL, resolvingAgainstBaseURL: false)
            components?.scheme = "wss"
            wsURL = components?.url ?? originalURL
        }
        
        // Validate the final URL has proper scheme
        guard wsURL.scheme == "ws" || wsURL.scheme == "wss" else {
            print("[WS Discovery] ✗ Cannot retry: URL scheme is not ws/wss")
            print("[WS Discovery]   Original URL: \(originalURL.absoluteString)")
            print("[WS Discovery]   Converted URL: \(wsURL.absoluteString)")
            activeConnections[nodeId]?.status = .reconnecting(attemptNumber: nextAttempt)
            dispatchToMain {
                self.onConnectionStatusChanged?(nodeId, .reconnecting(attemptNumber: nextAttempt))
            }
            activeConnections.removeValue(forKey: nodeId)
            return
        }
        
        let newSession = URLSession(configuration: .default)
        let newWebSocketTask = newSession.webSocketTask(with: wsURL)
        
        activeConnections[nodeId]?.webSocketTask = newWebSocketTask
        print("[WS Discovery] Resuming WebSocket task for retry...")
        newWebSocketTask.resume()
        
        // Send registration again
        let playerName = getDeviceName()
        let platform = getPlatformName()
        let playerId = PlayerIdentityService.shared.playerId
        let registerMessage = PlayerMessage.register(playerId: playerId, name: playerName, platform: platform)
        
        do {
            try await send(message: registerMessage, toNodeId: nodeId)
            print("[WS Discovery] ✓ Registration message sent on retry")
        } catch {
            print("[WS Discovery] ✗ Failed to send registration on retry: \(error)")
        }
        
        // Continue receiving
        await receiveMessages(fromNodeId: nodeId)
    }
    
    private func getDeviceName() -> String {
        #if os(macOS)
        return (try? Host.current().localizedName) ?? "Mac Player"
        #elseif os(iOS)
        return UIDevice.current.name
        #elseif os(tvOS)
        return UIDevice.current.name
        #else
        return "Singalong Player"
        #endif
    }
    
    private func getPlatformName() -> String {
        #if os(macOS)
        return "macos"
        #elseif os(iOS)
        return UIDevice.current.userInterfaceIdiom == .pad ? "ipados" : "ios"
        #elseif os(tvOS)
        return "tvos"
        #else
        return "unknown"
        #endif
    }
}

/// Represents an active discovery WebSocket connection
class DiscoveryWebSocketConnection {
    let nodeId: String
    let nodeName: String
    var webSocketTask: URLSessionWebSocketTask
    var status: NodeConnectionStatus = .connecting
    var retryAttempt: Int = 0
    let maxRetryAttempts: Int
    let initialBackoffSeconds: Double
    
    init(nodeId: String, nodeName: String, webSocketTask: URLSessionWebSocketTask, maxRetryAttempts: Int, initialBackoffSeconds: Double) {
        self.nodeId = nodeId
        self.nodeName = nodeName
        self.webSocketTask = webSocketTask
        self.maxRetryAttempts = maxRetryAttempts
        self.initialBackoffSeconds = initialBackoffSeconds
    }
}

// MARK: - Error Types

enum WebSocketError: LocalizedError {
    case invalidURL
    case notConnected
    case encodingFailed
    case decodingFailed
    case connectionClosed
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid WebSocket URL"
        case .notConnected:
            return "Not connected to node"
        case .encodingFailed:
            return "Failed to encode message"
        case .decodingFailed:
            return "Failed to decode message"
        case .connectionClosed:
            return "Connection was closed"
        }
    }
}
