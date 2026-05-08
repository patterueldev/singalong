import Foundation
import SwiftUI

/// Represents a discovered Singalong Node on the local network
struct DiscoveredNode: Identifiable, Hashable {
    let id: String  // service name/identifier
    var name: String
    var host: String
    var port: Int
    var ipAddress: String?
    var discoveredAt: Date
    
    /// Resolved base URL (ws://host:port) used for WebSocket endpoints
    var nodeBaseURL: String? {
        let hostWithoutDot = host.hasSuffix(".") ? String(host.dropLast()) : host
        let target = !hostWithoutDot.isEmpty ? hostWithoutDot : ipAddress
        guard let target = target, !target.isEmpty else { return nil }
        return "ws://\(target):\(port)"
    }
    
    /// Resolved base URL (http://host:port) used for HTTP REST endpoints
    var nodeHTTPBaseURL: String? {
        let hostWithoutDot = host.hasSuffix(".") ? String(host.dropLast()) : host
        let target = !hostWithoutDot.isEmpty ? hostWithoutDot : ipAddress
        guard let target = target, !target.isEmpty else { return nil }
        return "http://\(target):\(port)"
    }
    
    /// Full WebSocket URL for discovery endpoint
    var discoveryWSURL: URL? {
        guard let base = nodeBaseURL else {
            print("[DiscoveredNode] No valid target: host='\(host)' ipAddress='\(ipAddress ?? "nil")'")
            return nil
        }
        let urlString = "\(base)/ws/player/discovery"
        print("[DiscoveredNode] Generated URL: \(urlString)")
        let url = URL(string: urlString)
        if url == nil {
            print("[DiscoveredNode] ✗ Failed to create URL from: \(urlString)")
        }
        return url
    }
    
    /// Full WebSocket URL for the player session endpoint
    func sessionWSURL(sessionCode: String) -> URL? {
        guard let base = nodeBaseURL else { return nil }
        return URL(string: "\(base)/ws/player/session/\(sessionCode)")
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: DiscoveredNode, rhs: DiscoveredNode) -> Bool {
        lhs.id == rhs.id && lhs.host == rhs.host
    }
}

/// Connection status of a discovered node
enum NodeConnectionStatus: Equatable {
    case connecting                    // Establishing initial WebSocket connection
    case waiting                       // Connected, waiting for admin selection
    case reconnecting(attemptNumber: Int)  // Retrying after connection failure
    case locked                        // Admin selected this node
    
    var displayText: String {
        switch self {
        case .connecting:
            return "Connecting..."
        case .waiting:
            return "Waiting..."
        case .reconnecting(let attempt):
            return "Reconnecting (\(attempt))..."
        case .locked:
            return "Selected"
        }
    }
    
    var statusColor: Color {
        switch self {
        case .connecting:
            return Color.yellow
        case .waiting:
            return Color.green
        case .reconnecting:
            return Color.orange
        case .locked:
            return Color(red: 0.753, green: 0.522, blue: 0.992) // purple
        }
    }
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
