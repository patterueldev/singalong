import SwiftUI

@main
struct SingalongPlayerApp: App {
    
    @StateObject var appState = PlayerAppState()
    @StateObject private var idleScreenViewModel: IdleScreenViewModel
    @StateObject private var mainScreenViewModel: MainScreenViewModel
    
    init() {
        let container = DependencyContainer.shared
        let appState = PlayerAppState()
        let idleVM = IdleScreenViewModel(
            discoveryCoordinator: container.discoveryCoordinator,
            dependencyContainer: container,
            appState: appState
        )
        let mainVM = MainScreenViewModel(
            sessionCode: "",
            sessionToken: ""
        )
        _appState = StateObject(wrappedValue: appState)
        _idleScreenViewModel = StateObject(wrappedValue: idleVM)
        _mainScreenViewModel = StateObject(wrappedValue: mainVM)
    }
    
    var body: some Scene {
        WindowGroup {
            Group {
                if let _ = appState.lockedSessionCode {
                    // Player is locked to a session - show main screen
                    MainScreen(viewModel: mainScreenViewModel)
                        .environmentObject(appState)
                } else {
                    // Player is idle - show discovery screen
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
