import UIKit

final class OnboardingViewController: UIViewController {
    var onComplete: (() -> Void)?

    private let logoView = UIView()
    private let logoLabel = UILabel()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let primaryButton = UIButton(type: .system)
    private let secondaryButton = UIButton(type: .system)
    private let footerLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .yaBackground
        setupLayout()
    }

    private func setupLayout() {
        logoView.backgroundColor = .yaPrimary
        logoView.layer.cornerRadius = 30
        logoView.translatesAutoresizingMaskIntoConstraints = false

        logoLabel.text = "💚"
        logoLabel.font = .systemFont(ofSize: 48)
        logoLabel.translatesAutoresizingMaskIntoConstraints = false
        logoView.addSubview(logoLabel)

        titleLabel.text = "Я ОК"
        titleLabel.font = .systemFont(ofSize: 34, weight: .bold)
        titleLabel.textColor = .yaTextPrimary

        subtitleLabel.text = "Один дотик — спокій для близьких"
        subtitleLabel.font = .systemFont(ofSize: 16)
        subtitleLabel.textColor = .yaTextSecondary
        subtitleLabel.numberOfLines = 0
        subtitleLabel.textAlignment = .center

        primaryButton.setTitle("Створити ідентичність", for: .normal)
        primaryButton.backgroundColor = .yaSuccess
        primaryButton.setTitleColor(.white, for: .normal)
        primaryButton.layer.cornerRadius = 16
        primaryButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .bold)
        primaryButton.addTarget(self, action: #selector(createIdentity), for: .touchUpInside)

        secondaryButton.setTitle("Відновити з ключа", for: .normal)
        secondaryButton.backgroundColor = .yaCard
        secondaryButton.setTitleColor(.yaTextPrimary, for: .normal)
        secondaryButton.layer.cornerRadius = 16
        secondaryButton.layer.borderWidth = 1
        secondaryButton.layer.borderColor = UIColor.yaBorder.cgColor
        secondaryButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .bold)
        secondaryButton.addTarget(self, action: #selector(showRestoreInfo), for: .touchUpInside)

        footerLabel.text = "Без реєстрації. Без геолокації. Безпечно."
        footerLabel.font = .systemFont(ofSize: 13)
        footerLabel.textColor = .yaTextSecondary
        footerLabel.textAlignment = .center

        let stack = UIStackView(arrangedSubviews: [
            logoView,
            titleLabel,
            subtitleLabel,
            primaryButton,
            secondaryButton
        ])
        stack.axis = .vertical
        stack.spacing = 16
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(stack)
        view.addSubview(footerLabel)

        NSLayoutConstraint.activate([
            logoView.widthAnchor.constraint(equalToConstant: 120),
            logoView.heightAnchor.constraint(equalToConstant: 120),
            logoLabel.centerXAnchor.constraint(equalTo: logoView.centerXAnchor),
            logoLabel.centerYAnchor.constraint(equalTo: logoView.centerYAnchor),

            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor),

            primaryButton.widthAnchor.constraint(equalTo: stack.widthAnchor),
            primaryButton.heightAnchor.constraint(equalToConstant: 52),
            secondaryButton.widthAnchor.constraint(equalTo: stack.widthAnchor),
            secondaryButton.heightAnchor.constraint(equalToConstant: 52),

            footerLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            footerLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }

    @objc private func createIdentity() {
        if CoreBridge.shared.ensureIdentity() {
            onComplete?()
        } else {
            showAlert(title: "Помилка", message: "Не вдалося створити ідентичність.")
        }
    }

    @objc private func showRestoreInfo() {
        showAlert(title: "Недоступно", message: "Відновлення поки не реалізовано.")
    }

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
