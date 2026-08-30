import Foundation

struct Profile: Codable, Identifiable {
    let id: UUID
    let displayName: String?
    let photoURL: String?
    let onboardingComplete: Bool
    let createdAt: Date
    let email: String?
    let phoneNumber: String?

    enum CodingKeys: String, CodingKey {
        case id
        case displayName = "display_name"
        case photoURL = "photo_url"
        case onboardingComplete = "onboarding_complete"
        case createdAt = "created_at"
        case email
        case phoneNumber = "phone_number"
    }
}
