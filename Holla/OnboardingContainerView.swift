import SwiftUI

enum OnboardingStep {
    case phoneNumber
    case contactsPermission
    case syncing
}

/// Deliberately not a NavigationStack: each RN onboarding screen calls
/// `navigation.replace(...)`, i.e. removes back-navigation at every step.
/// A plain state switch matches that with no back-swipe gesture to suppress.
struct OnboardingContainerView: View {
    @State private var step: OnboardingStep = .phoneNumber

    var body: some View {
        switch step {
        case .phoneNumber:
            PhoneNumberScreen(onContinue: { step = .contactsPermission })
        case .contactsPermission:
            ContactsPermissionScreen(onContinue: { step = .syncing })
        case .syncing:
            SyncingScreen()
        }
    }
}
