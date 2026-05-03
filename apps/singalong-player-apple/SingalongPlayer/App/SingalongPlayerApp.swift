import SwiftUI

@main
struct SingalongPlayerApp: App {
    
    @StateObject var appState = PlayerAppState()
    
    var body: some Scene {
        WindowGroup {
            IdleScreen(appState: appState)
                .preferredColorScheme(.dark)
        }
    }
}
