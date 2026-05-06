import Darwin
import Foundation
import Network

/// Service for discovering Singalong Nodes on the local network via mDNS/Bonjour
actor MDNSDiscoveryService: NSObject, NetServiceBrowserDelegate {
    
    static let shared = MDNSDiscoveryService()
    
    private let serviceBrowser: NetServiceBrowser
    private var discoveredNodes: [String: DiscoveredNode] = [:]
    private var activeResolvers: [String: MDNSServiceResolver] = [:]  // Keep resolvers alive
    private var activeServices: [String: NetService] = [:]  // ALSO keep NetService objects alive
    private var resolvedServices: Set<String> = []  // Track which services have been resolved
    
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
        print("[mDNS] ===== STARTING mDNS DISCOVERY =====")
        print("[mDNS] Service type: _singalong-node._tcp")
        print("[mDNS] Domain: local.")
        print("[mDNS] Browser delegate set and search started")
        serviceBrowser.delegate = self
        serviceBrowser.searchForServices(ofType: "_singalong-node._tcp", inDomain: "local.")
        print("[mDNS] Started scanning for _singalong-node._tcp services")
    }
    
    /// Stop scanning for nodes
    func stopDiscovery() {
        serviceBrowser.stop()
        discoveredNodes.removeAll()
        activeResolvers.removeAll()
        activeServices.removeAll()
        resolvedServices.removeAll()
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
    
    /// Set the onNodesUpdated callback
    func setCallback(onNodesUpdated: @escaping ([DiscoveredNode]) -> Void) {
        self.onNodesUpdated = onNodesUpdated
    }
    
    /// Set the onNodeAdded callback
    func setCallback(onNodeAdded: @escaping (DiscoveredNode) -> Void) {
        self.onNodeAdded = onNodeAdded
    }
    
    /// Set the onNodeRemoved callback
    func setCallback(onNodeRemoved: @escaping (DiscoveredNode) -> Void) {
        self.onNodeRemoved = onNodeRemoved
    }
    
    // MARK: - NetServiceBrowserDelegate
    
    nonisolated func netServiceBrowser(
        _ browser: NetServiceBrowser,
        didFind netService: NetService,
        moreComing: Bool
    ) {
        print("[mDNS] ✓ Found service: '\(netService.name)' on '\(netService.hostName ?? "unknown")'")
        print("[mDNS]   - Port: \(netService.port)")
        print("[mDNS]   - More coming: \(moreComing)")
        
        // Create resolver and keep it alive
        let resolver = MDNSServiceResolver(discoveryService: self, serviceId: netService.name)
        netService.delegate = resolver
        
        Task {
            // Store BOTH the resolver and the NetService to keep them alive
            await self.storeResolver(resolver, forService: netService.name)
            await self.storeService(netService, forId: netService.name)
        }
        
        // Small delay to allow service to fully populate
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            print("[mDNS] Resolving service '\(netService.name)' (timeout 10s)...")
            netService.resolve(withTimeout: 10.0)
        }
    }
    
    nonisolated func netServiceBrowser(
        _ browser: NetServiceBrowser,
        didRemove netService: NetService,
        moreComing: Bool
    ) {
        print("[mDNS] ✗ Service removed: \(netService.name)")
        
        Task {
            // Only remove the node if it was already resolved (not during initial discovery)
            let wasResolved = await self.isServiceResolved(netService.name)
            if wasResolved {
                print("[mDNS] Service was resolved, removing node")
                await self.removeNode(withId: netService.name)
            } else {
                print("[mDNS] Service not yet resolved, skipping node removal")
            }
        }
    }
    
    nonisolated func netServiceBrowser(
        _ browser: NetServiceBrowser,
        didNotSearch errorDict: [String : NSNumber]
    ) {
        print("[mDNS] ✗ ERROR during search: \(errorDict)")
        if let errorCode = errorDict[NetService.errorCode] {
            print("[mDNS]   Error code: \(errorCode)")
        }
    }
    
    // MARK: - Internal Methods
    
    fileprivate func storeResolver(_ resolver: MDNSServiceResolver, forService serviceId: String) async {
        activeResolvers[serviceId] = resolver
        print("[mDNS] Stored resolver for: \(serviceId)")
    }
    
    fileprivate func removeResolver(forService serviceId: String) async {
        activeResolvers.removeValue(forKey: serviceId)
        print("[mDNS] Removed resolver for: \(serviceId)")
    }
    
    fileprivate func storeService(_ service: NetService, forId serviceId: String) async {
        activeServices[serviceId] = service
        print("[mDNS] Stored NetService for: \(serviceId)")
    }
    
    fileprivate func removeService(forId serviceId: String) async {
        activeServices.removeValue(forKey: serviceId)
        print("[mDNS] Removed NetService for: \(serviceId)")
    }
    
    fileprivate func markServiceResolved(_ serviceId: String) async {
        resolvedServices.insert(serviceId)
        print("[mDNS] Marked service as resolved: \(serviceId)")
    }
    
    fileprivate func isServiceResolved(_ serviceId: String) async -> Bool {
        return resolvedServices.contains(serviceId)
    }
    
    func addNode(_ node: DiscoveredNode) {
        discoveredNodes[node.id] = node
        print("[mDNS] ✓ Added node: '\(node.name)' at \(node.ipAddress ?? "unknown"):\(node.port)")
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
        print("[mDNS] Updated node list: \(nodes.count) node(s) discovered")
        onNodesUpdated?(nodes)
    }
}

/// Helper class to resolve NetService details (IP address)
private class MDNSServiceResolver: NSObject, NetServiceDelegate {
    
    let discoveryService: MDNSDiscoveryService
    let serviceId: String
    
    init(discoveryService: MDNSDiscoveryService, serviceId: String) {
        self.discoveryService = discoveryService
        self.serviceId = serviceId
        super.init()
        print("[mDNS] Created resolver for service: '\(serviceId)'")
    }
    
    func netServiceDidResolveAddress(_ sender: NetService) {
        print("[mDNS] ✓ netServiceDidResolveAddress called for: '\(sender.name)'")
        guard let addresses = sender.addresses, !addresses.isEmpty else {
            print("[mDNS] ✗ Could not resolve addresses for '\(sender.name)' - addresses array empty")
            cleanup()
            return
        }
        
        print("[mDNS] ✓ Got \(addresses.count) address(es) for '\(sender.name)'")
        
        // Try to extract IPv4 from any of the addresses
        var ipAddress: String?
        for (index, addressData) in addresses.enumerated() {
            print("[mDNS]   Address \(index):", terminator: "")
            if let extracted = extractIPAddress(from: addressData) {
                ipAddress = extracted
                print("[mDNS]     ✓ FOUND: \(extracted)")
                break  // Found IPv4, stop searching
            }
        }
        
        // If no IPv4 found, try to resolve the hostname manually
        if ipAddress == nil {
            print("[mDNS] No IPv4 in addresses array, trying manual DNS resolution...")
            if let hostName = sender.hostName {
                print("[mDNS] Resolving hostname: \(hostName)")
                ipAddress = resolveHostname(hostName)
            }
        }
        
        guard let ipAddress = ipAddress else {
            print("[mDNS] ✗✗ FAILED: No IPv4 address found in mDNS or DNS")
            cleanup()
            sender.stop()
            return
        }
        
        let port = Int(sender.port)
        print("[mDNS] ✓ Port from service: \(port)")
        
        let node = DiscoveredNode(
            id: sender.name,
            name: sender.name.replacingOccurrences(of: "._singalong-node._tcp.", with: ""),
            host: sender.hostName ?? sender.name,
            port: port,
            ipAddress: ipAddress,
            discoveredAt: Date()
        )
        
        print("[mDNS] ✓ Successfully resolved: \(ipAddress):\(port)")
        
        Task {
            // Mark as resolved BEFORE adding node to prevent removal in didRemove
            await discoveryService.markServiceResolved(self.serviceId)
            await discoveryService.addNode(node)
            // DON'T remove the resolver/service yet - keep them alive
            // They will be cleaned up when the service is actually removed from the network
        }
    }
    
    private func resolveHostname(_ hostname: String) -> String? {
        var hints = addrinfo()
        hints.ai_family = AF_INET  // IPv4 only
        hints.ai_socktype = SOCK_STREAM
        
        var result: UnsafeMutablePointer<addrinfo>?
        
        let status = getaddrinfo(hostname, nil, &hints, &result)
        guard status == 0, let info = result else {
            print("[mDNS]   DNS resolution failed for '\(hostname)'")
            return nil
        }
        
        defer { freeaddrinfo(result) }
        
        var current = info
        while true {
            if current.pointee.ai_family == AF_INET,
                let sockaddr = current.pointee.ai_addr {
                 let addr = UnsafeRawPointer(sockaddr).assumingMemoryBound(to: sockaddr_in.self).pointee
                 var ip = addr.sin_addr
                 
                 let ipString = String(cString: inet_ntoa(ip))
                 print("[mDNS]   ✓ Resolved '\(hostname)' to \(ipString) via DNS")
                 return ipString
             }
            
            if current.pointee.ai_next == nil { break }
            current = current.pointee.ai_next!
        }
        
        print("[mDNS]   No IPv4 found for '\(hostname)' in DNS")
        return nil
    }
    
    func netService(_ sender: NetService, didNotResolve errorDict: [String : NSNumber]) {
        print("[mDNS] ✗ Could not resolve service '\(sender.name)'")
        print("[mDNS]   Error dict: \(errorDict)")
        if let errorCode = errorDict[NetService.errorCode] {
            print("[mDNS]   Error code: \(errorCode)")
        }
        cleanup()
    }
    
    private func cleanup() {
        print("[mDNS] Cleaning up resolver for: \(serviceId)")
        Task {
            await discoveryService.removeResolver(forService: serviceId)
            await discoveryService.removeService(forId: serviceId)
        }
    }
    
    private func extractIPAddress(from addressData: Data) -> String? {
        guard addressData.count >= MemoryLayout<sockaddr_storage>.size else {
            print("Data length: \(addressData.count), Family: unknown (data too small)")
            return nil
        }
        
        var address = sockaddr_storage()
        let addressBytes = addressData.withUnsafeBytes { ptr in
            ptr.baseAddress.map { Array(UnsafeRawBufferPointer(start: $0, count: addressData.count)) } ?? []
        }
        
        guard addressBytes.count >= MemoryLayout<sockaddr_storage>.size else {
            return nil
        }
        
        memcpy(&address, addressBytes, min(addressBytes.count, MemoryLayout<sockaddr_storage>.size))
        
        // Check address family
        let family = Int32(address.ss_family)
        
        if family == AF_INET {
            // IPv4
            let sockaddr = UnsafeRawPointer(&address).assumingMemoryBound(to: sockaddr_in.self).pointee
            var ip = sockaddr.sin_addr
            let ipString = String(cString: inet_ntoa(ip))
            print("Data length: \(addressData.count), Family: 2 -> IPv4: \(ipString)")
            return ipString
        } else if family == AF_INET6 {
            // IPv6
            let sockaddr = UnsafeRawPointer(&address).assumingMemoryBound(to: sockaddr_in6.self).pointee
            var ip = sockaddr.sin6_addr
            
            var buffer = [CChar](repeating: 0, count: Int(INET6_ADDRSTRLEN))
            if inet_ntop(AF_INET6, &ip, &buffer, socklen_t(INET6_ADDRSTRLEN)) != nil {
                let ipString = String(cString: buffer)
                print("Data length: \(addressData.count), Family: 28 -> IPv6: \(ipString)")
                return ipString
            }
        } else {
            print("Data length: \(addressData.count), Family: \(family) -> Unknown family \(family) (skipping)")
        }
        
        return nil
    }
}
