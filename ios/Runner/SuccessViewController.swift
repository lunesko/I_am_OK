import UIKit

final class SuccessViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.yaBackground.withAlphaComponent(0.98)
        setupLayout()
    }

    private func setupLayout() {
        let header = UIView()
        header.backgroundColor = .yaCard
        header.translatesAutoresizingMaskIntoConstraints = false

        let titleLabel = UILabel()
        titleLabel.text = "Я ОК"
        titleLabel.font = .systemFont(ofSize: 22, weight: .bold)
        titleLabel.textColor = .yaTextPrimary
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        let closeButton = UIButton(type: .system)
        closeButton.setTitle("✕", for: .normal)
        closeButton.titleLabel?.font = .systemFont(ofSize: 18)
        closeButton.backgroundColor = .yaBackground
        closeButton.layer.cornerRadius = 10
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.addTarget(self, action: #selector(close), for: .touchUpInside)

        header.addSubview(titleLabel)
        header.addSubview(closeButton)

        let successIcon = UILabel()
        successIcon.text = "✓"
        successIcon.textAlignment = .center
        successIcon.textColor = .white
        successIcon.backgroundColor = .yaSuccess
        successIcon.layer.cornerRadius = 50
        successIcon.clipsToBounds = true
        successIcon.font = .systemFont(ofSize: 48, weight: .bold)
        successIcon.translatesAutoresizingMaskIntoConstraints = false

        let successTitle = UILabel()
        successTitle.text = "Відправлено"
        successTitle.font = .systemFont(ofSize: 22, weight: .bold)
        successTitle.textColor = .yaTextPrimary
        successTitle.translatesAutoresizingMaskIntoConstraints = false

        let listStack = UIStackView()
        listStack.axis = .vertical
        listStack.spacing = 8
        listStack.translatesAutoresizingMaskIntoConstraints = false
        listStack.backgroundColor = .yaCard
        listStack.layer.cornerRadius = 20
        listStack.layoutMargins = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
        listStack.isLayoutMarginsRelativeArrangement = true

        let contacts = ContactStore.shared.getContacts()
        if contacts.isEmpty {
            let label = UILabel()
            label.text = "Немає доданих людей"
            label.textColor = .yaTextSecondary
            label.font = .systemFont(ofSize: 14)
            listStack.addArrangedSubview(label)
        } else {
            contacts.forEach { contact in
                let row = UIStackView()
                row.axis = .horizontal
                row.spacing = 8

                let nameLabel = UILabel()
                nameLabel.text = contact.name
                nameLabel.textColor = .yaTextPrimary
                nameLabel.font = .systemFont(ofSize: 15, weight: .medium)

                let status = UILabel()
                status.text = "✓"
                status.textColor = .yaSuccess
                status.font = .systemFont(ofSize: 16, weight: .bold)

                row.addArrangedSubview(nameLabel)
                row.addArrangedSubview(UIView())
                row.addArrangedSubview(status)
                listStack.addArrangedSubview(row)
            }
        }

        view.addSubview(header)
        view.addSubview(successIcon)
        view.addSubview(successTitle)
        view.addSubview(listStack)

        NSLayoutConstraint.activate([
            header.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            header.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            header.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            header.heightAnchor.constraint(equalToConstant: 64),

            titleLabel.leadingAnchor.constraint(equalTo: header.leadingAnchor, constant: 20),
            titleLabel.centerYAnchor.constraint(equalTo: header.centerYAnchor),
            closeButton.trailingAnchor.constraint(equalTo: header.trailingAnchor, constant: -20),
            closeButton.centerYAnchor.constraint(equalTo: header.centerYAnchor),
            closeButton.widthAnchor.constraint(equalToConstant: 40),
            closeButton.heightAnchor.constraint(equalToConstant: 40),

            successIcon.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            successIcon.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -80),
            successIcon.widthAnchor.constraint(equalToConstant: 100),
            successIcon.heightAnchor.constraint(equalToConstant: 100),

            successTitle.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            successTitle.topAnchor.constraint(equalTo: successIcon.bottomAnchor, constant: 16),

            listStack.topAnchor.constraint(equalTo: successTitle.bottomAnchor, constant: 20),
            listStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            listStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40)
        ])
    }

    @objc private func close() {
        dismiss(animated: true)
    }
}
