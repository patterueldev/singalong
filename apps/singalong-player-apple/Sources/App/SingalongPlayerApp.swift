import SwiftUI

@main
struct SingalongPlayerApp: App {
    
    @StateObject var appState: PlayerAppState
    @StateObject private var idleScreenViewModel: IdleScreenViewModel
    
    init() {
        let container = DependencyContainer.shared
        let appState = PlayerAppState()
        let idleVM = IdleScreenViewModel(
            discoveryCoordinator: container.discoveryCoordinator,
            dependencyContainer: container,
            appState: appState
        )
        _appState = StateObject(wrappedValue: appState)
        _idleScreenViewModel = StateObject(wrappedValue: idleVM)
    }
    
    var body: some Scene {
        WindowGroup {
            Group {
                if let sessionCode = appState.lockedSessionCode,
                   let sessionToken = appState.lockedSessionToken,
                   let nodeBaseUrl = appState.lockedNodeBaseUrl {
                    // Player is locked to a session — show main screen
                    // .id(sessionCode) forces SwiftUI to recreate MainScreen (and its @StateObject VM)
                    // if the player is assigned to a different session
                    MainScreen(
                        sessionCode: sessionCode,
                        sessionToken: sessionToken,
                        nodeBaseUrl: nodeBaseUrl
                    )
                    .id(sessionCode)
                    .environmentObject(appState)
                } else {
                    // Player is idle — show discovery screen
                    IdleScreen(viewModel: idleScreenViewModel)
                        .environmentObject(appState)
                }
            }
            .preferredColorScheme(.dark)
            .onAppear {
                print("[SingalongPlayerApp] App appeared")
            }
        }
    }
}
