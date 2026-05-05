import Foundation
import Network

/// Service for discovering Singalong Nodes on the local network via mDNS/Bonjour
actor MDNSDiscoveryService: NSObject, NetServiceBrowserDelegate {
    
    static let shared = MDNSDiscoveryService()
    
    private let serviceBrowser: NetServiceBrowser
    private var discoveredNodes: [String: DiscoveredNode] = [:]
    private var serviceResolver: NetServiceDelegate?
    
    // MARK: - Properties
    var onNodesUpdated: (([DiscoveredNode]) -> Void)?
    var onNodeAdded: ((DiscoveredNode) -> Void)?
    var onNodeRemoved: ((DiscoveredNode) -> Void)?
    
    private override init() {
        self.serviceBrowser = NetServiceBrowser()
        super.init()
    }
    
    // MARK: - Public Methods
    
    /// Start scanning for Singalong Nodes
    func startDiscovery() {
        serviceBrowser.delegate = self
        serviceBrowser.searchForServices(ofType: "_singalong-node._tcp", inDomain: "local.")
        print("[mDNS] Started scanning for _singalong-node._tcp services")
    }
    
    /// Stop scanning for nodes
    func stopDiscovery() {
        serviceBrowser.stop()
        discoveredNodes.removeAll()
        print("[mDNS] Stopped scanning")
    }
    
    /// Get list of discovered nodes
    func getDiscoveredNodes() -> [DiscoveredNode] {
        return Array(discoveredNodes.values).sorted { $0.discoveredAt > $1.discoveredAt }
    }
    
    /// Get specific node by ID
    func getNode(byId id: String) -> DiscoveredNode? {
        return discoveredNodes[id]
    }
    
    // MARK: - NetServiceBrowserDelegate
    
    nonisolated func netServiceBrowser(
        _ browser: NetServiceBrowser,
        didFind netService: NetService,
        moreComing: Bool
    ) {
        print("[mDNS] Found service: \(netService.name) on \(netService.hostName ?? "unknown")")
        
        // Resolve the service to get IP address
        netService.delegate = MDNSServiceResolver(discoveryService: self)
        netService.resolve(withTimeout: 5.0)
    }
    
    nonisolated func netServiceBrowser(
        _ browser: NetServiceBrowser,
        didRemove netService: NetService,
        moreComing: Bool
    ) {
        print("[mDNS] Service removed: \(netService.name)")
        
        Task {
            await self.removeNode(withId: netService.name)
        }
    }
    
    nonisolated func netServiceBrowser(
        _ browser: NetServiceBrowser,
        didNotSearch errorDict: [String : NSNumber]
    ) {
        print("[mDNS] Error during search: \(errorDict)")
    }
    
    // MARK: - Internal Methods
    
    func addNode(_ node: DiscoveredNode) {
        discoveredNodes[node.id] = node
        print("[mDNS] Added node: \(node.name) at \(node.ipAddress ?? "unknown"):\(node.port)")
        onNodeAdded?(node)
        notifyUpdate()
    }
    
    func updateNode(_ node: DiscoveredNode) {
        discoveredNodes[node.id] = node
        print("[mDNS] Updated node: \(node.name)")
        notifyUpdate()
    }
    
    func removeNode(withId id: String) {
        if let removed = discoveredNodes.removeValue(forKey: id) {
            print("[mDNS] Removed node: \(removed.name)")
            onNodeRemoved?(removed)
            notifyUpdate()
        }
    }
    
    private func notifyUpdate() {
        let nodes = getDiscoveredNodes()
        onNodesUpdated?(nodes)
    }
}

/// Helper class to resolve NetService details (IP address)
private class MDNSServiceResolver: NSObject, NetServiceDelegate {
    
    let discoveryService: MDNSDiscoveryService
    
    init(discoveryService: MDNSDiscoveryService) {
        self.discoveryService = discoveryService
    }
    
    func netServiceDidResolveAddress(_ sender: NetService) {
        guard let addresses = sender.addresses, !addresses.isEmpty else {
            print("[mDNS] Could not resolve addresses for \(sender.name)")
            return
        }
        
        // Extract IPv4 address from sockaddr
        if let ipAddress = extractIPAddress(from: addresses[0]) {
            let port = Int(sender.port)
            
            let node = DiscoveredNode(
                id: sender.name,
                name: sender.name.replacingOccurrences(of: "._singalong-node._tcp.", with: ""),
                host: sender.hostName ?? sender.name,
                port: port,
                ipAddress: ipAddress,
                discoveredAt: Date()
            )
            
            Task {
                await discoveryService.addNode(node)
            }
        }
        
        sender.stop()
    }
    
    func netService(_ sender: NetService, didNotResolve errorDict: [String : NSNumber]) {
        print("[mDNS] Could not resolve service \(sender.name): \(errorDict)")
        sender.stop()
    }
    
    private func extractIPAddress(from addressData: Data) -> String? {
        var ipAddress: String?
        
        addressData.withUnsafeBytes { buffer in
            let rawBytes = buffer.baseAddress!.assumingMemoryBound(to: UInt8.self)
            let sa_family = rawBytes.pointee
            
            // AF_INET = 2 (IPv4)
            if sa_family == 2 {
                let octets = (rawBytes + 4).pointee
                let ips = (rawBytes + 5).pointee
                let ipa = (rawBytes + 6).pointee
                let ipa2 = (rawBytes + 7).pointee
                ipAddress = "\(octets).\(ips).\(ipa).\(ipa2)"
            }
        }
        
        return ipAddress
    }
}
