import Foundation
import Supabase

private struct StatusRow: Decodable {
    let isAvailable: Bool
    let expiresAt: Date?

    enum CodingKeys: String, CodingKey {
        case isAvailable = "is_available"
        case expiresAt = "expires_at"
    }
}

enum AvailabilityRepository {
    static let availableDuration: TimeInterval = 60 * 60 // 1 hour

    static func fetchMyStatus(userId: UUID) async throws -> Bool {
        let row: StatusRow? = try await SupabaseManager.client
            .from("availability_status")
            .select("is_available, expires_at")
            .eq("user_id", value: userId)
            .maybeSingle()
            .execute()
            .value

        guard let row, row.isAvailable, let expiresAt = row.expiresAt else { return false }
        return expiresAt > Date()
    }

    static func setAvailable(userId: UUID, available: Bool) async throws {
        struct Upsert: Encodable {
            let userId: String
            let isAvailable: Bool
            let expiresAt: String?
            let updatedAt: String

            enum CodingKeys: String, CodingKey {
                case userId = "user_id"
                case isAvailable = "is_available"
                case expiresAt = "expires_at"
                case updatedAt = "updated_at"
            }
        }

        let formatter = ISO8601DateFormatter()
        let expiresAt = available ? formatter.string(from: Date().addingTimeInterval(availableDuration)) : nil

        try await SupabaseManager.client
            .from("availability_status")
            .upsert(Upsert(
                userId: userId.uuidString,
                isAvailable: available,
                expiresAt: expiresAt,
                updatedAt: formatter.string(from: Date())
            ))
            .execute()
    }
}
