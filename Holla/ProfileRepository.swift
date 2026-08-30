import Foundation
import Supabase

enum ProfileRepository {
    static func fetchOrCreateProfile(session: Session) async throws -> Profile? {
        let userId = session.user.id

        let existing: Profile? = try await SupabaseManager.client
            .from("profiles")
            .select()
            .eq("id", value: userId)
            .maybeSingle()
            .execute()
            .value

        if let existing {
            return existing
        }

        guard let email = session.user.email else {
            return nil
        }

        let created: Profile = try await SupabaseManager.client
            .from("profiles")
            .insert(["id": userId.uuidString, "email": email])
            .select()
            .single()
            .execute()
            .value

        return created
    }

    static func updatePhoneNumber(userId: UUID, e164: String) async throws {
        try await SupabaseManager.client
            .from("profiles")
            .update(["phone_number": e164])
            .eq("id", value: userId)
            .execute()
    }
}
