import SwiftUI

struct SyncingScreen: View {
    @Environment(AppState.self) private var appState
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 20) {
            if let errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                Button("Retry") {
                    Task { await sync() }
                }
                .buttonStyle(.borderedProminent)
            } else {
                ProgressView("Finding your friends…")
            }
        }
        .task { await sync() }
    }

    private func sync() async {
        errorMessage = nil
        do {
            let phoneNumbers = try ContactsService.readContactPhoneNumbers()
            try await APIClient.syncContacts(phoneNumbers: phoneNumbers)
            await appState.refreshProfile()
            // Backend flips profiles.onboarding_complete = true on success;
            // AppState.phase reactively switches to .main once refreshed.
        } catch {
            errorMessage = "Something went wrong syncing your contacts."
        }
    }
}
