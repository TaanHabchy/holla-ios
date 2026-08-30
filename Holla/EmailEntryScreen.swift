import SwiftUI
import Supabase

struct EmailEntryScreen: View {
    @State private var email = ""
    @State private var loading = false
    @State private var errorMessage: String?
    @FocusState private var emailFieldFocused: Bool

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Text("What's your email?")
                .font(.title2.bold())

            TextField("you@example.com", text: $email)
                .textFieldStyle(.roundedBorder)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.done)
                .focused($emailFieldFocused)
                .onSubmit { Task { await submit() } }

            if let errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
                    .font(.footnote)
            }

            Button {
                Task { await submit() }
            } label: {
                if loading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                } else {
                    Text("Continue")
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(loading)

            Spacer()
            Spacer()
        }
        .padding(.horizontal, 32)
        .onAppear { emailFieldFocused = true }
    }

    private func submit() async {
        guard email.contains("@") else {
            errorMessage = "Enter a valid email address."
            return
        }
        errorMessage = nil
        loading = true
        defer { loading = false }

        do {
            let response = try await APIClient.emailLogin(email: email.trimmingCharacters(in: .whitespaces))
            guard let type = EmailOTPType(rawValue: response.verificationType) else {
                errorMessage = "Unexpected response from server."
                return
            }
            try await SupabaseManager.client.auth.verifyOTP(tokenHash: response.tokenHash, type: type)
            // On success, AppState's auth-state-changes loop picks up the new
            // session and RootView reactively switches away from this screen.
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
