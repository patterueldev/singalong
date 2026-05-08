import Foundation

/// ViewModel for the Main Screen (player session phase)
@MainActor
final class MainScreenViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published private(set) var sessionCode: String?
    @Published private(set) var sessionToken: String?
    @Published private(set) var nodeBaseUrl: String?
    @Published private(set) var queueItems: [QueueItem] = []
    @Published private(set) var isConnected = false
    @Published private(set) var isDisconnected = false
    @Published private(set) var currentPlayback: PlaybackState?
    @Published private(set) var errorMessage: String?
    @Published private(set) var attendeeCount = 0
    
    // MARK: - Private Properties
    
    private var sessionManager: WebSocketPlayerSessionManager?
    private var messageStreamTask: Task<Void, Never>?
    
    // MARK: - Initialization
    
    init(sessionCode: String, sessionToken: String, nodeBaseUrl: String) {
        self.sessionCode = sessionCode
        self.sessionToken = sessionToken
        self.nodeBaseUrl = nodeBaseUrl
        print("[MainScreenViewModel] Init with session \(sessionCode) @ \(nodeBaseUrl)")
    }
    
    // MARK: - Connection Methods
    
    func connectToSession() {
        guard !isConnected,
              let code = sessionCode,
              let token = sessionToken,
              let nodeUrl = nodeBaseUrl else {
            print("[MainScreenViewModel] Cannot connect: already connected or missing credentials")
            return
        }
        
        print("[MainScreenViewModel] Connecting to session \(code) @ \(nodeUrl)")
        
        sessionManager = WebSocketPlayerSessionManager()
        setupMessageHandlers()
        
        Task {
            do {
                try await sessionManager?.connect(to: code, token: token, nodeBaseUrl: nodeUrl)
                self.isConnected = true
                print("[MainScreenViewModel] ✓ Connected to session")
                
                startListeningToMessages()
            } catch {
                self.errorMessage = "Failed to connect: \(error.localizedDescription)"
                print("[MainScreenViewModel] ✗ Connect failed: \(error)")
            }
        }
    }
    
    func disconnectFromSession() {
        guard isConnected else { return }
        
        print("[MainScreenViewModel] Disconnecting from session")
        
        messageStreamTask?.cancel()
        
        Task {
            try await sessionManager?.disconnect()
            
            self.isConnected = false
            self.isDisconnected = true
            self.sessionManager = nil
            self.clearSessionState()
        }
    }
    
    // MARK: - Message Handlers Setup
    
    private func setupMessageHandlers() {
        sessionManager?.onAuthenticated = { [weak self] in
            print("[MainScreenViewModel] Session authenticated")
            self?.isConnected = true
        }
        
        sessionManager?.onDisconnect = { [weak self] in
            print("[MainScreenViewModel] Disconnect received from node")
            self?.handleDisconnect()
        }
        
        sessionManager?.onQueueUpdated = { [weak self] songIds in
            print("[MainScreenViewModel] Queue updated: \(songIds)")
            self?.handleQueueUpdated(songIds)
        }
        
        sessionManager?.onPlay = { [weak self] songId, url in
            print("[MainScreenViewModel] Play: \(songId)")
            self?.handlePlayCommand(songId: songId, url: url)
        }
        
        sessionManager?.onPause = { [weak self] in
            print("[MainScreenViewModel] Pause command")
            self?.handlePauseCommand()
        }
        
        sessionManager?.onSeek = { [weak self] seconds in
            print("[MainScreenViewModel] Seek to \(seconds)s")
            self?.handleSeekCommand(seconds: seconds)
        }
        
        sessionManager?.onVolume = { [weak self] level in
            print("[MainScreenViewModel] Volume: \(level)")
            self?.handleVolumeCommand(level: level)
        }
        
        sessionManager?.onAttendees = { [weak self] count in
            print("[MainScreenViewModel] Attendee count: \(count)")
            self?.attendeeCount = count
        }
        
        sessionManager?.onSessionMessage = { [weak self] message in
            print("[MainScreenViewModel] Message: \(message)")
        }
        
        sessionManager?.onSessionEnded = { [weak self] in
            print("[MainScreenViewModel] Session ended by admin")
            self?.handleSessionEnded()
        }
        
        sessionManager?.onError = { [weak self] error in
            print("[MainScreenViewModel] ✗ Error: \(error)")
            self?.errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Message Listener
    
    private func startListeningToMessages() {
        guard let sessionManager = sessionManager else { return }
        
        messageStreamTask = Task {
            for await message in sessionManager.receiveStream() {
                // Messages are handled by callbacks in setupMessageHandlers()
                print("[MainScreenViewModel] Processed message")
            }
        }
    }
    
    // MARK: - Playback Command Handlers
    
    private func handlePlayCommand(songId: String, url: String) {
        currentPlayback = PlaybackState(
            songId: songId,
            url: url,
            status: .playing,
            progressSeconds: 0,
            totalSeconds: 0
        )
    }
    
    private func handlePauseCommand() {
        if var playback = currentPlayback {
            playback.status = .paused
            currentPlayback = playback
        }
    }
    
    private func handleSeekCommand(seconds: Int) {
        if var playback = currentPlayback {
            playback.progressSeconds = seconds
            currentPlayback = playback
        }
    }
    
    private func handleVolumeCommand(level: Float) {
        if var playback = currentPlayback {
            playback.volume = level
            currentPlayback = playback
        }
    }
    
    // MARK: - Session State Handlers
    
    private func handleQueueUpdated(_ songIds: [String]) {
        // TODO: Fetch actual queue items from API and populate queueItems
        queueItems = songIds.map { id in
            QueueItem(id: id, title: "Song", artist: "Unknown")
        }
    }
    
    private func handleDisconnect() {
        isDisconnected = true
        clearSessionState()
    }
    
    private func handleSessionEnded() {
        isDisconnected = true
        errorMessage = "Session ended by admin"
        clearSessionState()
    }
    
    private func clearSessionState() {
        queueItems = []
        currentPlayback = nil
        attendeeCount = 0
        messageStreamTask?.cancel()
    }
    
    // MARK: - Cleanup
    
    deinit {
        messageStreamTask?.cancel()
        Task {
            try await sessionManager?.disconnect()
        }
    }
}

// MARK: - Domain Models

struct PlaybackState {
    var songId: String
    var url: String
    var status: PlaybackStatus
    var progressSeconds: Int
    var totalSeconds: Int
    var volume: Float = 1.0
}

enum PlaybackStatus {
    case idle
    case loading
    case playing
    case paused
    case ended
    case error(String)
}

struct QueueItem: Identifiable {
    let id: String
    let title: String
    let artist: String
}
