import Foundation

@Observable
final class FriendListViewModel {
    var friends: [Friend] = []
    var loading = false
    var isAvailable = false
    var statusLoading = false
    var addFriendEmail = ""
    var addingFriend = false
    var addFriendError: String?

    private let userId: UUID

    init(userId: UUID) {
        self.userId = userId
    }

    func refresh() async {
        loading = true
        defer { loading = false }
        friends = (try? await FriendsRepository.fetchFriends(userId: userId)) ?? []
        isAvailable = (try? await AvailabilityRepository.fetchMyStatus(userId: userId)) ?? false
    }

    func setAvailable(_ available: Bool) async {
        statusLoading = true
        defer { statusLoading = false }
        do {
            try await AvailabilityRepository.setAvailable(userId: userId, available: available)
            isAvailable = available
        } catch {
            // Revert optimistic toggle on failure by leaving isAvailable as-is;
            // the Toggle binding will resync on next refresh().
        }
    }

    func addFriend() async {
        guard addFriendEmail.contains("@") else {
            addFriendError = "Enter a valid email address."
            return
        }
        addFriendError = nil
        addingFriend = true
        defer { addingFriend = false }

        do {
            try await APIClient.addFriend(email: addFriendEmail.trimmingCharacters(in: .whitespaces))
            addFriendEmail = ""
            await refresh()
        } catch {
            addFriendError = error.localizedDescription
        }
    }
}
