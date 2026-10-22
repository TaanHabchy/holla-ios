import Foundation

struct Profile: Codable, Identifiable {
    let id: UUID
    let displayName: String?
    let photoURL: String?
    let onboardingComplete: Bool
    let createdAt: Date
    let email: String?
    let phoneNumber: String?
}

struct Friend: Decodable, Identifiable {
    let id: UUID
    let displayName: String?
    let email: String?
    let phoneNumber: String?
    let isAvailable: Bool
}
