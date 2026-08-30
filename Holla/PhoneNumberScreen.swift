import SwiftUI

struct PhoneNumberScreen: View {
    let onContinue: () -> Void

    @Environment(AppState.self) private var appState
    @State private var phoneNumber = ""
    @State private var saving = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Text("What's your phone number?")
                .font(.title2.bold())
                .multilineTextAlignment(.center)

            TextField("+1 555 123 4567", text: $phoneNumber)
                .textFieldStyle(.roundedBorder)
                .keyboardType(.phonePad)

            if let errorMessage {
                Text(errorMessage).foregroundStyle(.red).font(.footnote)
            }

            Button {
                Task { await save() }
            } label: {
                if saving {
                    ProgressView().frame(maxWidth: .infinity)
                } else {
                    Text("Continue").frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(saving)

            Spacer()
            Spacer()
        }
        .padding(.horizontal, 32)
    }

    private func save() async {
        guard let userId = appState.session?.user.id else { return }
        guard let e164 = PhoneNumberNormalizer.normalizeToE164(phoneNumber) else {
            errorMessage = "Enter a valid phone number, e.g. +1 555 123 4567."
            return
        }
        errorMessage = nil
        saving = true
        defer { saving = false }

        do {
            try await ProfileRepository.updatePhoneNumber(userId: userId, e164: e164)
            await appState.refreshProfile()
            onContinue()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
