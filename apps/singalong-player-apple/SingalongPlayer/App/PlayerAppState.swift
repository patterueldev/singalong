import SwiftUI
import Foundation

/// Main app state manager for the player
@MainActor
class PlayerAppState: ObservableObject {
    
    static let shared = PlayerAppState()
    
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
        // Set up mDNS callbacks first (synchronously setup)
        setupCallbacks()
        
        // Then set up WebSocket callbacks asynchronously but immediately
        Task {
            await self.setupWebSocketCallbacksAsync()
        }
    }
    
    /// Set up WebSocket callbacks asynchronously on the actor
    private func setupWebSocketCallbacksAsync() async {
        guard !callbacksConfigured else {
            print("[PlayerApp] WebSocket callbacks already configured, skipping")
            return
        }
        
        let ws = wsManager
        await ws.setCallback(onConnectionStatusChanged: { [weak self] nodeId, status in
            print("[PlayerApp] ✓ STATUS CALLBACK FIRED: nodeId=\(nodeId), status=\(status.displayText)")
            DispatchQueue.main.async {
                print("[PlayerApp] ✓ Updating activeConnections[\(nodeId)] = \(status.displayText)")
                self?.activeConnections[nodeId] = status
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
    
    /// Handle registration response from node
    func handleRegisteredMessage(playerId: String, fromNodeId nodeId: String) {
        self.playerId = playerId
        print("[PlayerApp] Registered with player ID: \(playerId)")
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
            })
        }
    }
    
    private func handleNodeMessage(_ message: NodeMessage, fromNodeId nodeId: String) {
        switch message {
        case .registered(let playerId):
            handleRegisteredMessage(playerId: playerId, fromNodeId: nodeId)
            
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
