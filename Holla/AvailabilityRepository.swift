import Foundation

private struct AvailabilityStatus: Codable {
    let isAvailable: Bool
}

enum AvailabilityRepository {
    static func fetchMyStatus() async throws -> Bool {
        let status: AvailabilityStatus = try await APIClient.request(.get, "/me/availability")
        return status.isAvailable
    }

    /// The backend sets the expiry (one hour from now when available).
    static func setAvailable(_ available: Bool) async throws {
        let _: AvailabilityStatus = try await APIClient.request(
            .put,
            "/me/availability",
            body: AvailabilityStatus(isAvailable: available)
        )
    }
}
