import Contacts

enum ContactsService {
    static func permissionStatus() -> CNAuthorizationStatus {
        CNContactStore.authorizationStatus(for: .contacts)
    }

    static func requestPermission() async throws -> Bool {
        try await CNContactStore().requestAccess(for: .contacts)
    }

    static func readContactPhoneNumbers() throws -> [String] {
        let store = CNContactStore()
        let request = CNContactFetchRequest(keysToFetch: [CNContactPhoneNumbersKey as CNKeyDescriptor])
        var numbers = Set<String>()

        try store.enumerateContacts(with: request) { contact, _ in
            for phoneNumber in contact.phoneNumbers {
                if let e164 = PhoneNumberNormalizer.normalizeToE164(phoneNumber.value.stringValue) {
                    numbers.insert(e164)
                }
            }
        }

        return Array(numbers)
    }
}
