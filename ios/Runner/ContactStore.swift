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
    private let queue = DispatchQueue(label: "com.poruchstudio.yaok.contactstore", attributes: .concurrent)

    private init() {}

    func getContacts() -> [Contact] {
        queue.sync {
            guard let data = defaults.data(forKey: key) else { return [] }
            return (try? JSONDecoder().decode([Contact].self, from: data)) ?? []
        }
    }

    func saveContacts(_ contacts: [Contact]) {
        queue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            if let data = try? JSONEncoder().encode(contacts) {
                self.defaults.set(data, forKey: self.key)
            }
        }
    }

    func addContact(_ contact: Contact) {
        queue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            var contacts = self.getContactsUnsafe()
            contacts.append(contact)
            self.saveContactsUnsafe(contacts)
        }
    }
    
    // MARK: - Private (unsafe - must be called from queue)
    
    private func getContactsUnsafe() -> [Contact] {
        guard let data = defaults.data(forKey: key) else { return [] }
        return (try? JSONDecoder().decode([Contact].self, from: data)) ?? []
    }
    
    private func saveContactsUnsafe(_ contacts: [Contact]) {
        if let data = try? JSONEncoder().encode(contacts) {
            defaults.set(data, forKey: key)
        }
    }
}
