import SwiftUI

/// Main playback screen shown after a player is locked to a session
struct MainScreen: View {
    
    @StateObject var appState: PlayerAppState
    
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
                    
                    if let sessionCode = appState.lockedSessionCode {
                        Text("Code: \(sessionCode)")
                            .font(.headline)
                            .foregroundColor(Color(red: 0.753, green: 0.522, blue: 0.992)) // #c084fc
                    }
                }
                .padding(.top, 24)
                
                Spacer()
                
                // Placeholder content - Phase 2.7 will implement video playback
                VStack(spacing: 16) {
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(Color(red: 0.753, green: 0.522, blue: 0.992))
                    
                    Text("Waiting for Content")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text("Playback screen coming in Phase 2.7")
                        .font(.caption)
                        .foregroundColor(Color(red: 0.612, green: 0.639, blue: 0.686))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                
                Spacer()
            }
        }
    }
}

#Preview {
    MainScreen(appState: PlayerAppState())
}
