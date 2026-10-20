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

        let fullName = session.user.userMetadata["full_name"]?.stringValue

        if let existing {
            // Apple's name arrives in a follow-up metadata update, after the
            // profile row may already have been created without it.
            if existing.displayName == nil, let fullName {
                return try await SupabaseManager.client
                    .from("profiles")
                    .update(["display_name": fullName])
                    .eq("id", value: userId)
                    .select()
                    .single()
                    .execute()
                    .value
            }
            return existing
        }

        var row = ["id": userId.uuidString]
        row["email"] = session.user.email
        row["display_name"] = fullName

        let created: Profile = try await SupabaseManager.client
            .from("profiles")
            .insert(row)
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
