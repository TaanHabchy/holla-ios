import Foundation
import Supabase

struct Friend: Identifiable {
    let id: UUID
    let displayName: String?
    let email: String?
    let phoneNumber: String?
    let isAvailable: Bool
}

private struct MatchRow: Decodable {
    let userIdA: UUID
    let userIdB: UUID

    enum CodingKeys: String, CodingKey {
        case userIdA = "user_id_a"
        case userIdB = "user_id_b"
    }
}

private struct AvailableFriendRow: Decodable {
    let userId: UUID

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
    }
}

enum FriendsRepository {
    static func fetchFriends(userId: UUID) async throws -> [Friend] {
        let matches: [MatchRow] = try await SupabaseManager.client
            .from("matches")
            .select("user_id_a, user_id_b")
            .eq("is_mutual", value: true)
            .or("user_id_a.eq.\(userId),user_id_b.eq.\(userId)")
            .execute()
            .value

        let friendIds = matches.map { $0.userIdA == userId ? $0.userIdB : $0.userIdA }
        guard !friendIds.isEmpty else { return [] }

        async let profiles: [Profile] = SupabaseManager.client
            .from("profiles")
            .select()
            .in("id", values: friendIds.map { $0.uuidString })
            .execute()
            .value

        async let available: [AvailableFriendRow] = SupabaseManager.client
            .from("available_friends")
            .select("user_id")
            .in("user_id", values: friendIds.map { $0.uuidString })
            .execute()
            .value

        let (profileRows, availableRows) = try await (profiles, available)
        let availableIds = Set(availableRows.map { $0.userId })

        return profileRows
            .map { profile in
                Friend(
                    id: profile.id,
                    displayName: profile.displayName,
                    email: profile.email,
                    phoneNumber: profile.phoneNumber,
                    isAvailable: availableIds.contains(profile.id)
                )
            }
            .sorted { $0.isAvailable && !$1.isAvailable }
    }
}
