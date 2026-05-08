import SwiftUI

// MARK: - MainScreen View

/// Main playback screen shown after a player is locked to a session
struct MainScreen: View {
    
    @StateObject private var viewModel: MainScreenViewModel
    @EnvironmentObject var appState: PlayerAppState
    
    init(sessionCode: String, sessionToken: String, nodeBaseUrl: String) {
        _viewModel = StateObject(wrappedValue: MainScreenViewModel(
            sessionCode: sessionCode,
            sessionToken: sessionToken,
            nodeBaseUrl: nodeBaseUrl
        ))
    }
    
    var body: some View {
        ZStack {
            // Dark background (enforced)
            Color(red: 0.086, green: 0.090, blue: 0.116) // #16171d
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Text("Session Active")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    if let code = viewModel.sessionCode, !code.isEmpty {
                        Text("Code: \(code)")
                            .font(.headline)
                            .foregroundColor(Color(red: 0.753, green: 0.522, blue: 0.992)) // #c084fc
                    }
                }
                .padding(.top, 24)
                
                Spacer()
                
                // Connection status
                HStack(spacing: 8) {
                    Circle()
                        .fill(viewModel.isConnected ? Color(red: 0.753, green: 0.522, blue: 0.992) : Color.gray)
                        .frame(width: 12, height: 12)
                    
                    Text(viewModel.isConnected ? "Connected" : "Connecting...")
                        .font(.caption)
                        .foregroundColor(Color(red: 0.612, green: 0.639, blue: 0.686))
                }
                .padding(.horizontal, 24)
                
                // Playback content area
                if let playback = viewModel.currentPlayback {
                    VStack(spacing: 16) {
                        Text("Now Playing")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        // Placeholder for video playback
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(red: 0.110, green: 0.114, blue: 0.141))
                            .frame(height: 200)
                            .overlay(
                                Image(systemName: "play.circle.fill")
                                    .font(.system(size: 60))
                                    .foregroundColor(Color(red: 0.753, green: 0.522, blue: 0.992))
                            )
                        
                        // Progress bar
                        VStack(spacing: 8) {
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color(red: 0.110, green: 0.114, blue: 0.141))
                                    
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color(red: 0.753, green: 0.522, blue: 0.992))
                                        .frame(width: CGFloat(viewModel.currentPlayback?.progressSeconds ?? 0) / CGFloat(max(viewModel.currentPlayback?.totalSeconds ?? 0, 1)) * geometry.size.width)
                                }
                            }
                            .frame(height: 4)
                            
                            HStack {
                                Text(formatTime(viewModel.currentPlayback?.progressSeconds ?? 0))
                                    .font(.caption2)
                                    .foregroundColor(Color(red: 0.612, green: 0.639, blue: 0.686))
                                
                                Spacer()
                                
                                Text(formatTime(viewModel.currentPlayback?.totalSeconds ?? 0))
                                    .font(.caption2)
                                    .foregroundColor(Color(red: 0.612, green: 0.639, blue: 0.686))
                            }
                        }
                    }
                    .padding(24)
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(Color(red: 0.753, green: 0.522, blue: 0.992))
                        
                        Text("Waiting for Content")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text("Admin will send playback when ready")
                            .font(.caption)
                            .foregroundColor(Color(red: 0.612, green: 0.639, blue: 0.686))
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                }
                
                Spacer()
                
                // Error message
                if let error = viewModel.errorMessage {
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
                
                // Disconnect button
                if !viewModel.isDisconnected {
                    Button(action: { viewModel.disconnectFromSession() }) {
                        Text("Disconnect")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.red.opacity(0.2))
                            .foregroundColor(.red)
                            .cornerRadius(8)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                }
            }
        }
        .onAppear {
            viewModel.connectToSession()
        }
        .onDisappear {
            viewModel.disconnectFromSession()
        }
        .task {
            for await isDisconnected in viewModel.$isDisconnected.values {
                if isDisconnected {
                    appState.transitionToIdleScreen()
                }
            }
        }
    }
    
    private func formatTime(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}

#Preview {
    MainScreen(sessionCode: "1234", sessionToken: "token", nodeBaseUrl: "ws://localhost:8080")
        .environmentObject(PlayerAppState())
}
