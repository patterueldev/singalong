import SwiftUI
import Foundation

/// Main app state manager for the player
@MainActor
class PlayerAppState: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var discoveredNodes: [DiscoveredNode] = []
    @Published var activeConnections: [String: NodeConnectionStatus] = [:]
    @Published var selectedNodeId: String? = nil
    @Published var isDiscovering: Bool = false
    @Published var errorMessage: String? = nil
    
    @Published var lockedSessionCode: String? = nil
    @Published var lockedSessionToken: String? = nil
    @Published var playerId: String? = nil
    
    // MARK: - Private Properties
    
    private let mdnsService = MDNSDiscoveryService.shared
    private let wsManager = WebSocketDiscoveryManager.shared
    private var callbacksConfigured = false
    
    // MARK: - Initialization
    
    init() {
        print("[PlayerApp] === INIT CALLED ===")
        print("[PlayerApp] callbacksConfigured at init: \(callbacksConfigured)")
        
        // Restore persisted player ID if available
        if let savedPlayerId = UserDefaults.standard.string(forKey: "player_id") {
            self.playerId = savedPlayerId
            print("[PlayerApp] Restored player ID from UserDefaults: \(savedPlayerId)")
        }
        
        // Set up mDNS callbacks first (synchronously setup)
        setupCallbacks()
        
        // Then set up WebSocket callbacks asynchronously but immediately
        Task {
            print("[PlayerApp] >>> Spawning setupWebSocketCallbacksAsync task")
            await self.setupWebSocketCallbacksAsync()
        }
    }
    
    /// Set up WebSocket callbacks asynchronously on the actor
    private func setupWebSocketCallbacksAsync() async {
        print("[PlayerApp] >>> setupWebSocketCallbacksAsync CALLED, callbacksConfigured=\(callbacksConfigured)")
        guard !callbacksConfigured else {
            print("[PlayerApp] WebSocket callbacks already configured, skipping")
            return
        }
        
        print("[PlayerApp] >>> Setting up callbacks...")
        let ws = wsManager
        await ws.setCallback(onConnectionStatusChanged: { [weak self] nodeId, status in
            print("[PlayerApp] ✓ STATUS CALLBACK FIRED: nodeId=\(nodeId), status=\(status.displayText)")
            print("[PlayerApp] >>> Before DispatchQueue.main.async")
            DispatchQueue.main.async {
                print("[PlayerApp] >>> Inside DispatchQueue.main.async")
                print("[PlayerApp] ✓ Before update: activeConnections=\(self?.activeConnections ?? [:])")
                var updated = self?.activeConnections ?? [:]
                updated[nodeId] = status
                print("[PlayerApp] ✓ After mutation, before assignment: updated=\(updated)")
                self?.activeConnections = updated
                print("[PlayerApp] ✓ After assignment: activeConnections=\(self?.activeConnections ?? [:])")
            }
        })
        
        await ws.setCallback(onMessageReceived: { [weak self] nodeId, message in
            DispatchQueue.main.async {
                self?.handleNodeMessage(message, fromNodeId: nodeId)
            }
        })
        
        await ws.setCallback(onConnectionClosed: { [weak self] nodeId in
            DispatchQueue.main.async {
                self?.activeConnections.removeValue(forKey: nodeId)
            }
        })
        
        callbacksConfigured = true
        print("[PlayerApp] ✓ WebSocket callbacks configured")
    }
    
    // MARK: - Public Methods
    
    /// Start discovery of local nodes
    func startDiscovery() {
        guard !isDiscovering else { 
            print("[PlayerApp] Discovery already running, skipping start")
            return 
        }
        isDiscovering = true
        errorMessage = nil
        print("[PlayerApp] ===== STARTING DISCOVERY =====")
        print("[PlayerApp] isDiscovering: \(isDiscovering)")
        
        Task {
            print("[PlayerApp] Calling mdnsService.startDiscovery()...")
            await mdnsService.startDiscovery()
            print("[PlayerApp] mdnsService.startDiscovery() returned")
        }
    }
    
    /// Stop discovery
    func stopDiscovery() {
        print("[PlayerApp] ===== STOPPING DISCOVERY =====")
        isDiscovering = false
        Task {
            print("[PlayerApp] Calling mdnsService.stopDiscovery()...")
            await mdnsService.stopDiscovery()
            print("[PlayerApp] mdnsService.stopDiscovery() returned")
        }
    }
    
    /// Connect to a specific discovered node
    func connectToNode(_ node: DiscoveredNode) {
        Task {
            do {
                try await wsManager.connect(to: node)
            } catch {
                await setError("Failed to connect to \(node.name): \(error.localizedDescription)")
            }
        }
    }
    
    /// Disconnect from all nodes
    func disconnectAll() {
        Task {
            await wsManager.disconnectAll()
            selectedNodeId = nil
        }
    }
    
    /// Handle lock message received from node
    func handleLockMessage(sessionCode: String, token: String, fromNodeId nodeId: String) {
        selectedNodeId = nodeId
        lockedSessionCode = sessionCode
        lockedSessionToken = token
        
        print("[PlayerApp] Locked to session \(sessionCode) on node \(nodeId)")
        
        // Now transition to playback WebSocket
        // This will be implemented in next phase (P2.7)
    }
    
    /// Handle player selected message from node
    private func handlePlayerSelectedMessage(sessionCode: String, sessionTitle: String, fromNodeId nodeId: String) {
        self.lockedSessionCode = sessionCode
        print("[PlayerApp] ✓ Player selected for session \(sessionCode) ('\(sessionTitle)') by admin")
        print("[PlayerApp] ✓ Now transitioning to main screen...")
        print("[PlayerApp] ✓ Stopping discovery and mDNS listening...")
        
        // Stop discovering other nodes since we're now locked
        Task {
            await mdnsService.stopDiscovery()
            print("[PlayerApp] ✓ mDNS discovery stopped")
        }
    }
    
    /// Handle registration response from node
    func handleRegisteredMessage(playerId: String, fromNodeId nodeId: String) {
        self.playerId = playerId
        // Persist player ID so it survives app restarts
        UserDefaults.standard.set(playerId, forKey: "player_id")
        print("[PlayerApp] Registered with player ID: \(playerId) (persisted to UserDefaults)")
    }
    
    // MARK: - Private Methods
    
    private func setupCallbacks() {
        // Set up mDNS callbacks
        Task {
            let mdns = mdnsService
            await mdns.setCallback(onNodesUpdated: { [weak self] nodes in
                DispatchQueue.main.async {
                    self?.discoveredNodes = nodes
                }
            })
            
            await mdns.setCallback(onNodeRemoved: { [weak self] node in
                DispatchQueue.main.async {
                    self?.activeConnections.removeValue(forKey: node.id)
                    if self?.selectedNodeId == node.id {
                        self?.selectedNodeId = nil
                    }
                }
                
                // Disconnect from WebSocket when node is removed from mDNS
                Task {
                    await self?.wsManager.disconnect(fromNodeId: node.id)
                }
            })
        }
    }
    
    private func handleNodeMessage(_ message: NodeMessage, fromNodeId nodeId: String) {
        switch message {
        case .registered(let playerId):
            handleRegisteredMessage(playerId: playerId, fromNodeId: nodeId)
            
        case .playerSelected(let sessionCode, let sessionTitle):
            handlePlayerSelectedMessage(sessionCode: sessionCode, sessionTitle: sessionTitle, fromNodeId: nodeId)
            
        case .lock(let sessionCode, let token):
            handleLockMessage(sessionCode: sessionCode, token: token, fromNodeId: nodeId)
            
        case .pong:
            print("[PlayerApp] Received pong from \(nodeId)")
            
        case .error(let code, let errorMsg):
            setError("Node error (\(code)): \(errorMsg)")
        }
    }
    
    private func setError(_ message: String) {
        DispatchQueue.main.async {
            self.errorMessage = message
            print("[PlayerApp] Error: \(message)")
        }
    }
}
