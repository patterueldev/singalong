import SwiftUI

@main
struct SingalongPlayerApp: App {
    
    @StateObject var appState = PlayerAppState()
    
    var body: some Scene {
        WindowGroup {
            Group {
                if let _ = appState.lockedSessionCode {
                    // Player is locked to a session - show main screen
                    MainScreen(appState: appState)
                } else {
                    // Player is idle - show discovery screen
                    IdleScreen(appState: appState)
                }
            }
            .preferredColorScheme(.dark)
            .onAppear {
                print("[SingalongPlayerApp] App appeared")
            }
        }
    }
}
