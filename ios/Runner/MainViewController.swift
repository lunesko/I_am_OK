import UIKit
import CoreLocation
import AVFoundation

final class MainViewController: UIViewController, AVAudioRecorderDelegate {
    private enum StatusOption {
        case ok
        case busy
        case later
        case hug
    }

    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private let lastCheckinLabel = UILabel()
    private let locationWarningLabel = UILabel()
    private let textField = UITextField()
    private let recordButton = UIButton(type: .system)
    private let clearVoiceButton = UIButton(type: .system)
    private let voiceStatusLabel = UILabel()

    private var statusCards: [StatusOption: StatusCardView] = [:]
    private var selectedStatus: StatusOption = .ok
    private var recordedVoice: Data?
    private var recorder: AVAudioRecorder?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .yaBackground
        setupLayout()
        updateLastCheckin()
        updateStatus(.ok)
        updateLocationWarning()
    }

    private func setupLayout() {
        let header = UIView()
        header.backgroundColor = .yaCard
        header.translatesAutoresizingMaskIntoConstraints = false

        let titleLabel = UILabel()
        titleLabel.text = "Я ОК"
        titleLabel.font = .systemFont(ofSize: 26, weight: .bold)
        titleLabel.textColor = .yaTextPrimary
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        let familyButton = UIButton(type: .system)
        familyButton.setTitle("👥", for: .normal)
        familyButton.titleLabel?.font = .systemFont(ofSize: 18)
        familyButton.backgroundColor = .yaBackground
        familyButton.layer.cornerRadius = 10
        familyButton.translatesAutoresizingMaskIntoConstraints = false
        familyButton.addTarget(self, action: #selector(openFamily), for: .touchUpInside)

        let settingsButton = UIButton(type: .system)
        settingsButton.setTitle("⚙️", for: .normal)
        settingsButton.titleLabel?.font = .systemFont(ofSize: 18)
        settingsButton.backgroundColor = .yaBackground
        settingsButton.layer.cornerRadius = 10
        settingsButton.translatesAutoresizingMaskIntoConstraints = false
        settingsButton.addTarget(self, action: #selector(openSettings), for: .touchUpInside)

        header.addSubview(titleLabel)
        header.addSubview(familyButton)
        header.addSubview(settingsButton)

        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: header.leadingAnchor, constant: 20),
            titleLabel.centerYAnchor.constraint(equalTo: header.centerYAnchor),

            settingsButton.trailingAnchor.constraint(equalTo: header.trailingAnchor, constant: -20),
            settingsButton.centerYAnchor.constraint(equalTo: header.centerYAnchor),
            settingsButton.widthAnchor.constraint(equalToConstant: 40),
            settingsButton.heightAnchor.constraint(equalToConstant: 40),

            familyButton.trailingAnchor.constraint(equalTo: settingsButton.leadingAnchor, constant: -12),
            familyButton.centerYAnchor.constraint(equalTo: header.centerYAnchor),
            familyButton.widthAnchor.constraint(equalToConstant: 40),
            familyButton.heightAnchor.constraint(equalToConstant: 40)
        ])

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentStack.axis = .vertical
        contentStack.spacing = 12
        contentStack.translatesAutoresizingMaskIntoConstraints = false

        let cards: [(StatusOption, String, String)] = [
            (.ok, "💚", "Я ОК"),
            (.busy, "💛", "Все нормально, зайнятий"),
            (.later, "💙", "Зателефоную пізніше"),
            (.hug, "🤍", "Обійми")
        ]

        cards.forEach { option, emoji, text in
            let card = StatusCardView(emoji: emoji, text: text)
            card.addTarget(self, action: #selector(statusTapped(_:)), for: .touchUpInside)
            statusCards[option] = card
            contentStack.addArrangedSubview(card)
        }

        textField.placeholder = "Короткий текст (до 256 символів)"
        textField.backgroundColor = .yaCard
        textField.layer.cornerRadius = 16
        textField.layer.borderWidth = 1
        textField.layer.borderColor = UIColor.yaBorder.cgColor
        textField.textColor = .yaTextPrimary
        textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 1))
        textField.leftViewMode = .always
        textField.heightAnchor.constraint(equalToConstant: 52).isActive = true
        contentStack.addArrangedSubview(textField)

        let voiceLabel = UILabel()
        voiceLabel.text = "Запис голосу"
        voiceLabel.font = .systemFont(ofSize: 14)
        voiceLabel.textColor = .yaTextSecondary
        contentStack.addArrangedSubview(voiceLabel)

        let voiceRow = UIStackView()
        voiceRow.axis = .horizontal
        voiceRow.spacing = 12

        recordButton.setTitle("🎙️", for: .normal)
        recordButton.backgroundColor = .yaCard
        recordButton.layer.cornerRadius = 16
        recordButton.layer.borderWidth = 1
        recordButton.layer.borderColor = UIColor.yaBorder.cgColor
        recordButton.titleLabel?.font = .systemFont(ofSize: 18)
        recordButton.heightAnchor.constraint(equalToConstant: 44).isActive = true
        recordButton.addTarget(self, action: #selector(toggleRecording), for: .touchUpInside)

        clearVoiceButton.setTitle("✕", for: .normal)
        clearVoiceButton.backgroundColor = .yaCard
        clearVoiceButton.layer.cornerRadius = 16
        clearVoiceButton.layer.borderWidth = 1
        clearVoiceButton.layer.borderColor = UIColor.yaBorder.cgColor
        clearVoiceButton.widthAnchor.constraint(equalToConstant: 44).isActive = true
        clearVoiceButton.heightAnchor.constraint(equalToConstant: 44).isActive = true
        clearVoiceButton.isHidden = true
        clearVoiceButton.addTarget(self, action: #selector(clearVoice), for: .touchUpInside)

        voiceRow.addArrangedSubview(recordButton)
        voiceRow.addArrangedSubview(clearVoiceButton)
        contentStack.addArrangedSubview(voiceRow)

        voiceStatusLabel.textColor = .yaTextSecondary
        voiceStatusLabel.font = .systemFont(ofSize: 13)
        contentStack.addArrangedSubview(voiceStatusLabel)

        let sendButton = UIButton(type: .system)
        sendButton.setTitle("Відправити", for: .normal)
        sendButton.backgroundColor = .yaSuccess
        sendButton.setTitleColor(.white, for: .normal)
        sendButton.titleLabel?.font = .systemFont(ofSize: 20, weight: .bold)
        sendButton.layer.cornerRadius = 30
        sendButton.heightAnchor.constraint(equalToConstant: 64).isActive = true
        sendButton.addTarget(self, action: #selector(sendCheckin), for: .touchUpInside)
        contentStack.addArrangedSubview(sendButton)

        lastCheckinLabel.textColor = .yaTextSecondary
        lastCheckinLabel.font = .systemFont(ofSize: 13)
        lastCheckinLabel.textAlignment = .center
        contentStack.addArrangedSubview(lastCheckinLabel)

        let footer = UIStackView()
        footer.axis = .horizontal
        footer.spacing = 8
        footer.alignment = .center

        let shield = UILabel()
        shield.text = "🛡️"
        shield.textColor = .yaWarning
        shield.font = .systemFont(ofSize: 14)

        locationWarningLabel.font = .systemFont(ofSize: 13)
        locationWarningLabel.textColor = .yaTextSecondary
        locationWarningLabel.numberOfLines = 0

        footer.addArrangedSubview(shield)
        footer.addArrangedSubview(locationWarningLabel)

        let footerContainer = UIView()
        footerContainer.backgroundColor = .yaCard
        footerContainer.translatesAutoresizingMaskIntoConstraints = false
        footerContainer.addSubview(footer)
        footer.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(header)
        view.addSubview(scrollView)
        scrollView.addSubview(contentStack)
        view.addSubview(footerContainer)

        NSLayoutConstraint.activate([
            header.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            header.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            header.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            header.heightAnchor.constraint(equalToConstant: 64),

            scrollView.topAnchor.constraint(equalTo: header.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: footerContainer.topAnchor),

            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 20),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 20),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -20),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -20),
            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -40),

            footerContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            footerContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            footerContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            footerContainer.heightAnchor.constraint(greaterThanOrEqualToConstant: 64),

            footer.leadingAnchor.constraint(equalTo: footerContainer.leadingAnchor, constant: 16),
            footer.trailingAnchor.constraint(equalTo: footerContainer.trailingAnchor, constant: -16),
            footer.topAnchor.constraint(equalTo: footerContainer.topAnchor, constant: 12),
            footer.bottomAnchor.constraint(equalTo: footerContainer.bottomAnchor, constant: -12)
        ])
    }

    @objc private func openFamily() {
        tabBarController?.selectedIndex = 2
    }

    @objc private func openSettings() {
        tabBarController?.selectedIndex = 3
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateLocationWarning()
    }

    private func updateLocationWarning() {
        // This does NOT request permissions; it only reflects the system Location toggle.
        let enabled = CLLocationManager.locationServicesEnabled()
        locationWarningLabel.text = enabled
            ? "Геолокація увімкнена. Рекомендуємо вимкнути біля позицій."
            : "Геолокація вимкнена. Не використовуй біля позицій."
    }

    @objc private func statusTapped(_ sender: StatusCardView) {
        guard let option = statusCards.first(where: { $0.value == sender })?.key else { return }
        updateStatus(option)
    }

    private func updateStatus(_ status: StatusOption) {
        selectedStatus = status
        statusCards.forEach { option, card in
            card.isSelected = option == status
        }
    }

    @objc private func toggleRecording() {
        if recorder != nil {
            stopRecording()
        } else {
            requestRecordPermissionAndStart()
        }
    }

    private func requestRecordPermissionAndStart() {
        let session = AVAudioSession.sharedInstance()
        session.requestRecordPermission { [weak self] granted in
            DispatchQueue.main.async {
                if granted {
                    self?.startRecording()
                } else {
                    self?.showAlert(title: "Доступ заборонено", message: "Немає доступу до мікрофона.")
                }
            }
        }
    }

    private func startRecording() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
            try session.setActive(true)

            let url = FileManager.default.temporaryDirectory.appendingPathComponent("voice.m4a")
            let settings: [String: Any] = [
                AVFormatIDKey: kAudioFormatMPEG4AAC,
                AVSampleRateKey: 16_000,
                AVNumberOfChannelsKey: 1,
                AVEncoderBitRateKey: 64_000
            ]
            recorder = try AVAudioRecorder(url: url, settings: settings)
            recorder?.delegate = self
            recorder?.record(forDuration: 7)
            recordButton.setTitle("⏹", for: .normal)
            voiceStatusLabel.text = "Запис..."
            recordedVoice = nil
            clearVoiceButton.isHidden = true
        } catch {
            showAlert(title: "Помилка", message: "Не вдалося почати запис.")
        }
    }

    private func stopRecording() {
        recorder?.stop()
        recorder = nil
    }

    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        recordButton.setTitle("🎙️", for: .normal)
        if flag, let data = try? Data(contentsOf: recorder.url) {
            recordedVoice = data
            voiceStatusLabel.text = "Голос записано"
            clearVoiceButton.isHidden = false
        } else {
            voiceStatusLabel.text = ""
        }
    }

    @objc private func clearVoice() {
        recordedVoice = nil
        voiceStatusLabel.text = ""
        clearVoiceButton.isHidden = true
    }

    @objc private func sendCheckin() {
        guard CoreBridge.shared.ensureIdentity() else {
            showAlert(title: "Помилка", message: "Ідентичність недоступна.")
            return
        }

        let statusResult: Int32
        switch selectedStatus {
        case .ok:
            statusResult = CoreBridge.shared.sendStatus(0)
        case .busy:
            statusResult = CoreBridge.shared.sendStatus(1)
        case .later:
            statusResult = CoreBridge.shared.sendStatus(2)
        case .hug:
            statusResult = CoreBridge.shared.sendText("Обійми")
        }

        guard statusResult == 0 else {
            showAlert(title: "Помилка", message: "Не вдалося відправити статус (\(statusResult)).")
            return
        }

        if let text = textField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
           !text.isEmpty {
            let result = CoreBridge.shared.sendText(text)
            if result != 0 {
                showAlert(title: "Помилка", message: "Текст не відправлено (\(result)).")
                return
            }
        }

        if let voice = recordedVoice {
            let result = CoreBridge.shared.sendVoice(voice)
            if result != 0 {
                showAlert(title: "Помилка", message: "Голос не відправлено (\(result)).")
                return
            }
        }

        SettingsStore.shared.lastCheckin = Date().timeIntervalSince1970
        updateLastCheckin()
        textField.text = ""
        clearVoice()

        let success = SuccessViewController()
        success.modalPresentationStyle = .overFullScreen
        present(success, animated: true)
    }

    private func updateLastCheckin() {
        let last = SettingsStore.shared.lastCheckin
        let formatted: String
        if last == 0 {
            formatted = "—"
        } else {
            let date = Date(timeIntervalSince1970: last)
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            formatted = formatter.string(from: date)
        }
        lastCheckinLabel.text = "🕐 Останній раз: \(formatted)"
    }

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

final class StatusCardView: UIControl {
    private let emojiLabel = UILabel()
    private let titleLabel = UILabel()
    private let checkLabel = UILabel()

    init(emoji: String, text: String) {
        super.init(frame: .zero)
        backgroundColor = .yaCard
        layer.cornerRadius = 20
        layer.borderWidth = 2
        layer.borderColor = UIColor.yaBorder.cgColor
        translatesAutoresizingMaskIntoConstraints = false

        emojiLabel.text = emoji
        emojiLabel.font = .systemFont(ofSize: 22)

        titleLabel.text = text
        titleLabel.textColor = .yaTextPrimary
        titleLabel.font = .systemFont(ofSize: 16)

        checkLabel.text = "✓"
        checkLabel.textColor = .yaPrimary
        checkLabel.font = .systemFont(ofSize: 18, weight: .bold)
        checkLabel.isHidden = true

        let stack = UIStackView(arrangedSubviews: [emojiLabel, titleLabel, checkLabel])
        stack.axis = .horizontal
        stack.spacing = 12
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false

        addSubview(stack)
        NSLayoutConstraint.activate([
            heightAnchor.constraint(greaterThanOrEqualToConstant: 56),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12)
        ])
    }

    required init?(coder: NSCoder) { nil }

    override var isSelected: Bool {
        didSet {
            layer.borderColor = (isSelected ? UIColor.yaPrimary : UIColor.yaBorder).cgColor
            checkLabel.isHidden = !isSelected
        }
    }
}
