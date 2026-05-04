import SwiftUI

@main
struct SingalongPlayerApp: App {
    
    @StateObject var appState = PlayerAppState()
    
    var body: some Scene {
        WindowGroup {
            IdleScreen(appState: appState)
                .preferredColorScheme(.dark)
                .onAppear {
                    print("[SingalongPlayerApp] App appeared")
                }
        }
    }
}
