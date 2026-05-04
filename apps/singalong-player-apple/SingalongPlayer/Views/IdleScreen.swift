import SwiftUI

/// The main Idle Screen showing discovered nodes and connection status
struct IdleScreen: View {
    
    @StateObject var appState: PlayerAppState
    @State private var showManualSetup = false
    @State private var manualURL = ""
    @State private var manualAPIKey = ""
    
    var body: some View {
        ZStack {
            // Dark background (enforced)
            Color(red: 0.086, green: 0.090, blue: 0.116) // #16171d
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Text("Singalong Player")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text(appState.isDiscovering ? "Discovering nodes..." : "Ready")
                        .font(.subheadline)
                        .foregroundColor(Color(red: 0.612, green: 0.639, blue: 0.686)) // #9ca3af
                }
                .padding(.top, 24)
                
                // Status indicator
                HStack(spacing: 8) {
                    Circle()
                        .fill(appState.isDiscovering ? Color(red: 0.753, green: 0.522, blue: 0.992) : Color.gray) // #c084fc
                        .frame(width: 12, height: 12)
                    
                    Text(appState.discoveredNodes.isEmpty ? "No nodes found" : "\(appState.discoveredNodes.count) node(s) found")
                        .font(.caption)
                        .foregroundColor(Color(red: 0.612, green: 0.639, blue: 0.686))
                }
                .padding(.horizontal, 24)
                
                // Nodes list
                if appState.discoveredNodes.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "network")
                            .font(.system(size: 48))
                            .foregroundColor(Color(red: 0.612, green: 0.639, blue: 0.686))
                        
                        Text("Waiting for Nodes")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text("Make sure a Singalong Node is running on your network")
                            .font(.caption)
                            .foregroundColor(Color(red: 0.612, green: 0.639, blue: 0.686))
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 200)
                    .padding(24)
                } else {
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(appState.discoveredNodes) { node in
                                NodeCard(
                                    node: node,
                                    status: appState.activeConnections[node.id] ?? .connecting
                                )
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                }
                
                Spacer()
                
                // Error message
                if let error = appState.errorMessage {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundColor(.red)
                        
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.white)
                            .lineLimit(2)
                        
                        Spacer()
                    }
                    .padding(12)
                    .background(Color.red.opacity(0.2))
                    .cornerRadius(8)
                    .padding(.horizontal, 24)
                }
                
                // Control buttons - Manual Setup ONLY
                VStack {
                    #if os(iOS) || os(macOS) || os(tvOS)
                    Button(action: { showManualSetup = true }) {
                        Text("Manual Setup")
                            .font(.caption)
                            .foregroundColor(Color(red: 0.753, green: 0.522, blue: 0.992))
                    }
                    #endif
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
        .onAppear {
            appState.startDiscovery()
        }
        .sheet(isPresented: $showManualSetup) {
            ManualSetupSheet(
                isPresented: $showManualSetup,
                url: $manualURL,
                apiKey: $manualAPIKey
            )
        }
    }
}

// MARK: - Node Card Component

struct NodeCard: View {
    
    let node: DiscoveredNode
    let status: NodeConnectionStatus
    @Environment(\.scenePhase) var scenePhase
    
    var statusIcon: String {
        switch status {
        case .connecting:
            return "hourglass"
        case .waiting:
            return "checkmark.circle"
        case .reconnecting:
            return "arrow.clockwise"
        case .locked:
            return "lock.fill"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(node.name)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    HStack(spacing: 8) {
                        Image(systemName: "network")
                            .font(.caption)
                        Text(node.host)
                            .font(.caption2)
                            .lineLimit(1)
                    }
                    .foregroundColor(Color(red: 0.612, green: 0.639, blue: 0.686)) // #9ca3af
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(status.displayText)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(status.statusColor)
                    
                    HStack(spacing: 4) {
                        Image(systemName: statusIcon)
                            .font(.caption2)
                        
                        switch status {
                        case .connecting:
                            Text("Establishing...")
                                .font(.caption2)
                        case .waiting:
                            Text("Ready")
                                .font(.caption2)
                        case .reconnecting(let attempt):
                            Text("Attempt \(attempt)")
                                .font(.caption2)
                        case .locked:
                            Text("Active")
                                .font(.caption2)
                        }
                    }
                    .foregroundColor(status.statusColor)
                }
            }
        }
        .padding(16)
        .background(Color(red: 0.110, green: 0.114, blue: 0.141)) // Slightly lighter bg
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    status == .locked ? Color(red: 0.753, green: 0.522, blue: 0.992) : Color.clear,
                    lineWidth: 2
                )
        )
        .onAppear {
            // Auto-connect when node is discovered
            if case .connecting = status {
                let appState = PlayerAppState.shared
                appState.connectToNode(node)
            }
        }
    }
}

// MARK: - Manual Setup Sheet

struct ManualSetupSheet: View {
    
    @Binding var isPresented: Bool
    @Binding var url: String
    @Binding var apiKey: String
    
    var body: some View {
        ZStack {
            Color(red: 0.086, green: 0.090, blue: 0.116) // #16171d
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                HStack {
                    Text("Manual Setup")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button(action: { isPresented = false }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundColor(Color(red: 0.612, green: 0.639, blue: 0.686))
                    }
                }
                .padding(24)
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Node URL")
                        .font(.caption)
                        .foregroundColor(Color(red: 0.612, green: 0.639, blue: 0.686))
                    
                    TextField("ws://192.168.1.100:5002", text: $url)
                        .padding(12)
                        .background(Color(red: 0.110, green: 0.114, blue: 0.141))
                        .cornerRadius(8)
                        .foregroundColor(.white)
                        #if os(iOS)
                        .textInputAutocapitalization(.never)
                        #endif
                }
                .padding(.horizontal, 24)
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("API Key (optional)")
                        .font(.caption)
                        .foregroundColor(Color(red: 0.612, green: 0.639, blue: 0.686))
                    
                    SecureField("API Key", text: $apiKey)
                        .padding(12)
                        .background(Color(red: 0.110, green: 0.114, blue: 0.141))
                        .cornerRadius(8)
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 24)
                
                Spacer()
                
                Button(action: { isPresented = false }) {
                    Text("Connect")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color(red: 0.753, green: 0.522, blue: 0.992)) // #c084fc
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
    }
}

#Preview {
    IdleScreen(appState: PlayerAppState())
}
