import SwiftUI
import UIKit
import Contacts

struct ContactsPermissionScreen: View {
    let onContinue: () -> Void

    @State private var denied = false
    @State private var requesting = false

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "person.2.circle")
                .font(.system(size: 56))
                .foregroundStyle(.tint)

            Text("Find friends from your contacts")
                .font(.title2.bold())
                .multilineTextAlignment(.center)

            Text("Holla at your friends.")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            if denied {
                Text("Contacts access was denied. Open Settings to allow it.")
                    .foregroundStyle(.red)
                    .font(.footnote)
                    .multilineTextAlignment(.center)

                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                .buttonStyle(.bordered)
            } else {
                Button {
                    Task { await requestAccess() }
                } label: {
                    if requesting {
                        ProgressView().frame(maxWidth: .infinity)
                    } else {
                        Text("Continue").frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(requesting)
            }

            Spacer()
            Spacer()
        }
        .padding(.horizontal, 32)
    }

    private func requestAccess() async {
        requesting = true
        defer { requesting = false }

        let granted = (try? await ContactsService.requestPermission()) ?? false
        if granted {
            onContinue()
        } else {
            denied = true
        }
    }
}
