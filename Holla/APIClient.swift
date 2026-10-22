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

/// Sends JSON requests to holla-backend (or the legacy .NET backend),
/// attaching the current Supabase session as a bearer token. All data access
/// goes through here; the app talks to Supabase directly only for auth.
enum APIClient {
    enum Method: String {
        case get = "GET"
        case post = "POST"
        case put = "PUT"
        case patch = "PATCH"
    }

    private struct NoBody: Encodable {}
    struct Empty: Decodable {}

    private static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        let withFractionalSeconds = ISO8601DateFormatter()
        withFractionalSeconds.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let withoutFractionalSeconds = ISO8601DateFormatter()
        decoder.dateDecodingStrategy = .custom { decoder in
            let string = try decoder.singleValueContainer().decode(String.self)
            guard let date = withFractionalSeconds.date(from: string)
                ?? withoutFractionalSeconds.date(from: string)
            else {
                throw DecodingError.dataCorrupted(.init(
                    codingPath: decoder.codingPath,
                    debugDescription: "Invalid ISO-8601 date: \(string)"
                ))
            }
            return date
        }
        return decoder
    }()

    static func request<T: Decodable>(
        _ method: Method,
        _ path: String,
        baseURL: URL = Config.backendBaseURL
    ) async throws -> T {
        try await request(method, path, body: Optional<NoBody>.none, baseURL: baseURL)
    }

    static func request<T: Decodable, Body: Encodable>(
        _ method: Method,
        _ path: String,
        body: Body?,
        baseURL: URL = Config.backendBaseURL
    ) async throws -> T {
        var urlRequest = URLRequest(url: baseURL.appendingPathComponent(path))
        urlRequest.httpMethod = method.rawValue
        if let body {
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            urlRequest.httpBody = try JSONEncoder().encode(body)
        }

        guard let session = try? await SupabaseManager.client.auth.session else {
            throw APIError.notSignedIn
        }
        urlRequest.setValue("Bearer \(session.accessToken)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.server("Request to \(path) failed")
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            let message = (try? JSONDecoder().decode([String: String].self, from: data))?["error"]
            throw APIError.server(message ?? "Request to \(path) failed (\(httpResponse.statusCode))")
        }
        if T.self == Empty.self, data.isEmpty {
            return Empty() as! T
        }
        return try decoder.decode(T.self, from: data)
    }

    // MARK: - Legacy .NET backend (to be ported to holla-backend)

    private struct SyncContactsBody: Encodable {
        let phoneNumbers: [String]
    }

    static func syncContacts(phoneNumbers: [String]) async throws {
        let _: Empty = try await request(
            .post,
            "/api/contacts/sync",
            body: SyncContactsBody(phoneNumbers: phoneNumbers),
            baseURL: Config.apiBaseURL
        )
    }

    private struct AddFriendBody: Encodable {
        let email: String
    }

    struct AddFriendResponse: Decodable {
        let success: Bool
    }

    static func addFriend(email: String) async throws {
        let _: AddFriendResponse = try await request(
            .post,
            "/api/friends/add",
            body: AddFriendBody(email: email),
            baseURL: Config.apiBaseURL
        )
    }
}
