import UIKit
import AVFoundation

final class InboxViewController: UIViewController {
    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private var audioPlayer: AVAudioPlayer?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .yaBackground
        setupLayout()
        reloadMessages()
    }

    private func setupLayout() {
        let header = UIView()
        header.backgroundColor = .yaCard
        header.translatesAutoresizingMaskIntoConstraints = false

        let titleLabel = UILabel()
        titleLabel.text = "Вхідні"
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

    private func reloadMessages() {
        contentStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        let messages = CoreBridge.shared.getRecentMessagesFull(limit: 50)
        guard !messages.isEmpty else {
            let empty = UILabel()
            empty.text = "Поки немає повідомлень"
            empty.textColor = .yaTextSecondary
            empty.font = .systemFont(ofSize: 14)
            contentStack.addArrangedSubview(empty)
            return
        }

        messages.forEach { summary in
            let row = MessageRowView(summary: summary)
            row.onPlayVoice = { [weak self] base64 in
                self?.playVoice(base64: base64)
            }
            contentStack.addArrangedSubview(row)
        }
    }

    private func playVoice(base64: String) {
        guard let data = Data(base64Encoded: base64) else { return }
        do {
            audioPlayer = try AVAudioPlayer(data: data)
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
        } catch {
            audioPlayer = nil
        }
    }
}

final class MessageRowView: UIView {
    var onPlayVoice: ((String) -> Void)?
    private let summary: MessageSummary

    init(summary: MessageSummary) {
        self.summary = summary
        super.init(frame: .zero)
        backgroundColor = .yaCard
        layer.cornerRadius = 16
        layer.borderWidth = 1
        layer.borderColor = UIColor.yaBorder.cgColor
        translatesAutoresizingMaskIntoConstraints = false

        let emojiLabel = UILabel()
        emojiLabel.text = emoji(for: summary)
        emojiLabel.textAlignment = .center
        emojiLabel.backgroundColor = .yaBackground
        emojiLabel.layer.cornerRadius = 10
        emojiLabel.clipsToBounds = true
        emojiLabel.translatesAutoresizingMaskIntoConstraints = false
        emojiLabel.widthAnchor.constraint(equalToConstant: 40).isActive = true
        emojiLabel.heightAnchor.constraint(equalToConstant: 40).isActive = true

        let titleLabel = UILabel()
        titleLabel.text = title(for: summary)
        titleLabel.textColor = .yaTextPrimary
        titleLabel.font = .systemFont(ofSize: 16, weight: .bold)

        let subtitleLabel = UILabel()
        subtitleLabel.text = timeText(for: summary)
        subtitleLabel.textColor = .yaTextSecondary
        subtitleLabel.font = .systemFont(ofSize: 13)

        let infoStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        infoStack.axis = .vertical
        infoStack.spacing = 2

        let row = UIStackView(arrangedSubviews: [emojiLabel, infoStack])
        row.axis = .horizontal
        row.spacing = 12
        row.alignment = .center
        row.translatesAutoresizingMaskIntoConstraints = false

        addSubview(row)
        if let base64 = summary.voiceBase64, !base64.isEmpty {
            let tap = UITapGestureRecognizer(target: self, action: #selector(playVoice))
            addGestureRecognizer(tap)
        }
        NSLayoutConstraint.activate([
            row.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            row.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            row.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            row.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12)
        ])
    }

    required init?(coder: NSCoder) { nil }

    private func title(for summary: MessageSummary) -> String {
        if summary.messageType == "status" {
            switch summary.status {
            case "ok": return "Я ОК"
            case "busy": return "Все нормально, зайнятий"
            case "later": return "Зателефоную пізніше"
            default: return "Статус"
            }
        }
        if summary.messageType == "voice" || summary.hasVoice {
            return "🎙️ Голос"
        }
        if let text = summary.text, !text.isEmpty {
            return text
        }
        return "Сигнал"
    }

    private func emoji(for summary: MessageSummary) -> String {
        if summary.messageType == "status" {
            switch summary.status {
            case "ok": return "💚"
            case "busy": return "💛"
            case "later": return "💙"
            default: return "•"
            }
        }
        if summary.messageType == "voice" || summary.hasVoice { return "🎙️" }
        if summary.messageType == "text" { return "💬" }
        return "•"
    }

    private func timeText(for summary: MessageSummary) -> String {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: summary.timestamp) else { return "—" }
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .short
        return dateFormatter.string(from: date)
    }

    @objc private func playVoice() {
        if let base64 = summary.voiceBase64, !base64.isEmpty {
            onPlayVoice?(base64)
        }
    }
}
