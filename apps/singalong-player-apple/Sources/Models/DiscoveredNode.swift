import Foundation

/// Represents a discovered Singalong Node on the local network
struct DiscoveredNode: Identifiable, Hashable {
    let id: String  // service name/identifier
    var name: String
    var host: String
    var port: Int
    var ipAddress: String?
    var discoveredAt: Date
    
    /// Full WebSocket URL for discovery endpoint
    var discoveryWSURL: URL? {
        guard let ip = ipAddress else { return nil }
        return URL(string: "ws://\(ip):\(port)/ws/player/discovery")
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: DiscoveredNode, rhs: DiscoveredNode) -> Bool {
        lhs.id == rhs.id && lhs.host == rhs.host
    }
}

/// Connection status of a discovered node
enum NodeConnectionStatus: String, CaseIterable {
    case disconnected = "Disconnected"
    case connecting = "Connecting..."
    case connected = "Connected"
    case locked = "Locked"
    case error = "Error"
}

/// Model for a player-node connection
struct PlayerNodeConnection: Identifiable {
    let id: String  // player_id from Node
    var nodeId: String
    var nodeName: String
    var status: NodeConnectionStatus
    var webSocketTask: URLSessionWebSocketTask?
    var lastMessageAt: Date?
    
    mutating func updateStatus(_ newStatus: NodeConnectionStatus) {
        self.status = newStatus
        self.lastMessageAt = Date()
    }
}
