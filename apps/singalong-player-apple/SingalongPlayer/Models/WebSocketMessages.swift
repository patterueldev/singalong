import Foundation

/// Messages sent from Player to Node
enum PlayerMessage: Codable {
    case register(name: String, platform: String)
    case locked(playerId: String)
    case auth(sessionCode: String, token: String)
    case ping
    
    private enum CodingKeys: String, CodingKey {
        case type
        case name
        case platform
        case playerId = "player_id"
        case sessionCode = "session_code"
        case token
    }
    
    private enum MessageType: String, Codable {
        case register
        case locked
        case auth
        case ping
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        switch self {
        case .register(let name, let platform):
            try container.encode(MessageType.register, forKey: .type)
            try container.encode(name, forKey: .name)
            try container.encode(platform, forKey: .platform)
        case .locked(let playerId):
            try container.encode(MessageType.locked, forKey: .type)
            try container.encode(playerId, forKey: .playerId)
        case .auth(let sessionCode, let token):
            try container.encode(MessageType.auth, forKey: .type)
            try container.encode(sessionCode, forKey: .sessionCode)
            try container.encode(token, forKey: .token)
        case .ping:
            try container.encode(MessageType.ping, forKey: .type)
        }
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(MessageType.self, forKey: .type)
        
        switch type {
        case .register:
            let name = try container.decode(String.self, forKey: .name)
            let platform = try container.decode(String.self, forKey: .platform)
            self = .register(name: name, platform: platform)
        case .locked:
            let playerId = try container.decode(String.self, forKey: .playerId)
            self = .locked(playerId: playerId)
        case .auth:
            let sessionCode = try container.decode(String.self, forKey: .sessionCode)
            let token = try container.decode(String.self, forKey: .token)
            self = .auth(sessionCode: sessionCode, token: token)
        case .ping:
            self = .ping
        }
    }
}

/// Messages received from Node by Player
enum NodeMessage: Codable {
    case registered(playerId: String)
    case lock(sessionCode: String, token: String)
    case pong
    case error(code: String, message: String)
    
    private enum CodingKeys: String, CodingKey {
        case type
        case playerId = "player_id"
        case sessionCode = "session_code"
        case token
        case code
        case message
    }
    
    private enum MessageType: String, Codable {
        case registered
        case lock
        case pong
        case error
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        switch self {
        case .registered(let playerId):
            try container.encode(MessageType.registered, forKey: .type)
            try container.encode(playerId, forKey: .playerId)
        case .lock(let sessionCode, let token):
            try container.encode(MessageType.lock, forKey: .type)
            try container.encode(sessionCode, forKey: .sessionCode)
            try container.encode(token, forKey: .token)
        case .pong:
            try container.encode(MessageType.pong, forKey: .type)
        case .error(let code, let message):
            try container.encode(MessageType.error, forKey: .type)
            try container.encode(code, forKey: .code)
            try container.encode(message, forKey: .message)
        }
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(MessageType.self, forKey: .type)
        
        switch type {
        case .registered:
            let playerId = try container.decode(String.self, forKey: .playerId)
            self = .registered(playerId: playerId)
        case .lock:
            let sessionCode = try container.decode(String.self, forKey: .sessionCode)
            let token = try container.decode(String.self, forKey: .token)
            self = .lock(sessionCode: sessionCode, token: token)
        case .pong:
            self = .pong
        case .error:
            let code = try container.decode(String.self, forKey: .code)
            let message = try container.decode(String.self, forKey: .message)
            self = .error(code: code, message: message)
        }
    }
}
