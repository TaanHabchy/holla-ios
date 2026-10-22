import SwiftUI

struct SettingsScreen: View {
    @Environment(AppState.self) private var appState
    @State private var phoneNumber = ""
    @State private var saving = false
    @State private var errorMessage: String?
    @State private var saved = false

    private var dirty: Bool {
        phoneNumber != (appState.profile?.phoneNumber ?? "")
    }

    var body: some View {
        Form {
            Section {
                LabeledContent("Name", value: appState.profile?.displayName ?? "—")
                LabeledContent("Email", value: appState.profile?.email ?? "—")
            }

            Section {
                TextField("+1 555 123 4567", text: $phoneNumber)
                    .keyboardType(.phonePad)
                if let errorMessage {
                    Text(errorMessage).foregroundStyle(.red).font(.footnote)
                }
                if saved {
                    Text("Saved.").foregroundStyle(.secondary).font(.footnote)
                }
                Button {
                    Task { await save() }
                } label: {
                    if saving {
                        ProgressView()
                    } else {
                        Text("Save")
                    }
                }
                .disabled(!dirty || saving)
            } header: {
                Text("Phone number")
            }

            Section {
                Button("Sign Out", role: .destructive) {
                    Task { try? await SupabaseManager.client.auth.signOut() }
                }
            }
        }
        .navigationTitle("Settings")
        .onAppear { phoneNumber = appState.profile?.phoneNumber ?? "" }
    }

    private func save() async {
        guard let e164 = PhoneNumberNormalizer.normalizeToE164(phoneNumber) else {
            errorMessage = "Enter a valid phone number, e.g. +1 555 123 4567."
            saved = false
            return
        }
        errorMessage = nil
        saved = false
        saving = true
        defer { saving = false }

        do {
            try await ProfileRepository.updatePhoneNumber(e164: e164)
            await appState.refreshProfile()
            saved = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
