import SwiftUI

struct FriendListScreen: View {
    @State private var viewModel = FriendListViewModel()
    @Environment(\.openURL) private var openURL
    @State private var showAddFriend = false

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Theme.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: Theme.Spacing.lg) {
                    statusHero

                    if viewModel.loading && viewModel.friends.isEmpty {
                        loadingState
                    } else if viewModel.friends.isEmpty {
                        emptyState
                    } else {
                        friendsSection
                    }
                }
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.top, Theme.Spacing.md)
                .padding(.bottom, 100)
            }

            addFriendButton
                .padding(.trailing, Theme.Spacing.lg)
                .padding(.bottom, Theme.Spacing.lg)
        }
        .navigationTitle("Holla")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink(value: MainRoute.settings) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Theme.textSecondary)
                        .frame(width: 36, height: 36)
                        .background(Theme.surface, in: Circle())
                        .elevation()
                }
            }
        }
        .refreshable { await viewModel.refresh() }
        .task { await viewModel.refresh() }
        .sheet(isPresented: $showAddFriend) {
            addFriendSheet
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.isAvailable)
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: viewModel.friends.map(\.id))
    }

    // MARK: - Status hero

    @ViewBuilder
    private var statusHero: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack(alignment: .top) {
                Text(viewModel.isAvailable ? "You're open\nto call" : "You're not\navailable")
                    .font(Theme.display())
                    .foregroundStyle(viewModel.isAvailable ? .white : Theme.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer()

                statusSwitch
            }

            Text(viewModel.isAvailable
                 ? "Friends can see you're free right now."
                 : "Flip the switch when you're free to talk.")
                .font(Theme.body(14))
                .foregroundStyle(viewModel.isAvailable ? .white.opacity(0.85) : Theme.textTertiary)
        }
        .padding(Theme.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(viewModel.isAvailable ? Theme.accent : Theme.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.large, style: .continuous))
        .shadow(color: viewModel.isAvailable ? Theme.accent.opacity(0.3) : .black.opacity(0.06),
                radius: viewModel.isAvailable ? 16 : 4,
                x: 0, y: viewModel.isAvailable ? 8 : 2)
        .contentShape(RoundedRectangle(cornerRadius: Theme.Radius.large, style: .continuous))
        .onTapGesture { toggleAvailability() }
        .opacity(viewModel.statusLoading ? 0.6 : 1)
        .disabled(viewModel.statusLoading)
    }

    private var statusSwitch: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(viewModel.isAvailable ? .white.opacity(0.35) : Theme.hairline)
            .frame(width: 52, height: 32)
            .overlay(alignment: viewModel.isAvailable ? .trailing : .leading) {
                Circle()
                    .fill(viewModel.isAvailable ? .white : Theme.textTertiary)
                    .frame(width: 28, height: 28)
                    .shadow(color: .black.opacity(0.15), radius: 2, x: 0, y: 1)
                    .padding(2)
            }
    }

    private func toggleAvailability() {
        guard !viewModel.statusLoading else { return }
        let next = !viewModel.isAvailable
        Task { await viewModel.setAvailable(next) }
    }

    // MARK: - Friends list

    private var friendsSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack(alignment: .firstTextBaseline, spacing: Theme.Spacing.xs) {
                Text("FRIENDS")
                    .font(Theme.overline())
                    .tracking(0.6)
                Text("\(viewModel.friends.count)")
                    .font(Theme.overline())
            }
            .foregroundStyle(Theme.textTertiary)
            .padding(.horizontal, Theme.Spacing.xxs)

            VStack(spacing: Theme.Spacing.xs) {
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

    @ViewBuilder
    private func friendRow(_ friend: Friend) -> some View {
        HStack(spacing: Theme.Spacing.sm) {
            avatar(for: friend)

            VStack(alignment: .leading, spacing: 2) {
                Text(friend.displayName ?? friend.email ?? "Friend")
                    .font(Theme.title())
                    .foregroundStyle(Theme.textPrimary)
                Text(friend.isAvailable ? "Open to call" : "Not available")
                    .font(Theme.caption())
                    .foregroundStyle(friend.isAvailable ? Theme.accent : Theme.textTertiary)
            }

            Spacer(minLength: Theme.Spacing.xs)

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(Theme.divider)
        }
        .padding(Theme.Spacing.sm)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.medium, style: .continuous))
        .elevation()
    }

    private func avatar(for friend: Friend) -> some View {
        ZStack(alignment: .bottomTrailing) {
            Circle()
                .fill(Theme.avatarFill)
                .frame(width: 56, height: 56)
                .overlay(
                    Circle().stroke(friend.isAvailable ? Theme.accent : Theme.hairline, lineWidth: friend.isAvailable ? 3 : 2)
                        .padding(friend.isAvailable ? -3 : 0)
                )
                .overlay(
                    Text(initial(for: friend))
                        .font(Theme.title(18))
                        .foregroundStyle(friend.isAvailable ? Theme.textPrimary : Theme.textTertiary)
                )

            ZStack {
                Circle()
                    .fill(friend.isAvailable ? Theme.accent : Theme.divider)
                    .frame(width: 20, height: 20)
                Image(systemName: friend.isAvailable ? "phone.fill" : "moon.fill")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(friend.isAvailable ? .white : Theme.textPrimary)
            }
            .overlay(Circle().stroke(Theme.surface, lineWidth: 2))
            .offset(x: 1, y: 1)
        }
        // status changes are frequent and meant to feel alive, not abrupt
        .animation(.spring(response: 0.35, dampingFraction: 0.75), value: friend.isAvailable)
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

    // MARK: - Empty / loading states

    private var emptyState: some View {
        VStack(spacing: Theme.Spacing.md) {
            Circle()
                .fill(Theme.avatarFill)
                .frame(width: 88, height: 88)
                .overlay(
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(Theme.divider)
                )

            VStack(spacing: Theme.Spacing.xxs) {
                Text("No friends yet")
                    .font(Theme.title(20))
                    .foregroundStyle(Theme.textPrimary)
                Text("Add a friend by email to see when they're free to talk.")
                    .font(Theme.body(14))
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center)
            }

            Button {
                showAddFriend = true
            } label: {
                Text("Add a friend")
                    .font(Theme.title(15))
                    .foregroundStyle(.white)
                    .padding(.horizontal, Theme.Spacing.lg)
                    .padding(.vertical, Theme.Spacing.sm)
                    .background(Theme.accent, in: Capsule())
                    .shadow(color: Theme.accent.opacity(0.3), radius: 10, x: 0, y: 4)
            }
        }
        .padding(.vertical, Theme.Spacing.xl)
        .padding(.horizontal, Theme.Spacing.lg)
        .frame(maxWidth: .infinity)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.large, style: .continuous))
        .elevation()
    }

    private var loadingState: some View {
        VStack(spacing: Theme.Spacing.xs) {
            ForEach(0..<3, id: \.self) { _ in
                HStack(spacing: Theme.Spacing.sm) {
                    Circle().fill(Theme.avatarFill).frame(width: 56, height: 56)
                    VStack(alignment: .leading, spacing: 8) {
                        RoundedRectangle(cornerRadius: 7).fill(Theme.avatarFill).frame(width: 120, height: 14)
                        RoundedRectangle(cornerRadius: 6).fill(Theme.avatarFill).frame(width: 80, height: 11)
                    }
                    Spacer()
                }
                .padding(Theme.Spacing.sm)
                .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.medium, style: .continuous))
                .elevation()
            }
        }
        .redacted(reason: .placeholder)
    }

    // MARK: - Add friend

    private var addFriendButton: some View {
        Button {
            showAddFriend = true
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background(Theme.accent, in: Circle())
                .shadow(color: Theme.accent.opacity(0.35), radius: 14, x: 0, y: 6)
        }
    }

    private var addFriendSheet: some View {
        NavigationStack {
            VStack(spacing: Theme.Spacing.md) {
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    TextField("Friend's email", text: $viewModel.addFriendEmail)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .submitLabel(.done)
                        .padding(Theme.Spacing.sm)
                        .background(Theme.avatarFill, in: RoundedRectangle(cornerRadius: Theme.Radius.small, style: .continuous))
                        .onSubmit { Task { await viewModel.addFriend() } }

                    if let addFriendError = viewModel.addFriendError {
                        Text(addFriendError)
                            .font(Theme.caption(12))
                            .foregroundStyle(.red)
                    }
                }

                Button {
                    Task {
                        await viewModel.addFriend()
                        if viewModel.addFriendError == nil { showAddFriend = false }
                    }
                } label: {
                    Text(viewModel.addingFriend ? "Adding…" : "Add friend")
                        .font(Theme.title(15))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Theme.Spacing.sm)
                        .background(Theme.accent, in: Capsule())
                }
                .disabled(viewModel.addingFriend || viewModel.addFriendEmail.isEmpty)

                Spacer()
            }
            .padding(Theme.Spacing.md)
            .padding(.top, Theme.Spacing.md)
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("Add a friend")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showAddFriend = false }
                }
            }
        }
        .presentationDetents([.height(220)])
    }
}
