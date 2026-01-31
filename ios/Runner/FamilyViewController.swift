import UIKit

final class FamilyViewController: UIViewController {
    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private let contactsStack = UIStackView()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .yaBackground
        setupLayout()
        reloadContacts()
    }

    private func setupLayout() {
        let header = UIView()
        header.backgroundColor = .yaCard
        header.translatesAutoresizingMaskIntoConstraints = false

        let titleLabel = UILabel()
        titleLabel.text = "Мої люди"
        titleLabel.font = .systemFont(ofSize: 20, weight: .bold)
        titleLabel.textColor = .yaTextPrimary
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        header.addSubview(titleLabel)
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: header.leadingAnchor, constant: 20),
            titleLabel.centerYAnchor.constraint(equalTo: header.centerYAnchor)
        ])

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentStack.axis = .vertical
        contentStack.spacing = 12
        contentStack.translatesAutoresizingMaskIntoConstraints = false

        contactsStack.axis = .vertical
        contactsStack.spacing = 12
        contactsStack.translatesAutoresizingMaskIntoConstraints = false
        contentStack.addArrangedSubview(contactsStack)

        let addButton = UIButton(type: .system)
        addButton.setTitle("+ Додати людину", for: .normal)
        addButton.setTitleColor(.yaPrimary, for: .normal)
        addButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .bold)
        addButton.backgroundColor = .yaCard
        addButton.layer.cornerRadius = 16
        addButton.layer.borderWidth = 1
        addButton.layer.borderColor = UIColor.yaBorder.cgColor
        addButton.heightAnchor.constraint(equalToConstant: 48).isActive = true
        addButton.addTarget(self, action: #selector(addContact), for: .touchUpInside)
        contentStack.addArrangedSubview(addButton)

        let myQrButton = UIButton(type: .system)
        myQrButton.setTitle("📱 Мій QR", for: .normal)
        myQrButton.setTitleColor(.yaPrimary, for: .normal)
        myQrButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .bold)
        myQrButton.backgroundColor = .yaCard
        myQrButton.layer.cornerRadius = 16
        myQrButton.layer.borderWidth = 1
        myQrButton.layer.borderColor = UIColor.yaBorder.cgColor
        myQrButton.heightAnchor.constraint(equalToConstant: 48).isActive = true
        myQrButton.addTarget(self, action: #selector(openMyQr), for: .touchUpInside)
        contentStack.addArrangedSubview(myQrButton)

        let feedbackCard = UIView()
        feedbackCard.backgroundColor = .yaPrimary
        feedbackCard.layer.cornerRadius = 20
        feedbackCard.translatesAutoresizingMaskIntoConstraints = false

        let feedbackStack = UIStackView()
        feedbackStack.axis = .vertical
        feedbackStack.spacing = 8
        feedbackStack.translatesAutoresizingMaskIntoConstraints = false

        let heart = UILabel()
        heart.text = "❤️"
        heart.font = .systemFont(ofSize: 26)

        let feedbackTitle = UILabel()
        feedbackTitle.text = "Зворотній зв'язок"
        feedbackTitle.font = .systemFont(ofSize: 18, weight: .bold)
        feedbackTitle.textColor = .white

        let feedbackDesc = UILabel()
        feedbackDesc.text = "Твої близькі теж можуть надіслати тобі швидке повідомлення"
        feedbackDesc.font = .systemFont(ofSize: 13)
        feedbackDesc.textColor = .white
        feedbackDesc.numberOfLines = 0

        let feedbackButton = UIButton(type: .system)
        feedbackButton.setTitle("Надіслати \"Вдома все добре\"", for: .normal)
        feedbackButton.backgroundColor = .white
        feedbackButton.setTitleColor(.yaPrimary, for: .normal)
        feedbackButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .bold)
        feedbackButton.layer.cornerRadius = 12
        feedbackButton.heightAnchor.constraint(equalToConstant: 44).isActive = true
        feedbackButton.addTarget(self, action: #selector(sendFeedback), for: .touchUpInside)

        feedbackStack.addArrangedSubview(heart)
        feedbackStack.addArrangedSubview(feedbackTitle)
        feedbackStack.addArrangedSubview(feedbackDesc)
        feedbackStack.addArrangedSubview(feedbackButton)

        feedbackCard.addSubview(feedbackStack)
        NSLayoutConstraint.activate([
            feedbackStack.leadingAnchor.constraint(equalTo: feedbackCard.leadingAnchor, constant: 16),
            feedbackStack.trailingAnchor.constraint(equalTo: feedbackCard.trailingAnchor, constant: -16),
            feedbackStack.topAnchor.constraint(equalTo: feedbackCard.topAnchor, constant: 16),
            feedbackStack.bottomAnchor.constraint(equalTo: feedbackCard.bottomAnchor, constant: -16)
        ])
        contentStack.addArrangedSubview(feedbackCard)

        view.addSubview(header)
        view.addSubview(scrollView)
        scrollView.addSubview(contentStack)

        NSLayoutConstraint.activate([
            header.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            header.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            header.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            header.heightAnchor.constraint(equalToConstant: 64),

            scrollView.topAnchor.constraint(equalTo: header.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 20),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 20),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -20),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -20),
            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -40)
        ])
    }

    private func reloadContacts() {
        contactsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        let contacts = ContactStore.shared.getContacts()
        if contacts.isEmpty {
            let label = UILabel()
            label.text = "Поки немає людей"
            label.textColor = .yaTextSecondary
            label.font = .systemFont(ofSize: 14)
            contactsStack.addArrangedSubview(label)
            return
        }

        contacts.forEach { contact in
            let card = ContactCardView(contact: contact)
            contactsStack.addArrangedSubview(card)
        }
    }

    @objc private func addContact() {
        let alert = UIAlertController(title: "Додати людину", message: nil, preferredStyle: .alert)
        alert.addTextField { $0.placeholder = "Ім'я" }
        alert.addTextField { $0.placeholder = "ID (необов'язково)" }
        alert.addAction(UIAlertAction(title: "Скасувати", style: .cancel))
        alert.addAction(UIAlertAction(title: "Додати", style: .default, handler: { [weak self] _ in
            guard let name = alert.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !name.isEmpty else { return }
            let id = alert.textFields?.last?.text?.trimmingCharacters(in: .whitespacesAndNewlines)
            let contactId = (id?.isEmpty == false) ? id! : "local_\(Int(Date().timeIntervalSince1970))"
            ContactStore.shared.addContact(Contact(id: contactId, name: name, lastCheckin: nil))
            self?.reloadContacts()
        }))
        present(alert, animated: true)
    }

    func openAddContact(prefillId: String) {
        let alert = UIAlertController(title: "Додати людину", message: nil, preferredStyle: .alert)
        alert.addTextField { $0.placeholder = "Ім'я" }
        alert.addTextField {
            $0.placeholder = "ID (необов'язково)"
            $0.text = prefillId
            $0.isEnabled = false
        }
        alert.addAction(UIAlertAction(title: "Скасувати", style: .cancel))
        alert.addAction(UIAlertAction(title: "Додати", style: .default, handler: { [weak self] _ in
            guard let name = alert.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !name.isEmpty else { return }
            let contactId = prefillId
            ContactStore.shared.addContact(Contact(id: contactId, name: name, lastCheckin: nil))
            self?.reloadContacts()
        }))
        present(alert, animated: true)
    }

    @objc private func openMyQr() {
        guard let identityId = CoreBridge.shared.getIdentityId() else { return }
        present(QrCodeViewController(identityId: identityId), animated: true)
    }

    @objc private func sendFeedback() {
        let result = CoreBridge.shared.sendText("Вдома все добре")
        let message = result == 0 ? "Повідомлення надіслано" : "Помилка (\(result))"
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

final class ContactCardView: UIView {
    init(contact: Contact) {
        super.init(frame: .zero)
        backgroundColor = .yaCard
        layer.cornerRadius = 16
        layer.borderWidth = 1
        layer.borderColor = UIColor.yaBorder.cgColor
        translatesAutoresizingMaskIntoConstraints = false

        let avatar = UILabel()
        avatar.text = contact.name.first.map { String($0) }?.uppercased() ?? "?"
        avatar.textAlignment = .center
        avatar.backgroundColor = .yaSuccess
        avatar.textColor = .white
        avatar.font = .systemFont(ofSize: 18, weight: .bold)
        avatar.layer.cornerRadius = 12
        avatar.clipsToBounds = true
        avatar.translatesAutoresizingMaskIntoConstraints = false
        avatar.widthAnchor.constraint(equalToConstant: 48).isActive = true
        avatar.heightAnchor.constraint(equalToConstant: 48).isActive = true

        let nameLabel = UILabel()
        nameLabel.text = contact.name
        nameLabel.textColor = .yaTextPrimary
        nameLabel.font = .systemFont(ofSize: 16, weight: .bold)

        let timeLabel = UILabel()
        if let last = contact.lastCheckin {
            let date = Date(timeIntervalSince1970: last)
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            formatter.timeStyle = .short
            timeLabel.text = formatter.string(from: date)
        } else {
            timeLabel.text = "Ще не бачив"
        }
        timeLabel.textColor = .yaTextSecondary
        timeLabel.font = .systemFont(ofSize: 13)

        let infoStack = UIStackView(arrangedSubviews: [nameLabel, timeLabel])
        infoStack.axis = .vertical
        infoStack.spacing = 2

        let statusLabel = UILabel()
        statusLabel.text = "✓"
        statusLabel.textColor = .yaSuccess

        let row = UIStackView(arrangedSubviews: [avatar, infoStack, statusLabel])
        row.axis = .horizontal
        row.spacing = 12
        row.alignment = .center
        row.translatesAutoresizingMaskIntoConstraints = false

        addSubview(row)
        NSLayoutConstraint.activate([
            row.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            row.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            row.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            row.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12)
        ])
    }

    required init?(coder: NSCoder) { nil }
}
