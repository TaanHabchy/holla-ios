import Foundation

enum ProfileRepository {
    /// The backend creates the profile on first call and backfills the
    /// display name from Apple's metadata once it arrives.
    static func fetchOrCreateProfile() async throws -> Profile {
        try await APIClient.request(.get, "/me/profile")
    }

    private struct UpdatePhoneNumberBody: Encodable {
        let phoneNumber: String
    }

    static func updatePhoneNumber(e164: String) async throws {
        let _: APIClient.Empty = try await APIClient.request(
            .patch,
            "/me/profile",
            body: UpdatePhoneNumberBody(phoneNumber: e164)
        )
    }
}
