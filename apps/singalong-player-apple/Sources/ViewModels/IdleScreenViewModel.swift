import Foundation

/// ViewModel for the Idle Screen (player discovery phase)
@MainActor
final class IdleScreenViewModel: ObservableObject {
    
    @Published private(set) var discoveredNodes: [DiscoveredNode] = []
    @Published private(set) var activeConnections: [String: ConnectionStatus] = [:]
    @Published private(set) var isDiscovering = false
    @Published private(set) var errorMessage: String?
    
    var currentPhase: PlayerPhase = .idle
    
    private let discoveryCoordinator: DiscoveryCoordinator
    private let dependencyContainer: DependencyContainer
    
    init(discoveryCoordinator: DiscoveryCoordinator, dependencyContainer: DependencyContainer) {
        self.discoveryCoordinator = discoveryCoordinator
        self.dependencyContainer = dependencyContainer
    }
    
    func startDiscovery() {
        guard !isDiscovering else { return }
        isDiscovering = true
        errorMessage = nil
        
        Task {
            do {
                try await discoveryCoordinator.startDiscovery { [weak self] node in
                    self?.handleNodeDiscovered(node)
                }
            } catch {
                self.isDiscovering = false
                self.errorMessage = "Discovery failed: \(error.localizedDescription)"
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
    
    func selectNode(_ node: DiscoveredNode) {
        print("[IdleScreenViewModel] selectNode() called for node: \(node.name)")
        errorMessage = nil
        
        Task {
            print("[IdleScreenViewModel] selectNode Task started, calling coordinator.selectNode()...")
            do {
                print("[IdleScreenViewModel] About to await discoveryCoordinator.selectNode(node)")
                try await discoveryCoordinator.selectNode(node)
                print("[IdleScreenViewModel] ✓ selectNode completed successfully")
            } catch {
                print("[IdleScreenViewModel] ✗ selectNode failed with error: \(error)")
                print("[IdleScreenViewModel]   Error description: \(error.localizedDescription)")
                self.errorMessage = "Failed to select node: \(error.localizedDescription)"
            }
        }
        print("[IdleScreenViewModel] selectNode() exiting (Task scheduled)")
    }
    
    func deselectNode() {
        Task {
            await discoveryCoordinator.deselectNode()
        }
    }
    
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

enum PlayerPhase {
    case idle
    case locked
    case session
}
