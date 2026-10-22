import Foundation

enum FriendsRepository {
    /// Mutual friends, available ones first.
    static func fetchFriends() async throws -> [Friend] {
        try await APIClient.request(.get, "/friends")
    }
}
