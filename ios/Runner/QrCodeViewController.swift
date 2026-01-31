import UIKit
import CoreImage

final class QrCodeViewController: UIViewController {
    private let identityId: String
    private let link: String

    private let imageView = UIImageView()
    private let idLabel = UILabel()

    init(identityId: String) {
        self.identityId = identityId
        let x = CoreBridge.shared.getIdentityX25519PublicKeyHex() ?? ""
        if x.isEmpty {
            self.link = "yaok://add?id=\(identityId)"
        } else {
            self.link = "yaok://add?id=\(identityId)&x=\(x)"
        }
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .fullScreen
    }

    required init?(coder: NSCoder) { nil }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .yaBackground
        setupLayout()
        render()
    }

    private func setupLayout() {
        let titleLabel = UILabel()
        titleLabel.text = "Мій QR-код"
        titleLabel.font = .systemFont(ofSize: 24, weight: .bold)
        titleLabel.textColor = .yaTextPrimary
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        let subtitleLabel = UILabel()
        subtitleLabel.text = "Покажіть цей код іншій людині для додавання"
        subtitleLabel.font = .systemFont(ofSize: 14)
        subtitleLabel.textColor = .yaTextSecondary
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 0
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false

        imageView.backgroundColor = .white
        imageView.layer.cornerRadius = 16
        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false

        idLabel.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        idLabel.textColor = .yaTextSecondary
        idLabel.textAlignment = .center
        idLabel.numberOfLines = 0
        idLabel.translatesAutoresizingMaskIntoConstraints = false

        let shareButton = UIButton(type: .system)
        shareButton.setTitle("Поділитися", for: .normal)
        shareButton.backgroundColor = .yaCard
        shareButton.setTitleColor(.yaPrimary, for: .normal)
        shareButton.layer.cornerRadius = 16
        shareButton.layer.borderWidth = 1
        shareButton.layer.borderColor = UIColor.yaBorder.cgColor
        shareButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .bold)
        shareButton.translatesAutoresizingMaskIntoConstraints = false
        shareButton.heightAnchor.constraint(equalToConstant: 52).isActive = true
        shareButton.addTarget(self, action: #selector(shareTapped), for: .touchUpInside)

        let closeButton = UIButton(type: .system)
        closeButton.setTitle("Закрити", for: .normal)
        closeButton.setTitleColor(.yaPrimary, for: .normal)
        closeButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .bold)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.heightAnchor.constraint(equalToConstant: 44).isActive = true
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel, imageView, idLabel, shareButton, closeButton])
        stack.axis = .vertical
        stack.spacing = 16
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor),

            imageView.widthAnchor.constraint(equalToConstant: 300),
            imageView.heightAnchor.constraint(equalToConstant: 300),
            shareButton.widthAnchor.constraint(equalTo: stack.widthAnchor),
            closeButton.widthAnchor.constraint(equalTo: stack.widthAnchor)
        ])
    }

    private func render() {
        idLabel.text = identityId
        imageView.image = makeQrImage(text: link, size: 512)
    }

    private func makeQrImage(text: String, size: CGFloat) -> UIImage? {
        let data = text.data(using: .utf8)
        guard let filter = CIFilter(name: "CIQRCodeGenerator") else { return nil }
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("M", forKey: "inputCorrectionLevel")
        guard let output = filter.outputImage else { return nil }

        // Scale without blurring.
        let scaleX = size / output.extent.size.width
        let scaleY = size / output.extent.size.height
        let transformed = output.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))

        let context = CIContext(options: nil)
        guard let cgImage = context.createCGImage(transformed, from: transformed.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }

    @objc private func shareTapped() {
        let text = "Додай мене в Я ОК:\n\(link)\n\nID:\n\(identityId)"
        let vc = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        present(vc, animated: true)
    }

    @objc private func closeTapped() {
        dismiss(animated: true)
    }
}

