import Foundation

struct Contact: Codable {
    let id: String
    var name: String
    var lastCheckin: TimeInterval?
}

final class ContactStore {
    static let shared = ContactStore()
    private let key = "ya_ok_contacts"
    private let defaults = UserDefaults.standard

    private init() {}

    func getContacts() -> [Contact] {
        guard let data = defaults.data(forKey: key) else { return [] }
        return (try? JSONDecoder().decode([Contact].self, from: data)) ?? []
    }

    func saveContacts(_ contacts: [Contact]) {
        if let data = try? JSONEncoder().encode(contacts) {
            defaults.set(data, forKey: key)
        }
    }

    func addContact(_ contact: Contact) {
        var contacts = getContacts()
        contacts.append(contact)
        saveContacts(contacts)
    }
}
