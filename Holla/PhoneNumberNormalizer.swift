import Foundation

/// Requires a leading "+" (matches the RN app's normalizer, which never
/// passes a default region and so only succeeds on already-international
/// input) then strips formatting and checks a plausible E.164 digit count.
enum PhoneNumberNormalizer {
    static func normalizeToE164(_ raw: String) -> String? {
        let trimmed = raw.trimmingCharacters(in: .whitespaces)
        guard trimmed.hasPrefix("+") else { return nil }

        let digits = trimmed.dropFirst().filter(\.isNumber)
        guard (8...15).contains(digits.count) else { return nil }

        return "+\(digits)"
    }
}
