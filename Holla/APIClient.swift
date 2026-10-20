import Foundation

enum APIError: LocalizedError {
    case notSignedIn
    case server(String)

    var errorDescription: String? {
        switch self {
        case .notSignedIn: return "Not signed in"
        case .server(let message): return message
        }
    }
}

/// Mirrors src/lib/api.ts's `request` helper in the RN app: POSTs JSON to the
/// .NET backend, attaching the current Supabase session as a bearer token
/// when the endpoint requires auth.
enum APIClient {
    static func request<T: Decodable>(
        _ path: String,
        body: [String: Any] = [:],
        requireAuth: Bool
    ) async throws -> T {
        var urlRequest = URLRequest(url: Config.apiBaseURL.appendingPathComponent(path))
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = try JSONSerialization.data(withJSONObject: body)

        if requireAuth {
            guard let session = try? await SupabaseManager.client.auth.session else {
                throw APIError.notSignedIn
            }
            urlRequest.setValue("Bearer \(session.accessToken)", forHTTPHeaderField: "Authorization")
        }

        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.server("Request to \(path) failed")
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            let message = (try? JSONDecoder().decode([String: String].self, from: data))?["error"]
            throw APIError.server(message ?? "Request to \(path) failed (\(httpResponse.statusCode))")
        }
        return try JSONDecoder().decode(T.self, from: data)
    }

    struct SyncContactsResponse: Decodable {}

    static func syncContacts(phoneNumbers: [String]) async throws {
        let _: SyncContactsResponse = try await request(
            "/api/contacts/sync",
            body: ["phoneNumbers": phoneNumbers],
            requireAuth: true
        )
    }

    struct AddFriendResponse: Decodable {
        let success: Bool
    }

    static func addFriend(email: String) async throws {
        let _: AddFriendResponse = try await request(
            "/api/friends/add",
            body: ["email": email],
            requireAuth: true
        )
    }
}
