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
    
    // MARK: - Public Methods
    
    /// Connect to a discovered node's discovery WebSocket endpoint
    func connect(to node: DiscoveredNode) async throws {
        guard let wsURL = node.discoveryWSURL else {
            print("[WS Discovery] ✗ Failed to create WebSocket URL for \(node.name)")
            print("[WS Discovery]   IP: \(node.ipAddress ?? "nil")")
            print("[WS Discovery]   Port: \(node.port)")
            print("[WS Discovery]   Host: \(node.host)")
            throw WebSocketError.invalidURL
        }
        
        print("[WS Discovery] ===== CONNECTING TO NODE =====")
        print("[WS Discovery] Node: \(node.name)")
        print("[WS Discovery] IP: \(node.ipAddress ?? "nil")")
        print("[WS Discovery] Port: \(node.port)")
        print("[WS Discovery] Host: \(node.host)")
        print("[WS Discovery] URL: \(wsURL.absoluteString)")
        
        let urlSession = URLSession(configuration: .default)
        let webSocketTask = urlSession.webSocketTask(with: wsURL)
        
        let connection = DiscoveryWebSocketConnection(
            nodeId: node.id,
            nodeName: node.name,
            webSocketTask: webSocketTask,
            maxRetryAttempts: maxRetryAttempts,
            initialBackoffSeconds: initialBackoffSeconds
        )
        
        activeConnections[node.id] = connection
        
        // Start connection
        print("[WS Discovery] Starting WebSocket task...")
        webSocketTask.resume()
        
        // Update status
        onConnectionStatusChanged?(node.id, .connecting)
        
        // Send registration message
        let playerName = getDeviceName()
        let platform = getPlatformName()
        print("[WS Discovery] Sending registration: name='\(playerName)' platform='\(platform)'")
        let registerMessage = PlayerMessage.register(name: playerName, platform: platform)
        
        do {
            try await send(message: registerMessage, toNodeId: node.id)
            print("[WS Discovery] ✓ Registration message sent")
        } catch {
            print("[WS Discovery] ✗ Failed to send registration: \(error)")
            throw error
        }
        
        // Start receiving messages
        print("[WS Discovery] Starting to receive messages...")
        await receiveMessages(fromNodeId: node.id)
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
        guard let connection = activeConnections[nodeId] else {
            throw WebSocketError.notConnected
        }
        
        let encoder = JSONEncoder()
        let jsonData = try encoder.encode(message)
        let jsonString = String(data: jsonData, encoding: .utf8) ?? ""
        
        try await connection.webSocketTask.send(.string(jsonString))
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
        guard activeConnections[nodeId] != nil else { 
            print("[WS Discovery] Connection not found for nodeId: \(nodeId)")
            return 
        }
        
        let decoder = JSONDecoder()
        
        while let connection = activeConnections[nodeId] {
            do {
                let message = try await connection.webSocketTask.receive()
                
                switch message {
                case .string(let jsonString):
                    print("[WS Discovery] ✓ Received string message from \(connection.nodeName)")
                    if let jsonData = jsonString.data(using: .utf8) {
                        let nodeMessage = try decoder.decode(NodeMessage.self, from: jsonData)
                        
                        // Update connection status based on message type
                        if case .registered = nodeMessage {
                            activeConnections[nodeId]?.status = .waiting
                            print("[WS Discovery] Calling onConnectionStatusChanged callback with nodeId=\(nodeId), status=.waiting")
                            onConnectionStatusChanged?(nodeId, .waiting)
                            print("[WS Discovery] ✓ Player registered successfully - now waiting for admin selection")
                        }
                        
                        onMessageReceived?(nodeId, nodeMessage)
                    }
                case .data(let data):
                    print("[WS Discovery] ✓ Received data message from \(connection.nodeName)")
                    if let jsonString = String(data: data, encoding: .utf8) {
                        if let jsonData = jsonString.data(using: .utf8) {
                            let nodeMessage = try decoder.decode(NodeMessage.self, from: jsonData)
                            onMessageReceived?(nodeId, nodeMessage)
                        }
                    }
                @unknown default:
                    print("[WS Discovery] ⚠ Received unknown message type")
                    break
                }
            } catch {
                print("[WS Discovery] ✗ Error receiving message from \(nodeId): \(error)")
                if let urlError = error as? URLError {
                    print("[WS Discovery]   URLError code: \(urlError.code.rawValue)")
                    print("[WS Discovery]   Error description: \(urlError.localizedDescription)")
                }
                
                // Attempt retry
                if let connection = activeConnections[nodeId],
                   connection.retryAttempt < connection.maxRetryAttempts {
                    await retryConnection(nodeId: nodeId)
                    return  // Exit after retry is handled (retryConnection continues the loop)
                } else {
                    activeConnections[nodeId]?.status = .reconnecting(attemptNumber: activeConnections[nodeId]?.retryAttempt ?? 0)
                    onConnectionStatusChanged?(nodeId, .reconnecting(attemptNumber: activeConnections[nodeId]?.retryAttempt ?? 0))
                    onConnectionClosed?(nodeId)
                    activeConnections.removeValue(forKey: nodeId)
                    return  // Exit when max retries exceeded
                }
            }
        }
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
        
        onConnectionStatusChanged?(nodeId, .reconnecting(attemptNumber: nextAttempt))
        
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
            onConnectionStatusChanged?(nodeId, .reconnecting(attemptNumber: nextAttempt))
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
            onConnectionStatusChanged?(nodeId, .reconnecting(attemptNumber: nextAttempt))
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
        let registerMessage = PlayerMessage.register(name: playerName, platform: platform)
        
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
