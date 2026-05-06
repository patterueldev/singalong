import Foundation
import Observation

/// ViewModel for the Idle Screen (player discovery phase)
/// Responsible for managing mDNS discovery, node selection, and transitions to locked state
@MainActor
final class IdleScreenViewModel: ObservableObject {
    // MARK: - State
    
    @Published private(set) var discoveredNodes: [DiscoveredNode] = []
    @Published private(set) var activeConnections: [String: ConnectionStatus] = [:]
    @Published private(set) var isDiscovering = false
    @Published private(set) var errorMessage: String?
    
    var currentPhase: PlayerPhase = .idle
    
    // MARK: - Dependencies
    
    private let discoveryCoordinator: DiscoveryCoordinator
    private let dependencyContainer: DependencyContainer
    
    // MARK: - Initialization
    
    init(discoveryCoordinator: DiscoveryCoordinator, dependencyContainer: DependencyContainer) {
        self.discoveryCoordinator = discoveryCoordinator
        self.dependencyContainer = dependencyContainer
    }
    
    // MARK: - Discovery Management
    
    func startDiscovery() {
        guard !isDiscovering else { return }
        isDiscovering = true
        errorMessage = nil
        
        Task {
            do {
                try await discoveryCoordinator.startDiscovery { [weak self] node in
                    await MainActor.run {
                        self?.handleNodeDiscovered(node)
                    }
                }
            } catch {
                await MainActor.run {
                    self.isDiscovering = false
                    self.errorMessage = "Discovery failed: \(error.localizedDescription)"
                }
            }
        }
    }
    
    func stopDiscovery() {
        guard isDiscovering else { return }
        isDiscovering = false
        
        Task {
            await discoveryCoordinator.stopDiscovery()
        }
    }
    
    // MARK: - Node Selection
    
    func selectNode(_ node: DiscoveredNode) {
        errorMessage = nil
        
        Task {
            do {
                try await discoveryCoordinator.selectNode(node)
            } catch {
                self.errorMessage = "Failed to select node: \(error.localizedDescription)"
            }
        }
    }
    
    func deselectNode() {
        Task {
            await discoveryCoordinator.deselectNode()
        }
    }
    
    // MARK: - Private Helpers
    
    private func handleNodeDiscovered(_ node: DiscoveredNode) {
        if !discoveredNodes.contains(where: { $0.id == node.id }) {
            discoveredNodes.append(node)
        }
    }
    
    deinit {
        Task {
            await discoveryCoordinator.stopDiscovery()
        }
    }
}

// MARK: - Supporting Types

enum PlayerPhase {
    case idle
    case locked
    case session
}
