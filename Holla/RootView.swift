import SwiftUI

enum MainRoute: Hashable {
    case settings
}

struct RootView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        switch appState.phase {
        case .loading:
            ProgressView()
        case .signedOut:
            SignInScreen()
        case .onboarding:
            OnboardingContainerView()
        case .main:
            if let userId = appState.session?.user.id {
                NavigationStack {
                    FriendListScreen(userId: userId)
                        .navigationDestination(for: MainRoute.self) { route in
                            switch route {
                            case .settings:
                                SettingsScreen()
                            }
                        }
                }
            }
        }
    }
}
