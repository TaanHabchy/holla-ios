import AuthenticationServices
import CryptoKit
import SwiftUI
import Supabase

struct SignInScreen: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var rawNonce = ""
    @State private var loading = false
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            VStack(spacing: Theme.Spacing.lg) {
                Spacer()

                VStack(spacing: Theme.Spacing.xs) {
                    Text("Holla")
                        .font(Theme.display(40))
                        .foregroundStyle(Theme.textPrimary)
                    Text("See who's free to talk.")
                        .font(Theme.body())
                        .foregroundStyle(Theme.textSecondary)
                }

                Spacer()

                if let errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                        .font(.footnote)
                        .multilineTextAlignment(.center)
                }

                SignInWithAppleButton(.signIn) { request in
                    rawNonce = Self.randomNonce()
                    request.requestedScopes = [.fullName, .email]
                    request.nonce = Self.sha256(rawNonce)
                } onCompletion: { result in
                    Task { await handle(result) }
                }
                .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
                .frame(height: 50)
                .disabled(loading)
                .overlay {
                    if loading { ProgressView() }
                }
            }
            .padding(.horizontal, Theme.Spacing.xl)
            .padding(.bottom, Theme.Spacing.xl)
        }
    }

    private func handle(_ result: Result<ASAuthorization, Error>) async {
        errorMessage = nil

        let authorization: ASAuthorization
        switch result {
        case .success(let value):
            authorization = value
        case .failure(let error):
            if (error as? ASAuthorizationError)?.code != .canceled {
                errorMessage = error.localizedDescription
            }
            return
        }

        guard
            let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
            let tokenData = credential.identityToken,
            let idToken = String(data: tokenData, encoding: .utf8)
        else {
            errorMessage = "Unexpected response from Apple."
            return
        }

        loading = true
        defer { loading = false }

        do {
            try await SupabaseManager.client.auth.signInWithIdToken(
                credentials: .init(provider: .apple, idToken: idToken, nonce: rawNonce)
            )

            // Apple only hands over the user's name on the very first
            // authorization, so stash it in user metadata for the profile.
            if let fullName = credential.fullName {
                let name = PersonNameComponentsFormatter().string(from: fullName)
                if !name.isEmpty {
                    try? await SupabaseManager.client.auth.update(
                        user: UserAttributes(data: ["full_name": .string(name)])
                    )
                }
            }
            // On success, AppState's auth-state-changes loop picks up the new
            // session and RootView reactively switches away from this screen.
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private static func randomNonce(length: Int = 32) -> String {
        var bytes = [UInt8](repeating: 0, count: length)
        _ = SecRandomCopyBytes(kSecRandomDefault, length, &bytes)
        return bytes.map { String(format: "%02x", $0) }.joined()
    }

    private static func sha256(_ input: String) -> String {
        SHA256.hash(data: Data(input.utf8))
            .map { String(format: "%02x", $0) }
            .joined()
    }
}
