import Foundation
#if os(iOS) || os(tvOS)
import UIKit
#endif

/// Manages WebSocket connections to discovered nodes in the discovery phase
actor WebSocketDiscoveryManager {
    
    static let shared = WebSocketDiscoveryManager()
    
    private var activeConnections: [String: DiscoveryWebSocketConnection] = [:]
    
    // MARK: - Callbacks
    var onMessageReceived: ((String, NodeMessage) -> Void)?
    var onConnectionStatusChanged: ((String, NodeConnectionStatus) -> Void)?
    var onConnectionClosed: ((String) -> Void)?
    
    // MARK: - Public Methods
    
    /// Connect to a discovered node's discovery WebSocket endpoint
    func connect(to node: DiscoveredNode) async throws {
        guard let wsURL = node.discoveryWSURL else {
            throw WebSocketError.invalidURL
        }
        
        print("[WS Discovery] Connecting to \(node.name) at \(wsURL.absoluteString)")
        
        let urlSession = URLSession(configuration: .default)
        let webSocketTask = urlSession.webSocketTask(with: wsURL)
        
        let connection = DiscoveryWebSocketConnection(
            nodeId: node.id,
            nodeName: node.name,
            webSocketTask: webSocketTask
        )
        
        activeConnections[node.id] = connection
        
        // Start connection
        webSocketTask.resume()
        
        // Update status
        onConnectionStatusChanged?(node.id, .connecting)
        
        // Send registration message
        let playerName = getDeviceName()
        let platform = getPlatformName()
        let registerMessage = PlayerMessage.register(name: playerName, platform: platform)
        
        try await send(message: registerMessage, toNodeId: node.id)
        
        // Start receiving messages
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
    func getStatus(forNodeId nodeId: String) -> NodeConnectionStatus? {
        return activeConnections[nodeId]?.status
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
        guard activeConnections[nodeId] != nil else { return }
        
        let decoder = JSONDecoder()
        
        while let connection = activeConnections[nodeId] {
            do {
                let message = try await connection.webSocketTask.receive()
                
                switch message {
                case .string(let jsonString):
                    if let jsonData = jsonString.data(using: .utf8) {
                        let nodeMessage = try decoder.decode(NodeMessage.self, from: jsonData)
                        
                        // Update connection status based on message type
                        if case .registered = nodeMessage {
                            activeConnections[nodeId]?.status = .connected
                            onConnectionStatusChanged?(nodeId, .connected)
                        }
                        
                        onMessageReceived?(nodeId, nodeMessage)
                    }
                case .data(let data):
                    if let jsonString = String(data: data, encoding: .utf8) {
                        if let jsonData = jsonString.data(using: .utf8) {
                            let nodeMessage = try decoder.decode(NodeMessage.self, from: jsonData)
                            onMessageReceived?(nodeId, nodeMessage)
                        }
                    }
                @unknown default:
                    break
                }
            } catch {
                if error as? URLError != nil {
                    print("[WS Discovery] Connection closed or error for \(nodeId): \(error)")
                    activeConnections[nodeId]?.status = .disconnected
                    onConnectionStatusChanged?(nodeId, .disconnected)
                    onConnectionClosed?(nodeId)
                    activeConnections.removeValue(forKey: nodeId)
                }
                break
            }
        }
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
private class DiscoveryWebSocketConnection {
    let nodeId: String
    let nodeName: String
    let webSocketTask: URLSessionWebSocketTask
    var status: NodeConnectionStatus = .connecting
    
    init(nodeId: String, nodeName: String, webSocketTask: URLSessionWebSocketTask) {
        self.nodeId = nodeId
        self.nodeName = nodeName
        self.webSocketTask = webSocketTask
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
