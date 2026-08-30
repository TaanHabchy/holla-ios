import SwiftUI

struct FriendListScreen: View {
    @State private var viewModel: FriendListViewModel
    @Environment(\.openURL) private var openURL

    init(userId: UUID) {
        _viewModel = State(initialValue: FriendListViewModel(userId: userId))
    }

    var body: some View {
        List {
            Section {
                Toggle(isOn: Binding(
                    get: { viewModel.isAvailable },
                    set: { newValue in Task { await viewModel.setAvailable(newValue) } }
                )) {
                    Text(viewModel.isAvailable ? "Available" : "Not available")
                }
                .disabled(viewModel.statusLoading)
            }

            Section {
                HStack {
                    TextField("Add a friend by email", text: $viewModel.addFriendEmail)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .submitLabel(.done)
                        .onSubmit { Task { await viewModel.addFriend() } }

                    Button("Add") {
                        Task { await viewModel.addFriend() }
                    }
                    .disabled(viewModel.addingFriend)
                }
                if let addFriendError = viewModel.addFriendError {
                    Text(addFriendError)
                        .foregroundStyle(.red)
                        .font(.footnote)
                }
            }

            Section {
                if viewModel.friends.isEmpty && !viewModel.loading {
                    Text("No friends yet — add one by email above.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(viewModel.friends) { friend in
                        Button {
                            callFriend(friend)
                        } label: {
                            friendRow(friend)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .navigationTitle("Holla")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink(value: MainRoute.settings) {
                    Image(systemName: "gearshape")
                }
            }
        }
        .refreshable { await viewModel.refresh() }
        .task { await viewModel.refresh() }
    }

    @ViewBuilder
    private func friendRow(_ friend: Friend) -> some View {
        HStack {
            ZStack(alignment: .bottomTrailing) {
                Circle()
                    .fill(Color(.secondarySystemBackground))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Text(initial(for: friend))
                            .font(.headline)
                            .foregroundStyle(.tint)
                    )
                Circle()
                    .fill(friend.isAvailable ? .green : Color(.systemGray3))
                    .frame(width: 13, height: 13)
                    .overlay(Circle().stroke(Color(.systemBackground), lineWidth: 2))
            }
            Text(friend.displayName ?? friend.email ?? "Friend")
                .foregroundStyle(.primary)
        }
    }

    private func initial(for friend: Friend) -> String {
        let source = friend.displayName ?? friend.email ?? "?"
        return String(source.prefix(1)).uppercased()
    }

    private func callFriend(_ friend: Friend) {
        guard let phoneNumber = friend.phoneNumber,
              let url = URL(string: "tel://\(phoneNumber)") else { return }
        openURL(url)
    }
}
