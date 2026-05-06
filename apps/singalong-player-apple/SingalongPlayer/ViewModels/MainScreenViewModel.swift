import Foundation

/// ViewModel for the Main Screen (player session phase)
@MainActor
final class MainScreenViewModel: ObservableObject {
    // MARK: - Session State
    
    @Published private(set) var sessionCode: String = ""
    @Published private(set) var sessionToken: String = ""
    
    // MARK: - Playback State
    
    @Published private(set) var queueItems: [QueueItem] = []
    @Published private(set) var currentPlayback: PlaybackState?
    @Published private(set) var elapsedSeconds: Int = 0
    @Published private(set) var totalSeconds: Int = 0
    
    // MARK: - Session Management
    
    @Published private(set) var isConnected = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var isDisconnected = false
    
    // MARK: - Dependencies
    
    private let dependencyContainer: DependencyContainer
    private var sessionManager: WebSocketPlayerSessionManager?
    
    var onDisconnect: (() -> Void)?
    
    // MARK: - Initialization
    
    init(sessionCode: String, sessionToken: String, dependencyContainer: DependencyContainer) {
        self.sessionCode = sessionCode
        self.sessionToken = sessionToken
        self.dependencyContainer = dependencyContainer
    }
    
    // MARK: - Session Lifecycle
    
    func connectToSession() {
        guard !isConnected else { return }
        
        sessionManager = WebSocketPlayerSessionManager()
        
        Task {
            do {
                try await sessionManager?.connect(sessionCode: sessionCode)
                try await sessionManager?.send(.auth(sessionCode: sessionCode, token: sessionToken))
                isConnected = true
                startListeningToMessages()
            } catch {
                errorMessage = "Failed to connect to session: \(error.localizedDescription)"
            }
        }
    }
    
    func disconnectFromSession() {
        Task {
            await try? sessionManager?.disconnect()
            isConnected = false
        }
    }
    
    // MARK: - Playback Control
    
    func handlePlayCommand(songId: String, url: String) {
        currentPlayback = PlaybackState(
            songId: songId,
            videoUrl: url,
            status: .playing,
            startedAt: Date()
        )
        elapsedSeconds = 0
    }
    
    func handlePauseCommand() {
        currentPlayback?.status = .paused
    }
    
    func handleSeekCommand(seconds: Int) {
        elapsedSeconds = seconds
    }
    
    func handleVolumeCommand(level: Float) {
        // Delegate to AV player
    }
    
    func updateProgress(elapsed: Int, total: Int) {
        elapsedSeconds = elapsed
        totalSeconds = total
        
        Task {
            guard let songId = currentPlayback?.songId else { return }
            try? await sessionManager?.send(.progress(elapsedSeconds: elapsed, totalSeconds: total))
        }
    }
    
    func handleVideoEnded() {
        guard let songId = currentPlayback?.songId else { return }
        currentPlayback?.status = .ended
        
        Task {
            try? await sessionManager?.send(.ended(songId: songId))
        }
    }
    
    // MARK: - Queue Management
    
    func handleQueueUpdate(songs: [String]) {
        queueItems = songs.map { QueueItem(id: $0, title: "Song: \($0)") }
    }
    
    func handleAttendeesUpdate(count: Int) {
        // Update UI with attendee count
    }
    
    func handleSessionMessage(text: String) {
        // Display toast or notification
    }
    
    // MARK: - Disconnection Handling
    
    func handleDisconnect(reason: String) {
        isDisconnected = true
        isConnected = false
        errorMessage = reason
        onDisconnect?()
    }
    
    func handleSessionEnded(reason: String) {
        isDisconnected = true
        isConnected = false
        errorMessage = "Session ended: \(reason)"
        onDisconnect?()
    }
    
    // MARK: - Private Helpers
    
    private func startListeningToMessages() {
        Task {
            while isConnected, let manager = sessionManager {
                do {
                    try await manager.receiveMessages { [weak self] message in
                        Task { @MainActor in
                            self?.handleSessionMessage(message)
                        }
                    }
                } catch {
                    await MainActor.run {
                        self.isConnected = false
                        self.errorMessage = "Connection lost: \(error.localizedDescription)"
                    }
                    break
                }
            }
        }
    }
    
    private func handleSessionMessage(_ message: NodeSessionMessage) {
        switch message {
        case .authenticated:
            break
        case .disconnect(let reason):
            handleDisconnect(reason: reason)
        case .queueUpdated(let songs):
            handleQueueUpdate(songs: songs)
        case .play(let songId, let url):
            handlePlayCommand(songId: songId, url: url)
        case .pause:
            handlePauseCommand()
        case .seek(let seconds):
            handleSeekCommand(seconds: seconds)
        case .volume(let level):
            handleVolumeCommand(level: level)
        case .attendees(let count):
            handleAttendeesUpdate(count: count)
        case .sessionMessage(let text):
            handleSessionMessage(text: text)
        case .sessionEnded(let reason):
            handleSessionEnded(reason: reason)
        case .pong:
            break
        case .error(let code, let message):
            errorMessage = "Session error [\(code)]: \(message)"
        }
    }
    
    deinit {
        Task {
            await try? sessionManager?.disconnect()
        }
    }
}

// MARK: - Supporting Types

struct QueueItem: Identifiable {
    let id: String
    let title: String
}

struct PlaybackState {
    let songId: String
    let videoUrl: String
    var status: PlaybackStatus
    let startedAt: Date
    
    var elapsedTime: TimeInterval {
        Date().timeIntervalSince(startedAt)
    }
}

enum PlaybackStatus {
    case loading
    case playing
    case paused
    case ended
    case error(String)
}
