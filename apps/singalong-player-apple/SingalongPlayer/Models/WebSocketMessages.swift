import Foundation

/// Messages sent from Player to Node during discovery phase
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

/// Messages received from Node by Player during discovery phase
enum NodeMessage: Codable {
    case registered(playerId: String)
    case playerSelected(sessionCode: String, sessionTitle: String)
    case lock(sessionCode: String, token: String)
    case pong
    case error(code: String, message: String)
    
    private enum CodingKeys: String, CodingKey {
        case type
        case playerId = "player_id"
        case sessionCode = "session_code"
        case sessionTitle = "session_title"
        case token
        case code
        case message
    }
    
    private enum MessageType: String, Codable {
        case registered
        case playerSelected = "player_selected"
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
        case .playerSelected(let sessionCode, let sessionTitle):
            try container.encode(MessageType.playerSelected, forKey: .type)
            try container.encode(sessionCode, forKey: .sessionCode)
            try container.encode(sessionTitle, forKey: .sessionTitle)
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
        case .playerSelected:
            let sessionCode = try container.decode(String.self, forKey: .sessionCode)
            let sessionTitle = try container.decode(String.self, forKey: .sessionTitle)
            self = .playerSelected(sessionCode: sessionCode, sessionTitle: sessionTitle)
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

// MARK: - Player Session Phase Messages (after player is locked)

/// Messages sent from Player to Node during player session phase
enum PlayerSessionMessage: Codable {
    case auth(sessionCode: String, token: String)
    case progress(elapsedSeconds: Int, totalSeconds: Int)
    case ended(songId: String)
    case ping
    
    private enum CodingKeys: String, CodingKey {
        case type
        case sessionCode = "session_code"
        case token
        case elapsedSeconds = "elapsed_seconds"
        case totalSeconds = "total_seconds"
        case songId = "song_id"
    }
    
    private enum MessageType: String, Codable {
        case auth
        case progress
        case ended
        case ping
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        switch self {
        case .auth(let sessionCode, let token):
            try container.encode(MessageType.auth, forKey: .type)
            try container.encode(sessionCode, forKey: .sessionCode)
            try container.encode(token, forKey: .token)
        case .progress(let elapsed, let total):
            try container.encode(MessageType.progress, forKey: .type)
            try container.encode(elapsed, forKey: .elapsedSeconds)
            try container.encode(total, forKey: .totalSeconds)
        case .ended(let songId):
            try container.encode(MessageType.ended, forKey: .type)
            try container.encode(songId, forKey: .songId)
        case .ping:
            try container.encode(MessageType.ping, forKey: .type)
        }
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(MessageType.self, forKey: .type)
        
        switch type {
        case .auth:
            let sessionCode = try container.decode(String.self, forKey: .sessionCode)
            let token = try container.decode(String.self, forKey: .token)
            self = .auth(sessionCode: sessionCode, token: token)
        case .progress:
            let elapsed = try container.decode(Int.self, forKey: .elapsedSeconds)
            let total = try container.decode(Int.self, forKey: .totalSeconds)
            self = .progress(elapsedSeconds: elapsed, totalSeconds: total)
        case .ended:
            let songId = try container.decode(String.self, forKey: .songId)
            self = .ended(songId: songId)
        case .ping:
            self = .ping
        }
    }
}

/// Messages received from Node by Player during player session phase
enum NodeSessionMessage: Codable {
    case authenticated
    case disconnect(reason: String)
    case queueUpdated(songs: [String]) // Simplified for now
    case play(songId: String, url: String)
    case pause
    case seek(seconds: Int)
    case volume(level: Float)
    case attendees(count: Int)
    case sessionMessage(text: String)
    case sessionEnded(reason: String)
    case pong
    case error(code: String, message: String)
    
    private enum CodingKeys: String, CodingKey {
        case type
        case reason
        case songs
        case songId = "song_id"
        case url
        case seconds
        case level
        case count
        case text
        case code
        case message
    }
    
    private enum MessageType: String, Codable {
        case authenticated
        case disconnect
        case queueUpdated = "queue:updated"
        case play
        case pause
        case seek
        case volume
        case attendees
        case sessionMessage = "session:message"
        case sessionEnded = "session:ended"
        case pong
        case error
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        switch self {
        case .authenticated:
            try container.encode(MessageType.authenticated, forKey: .type)
        case .disconnect(let reason):
            try container.encode(MessageType.disconnect, forKey: .type)
            try container.encode(reason, forKey: .reason)
        case .queueUpdated(let songs):
            try container.encode(MessageType.queueUpdated, forKey: .type)
            try container.encode(songs, forKey: .songs)
        case .play(let songId, let url):
            try container.encode(MessageType.play, forKey: .type)
            try container.encode(songId, forKey: .songId)
            try container.encode(url, forKey: .url)
        case .pause:
            try container.encode(MessageType.pause, forKey: .type)
        case .seek(let seconds):
            try container.encode(MessageType.seek, forKey: .type)
            try container.encode(seconds, forKey: .seconds)
        case .volume(let level):
            try container.encode(MessageType.volume, forKey: .type)
            try container.encode(level, forKey: .level)
        case .attendees(let count):
            try container.encode(MessageType.attendees, forKey: .type)
            try container.encode(count, forKey: .count)
        case .sessionMessage(let text):
            try container.encode(MessageType.sessionMessage, forKey: .type)
            try container.encode(text, forKey: .text)
        case .sessionEnded(let reason):
            try container.encode(MessageType.sessionEnded, forKey: .type)
            try container.encode(reason, forKey: .reason)
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
        case .authenticated:
            self = .authenticated
        case .disconnect:
            let reason = try container.decode(String.self, forKey: .reason)
            self = .disconnect(reason: reason)
        case .queueUpdated:
            let songs = try container.decode([String].self, forKey: .songs)
            self = .queueUpdated(songs: songs)
        case .play:
            let songId = try container.decode(String.self, forKey: .songId)
            let url = try container.decode(String.self, forKey: .url)
            self = .play(songId: songId, url: url)
        case .pause:
            self = .pause
        case .seek:
            let seconds = try container.decode(Int.self, forKey: .seconds)
            self = .seek(seconds: seconds)
        case .volume:
            let level = try container.decode(Float.self, forKey: .level)
            self = .volume(level: level)
        case .attendees:
            let count = try container.decode(Int.self, forKey: .count)
            self = .attendees(count: count)
        case .sessionMessage:
            let text = try container.decode(String.self, forKey: .text)
            self = .sessionMessage(text: text)
        case .sessionEnded:
            let reason = try container.decode(String.self, forKey: .reason)
            self = .sessionEnded(reason: reason)
        case .pong:
            self = .pong
        case .error:
            let code = try container.decode(String.self, forKey: .code)
            let message = try container.decode(String.self, forKey: .message)
            self = .error(code: code, message: message)
        }
    }
}
