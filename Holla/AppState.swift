import Foundation
import Supabase

@Observable
final class AppState {
    enum Phase {
        case loading
        case signedOut
        case onboarding
        case main
    }

    var session: Session?
    var profile: Profile?
    var initializing = true

    var phase: Phase {
        if initializing { return .loading }
        guard session != nil else { return .signedOut }
        guard let profile else { return .loading }
        return profile.onboardingComplete ? .main : .onboarding
    }

    func bootstrap() async {
        for await (_, session) in SupabaseManager.client.auth.authStateChanges {
            self.session = session
            if session != nil {
                self.profile = try? await ProfileRepository.fetchOrCreateProfile()
            } else {
                self.profile = nil
            }
            self.initializing = false
        }
    }

    func refreshProfile() async {
        guard session != nil else { return }
        profile = try? await ProfileRepository.fetchOrCreateProfile()
    }
}
