import UIKit

final class SettingsViewController: UIViewController {
    private let supportUrl = URL(string: "https://buymeacoffee.com/lunesko")
    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private let reminderSummary = UILabel()
    private let warnSummary = UILabel()
    private let quietSwitch = UISwitch()
    private let themeSwitch = UISwitch()
    private let wipeTitle = "Екстрене очищення"
    private let wipeMessage = "Це видалить локальні дані на цьому пристрої та поверне до онбордингу. Продовжити?"

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .yaBackground
        setupLayout()
        refreshSummaries()
    }

    private func setupLayout() {
        let header = UIView()
        header.backgroundColor = .yaCard
        header.translatesAutoresizingMaskIntoConstraints = false

        let titleLabel = UILabel()
        titleLabel.text = "Налаштування"
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

        let reminderCard = makeSettingCard(icon: "🔔", title: "Нагадувати мені", summaryLabel: reminderSummary)
        reminderCard.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(openReminderPicker)))
        contentStack.addArrangedSubview(reminderCard)

        let warnCard = makeSettingCard(icon: "⚠️", title: "Попередити близьких", summaryLabel: warnSummary)
        warnCard.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(openWarnPicker)))
        contentStack.addArrangedSubview(warnCard)

        let quietCard = makeToggleCard(icon: "🌙", title: "Тихий режим", summary: "Без звуку вночі", toggle: quietSwitch)
        quietSwitch.isOn = SettingsStore.shared.quietMode
        quietSwitch.addTarget(self, action: #selector(toggleQuietMode), for: .valueChanged)
        contentStack.addArrangedSubview(quietCard)

        let themeCard = makeToggleCard(icon: "🎨", title: "Темна тема", summary: nil, toggle: themeSwitch)
        themeSwitch.isOn = SettingsStore.shared.darkMode
        themeSwitch.addTarget(self, action: #selector(toggleTheme), for: .valueChanged)
        contentStack.addArrangedSubview(themeCard)

        let supportCard = UIView()
        supportCard.backgroundColor = .yaPrimary
        supportCard.layer.cornerRadius = 20
        supportCard.translatesAutoresizingMaskIntoConstraints = false

        let supportStack = UIStackView()
        supportStack.axis = .vertical
        supportStack.spacing = 8
        supportStack.translatesAutoresizingMaskIntoConstraints = false

        let heart = UILabel()
        heart.text = "❤️"
        heart.font = .systemFont(ofSize: 26)

        let supportTitle = UILabel()
        supportTitle.text = "Підтримати проєкт"
        supportTitle.font = .systemFont(ofSize: 18, weight: .bold)
        supportTitle.textColor = .white

        let supportDesc = UILabel()
        supportDesc.text = "Я ОК — безкоштовний для військових та їх родин"
        supportDesc.font = .systemFont(ofSize: 13)
        supportDesc.textColor = .white
        supportDesc.numberOfLines = 0

        let supportButton = UIButton(type: .system)
        supportButton.setTitle("Задонатити на ЗСУ", for: .normal)
        supportButton.backgroundColor = .white
        supportButton.setTitleColor(.yaPrimary, for: .normal)
        supportButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .bold)
        supportButton.layer.cornerRadius = 12
        supportButton.heightAnchor.constraint(equalToConstant: 44).isActive = true
        supportButton.addTarget(self, action: #selector(openSupportLink), for: .touchUpInside)

        supportStack.addArrangedSubview(heart)
        supportStack.addArrangedSubview(supportTitle)
        supportStack.addArrangedSubview(supportDesc)
        supportStack.addArrangedSubview(supportButton)
        supportCard.addSubview(supportStack)
        NSLayoutConstraint.activate([
            supportStack.leadingAnchor.constraint(equalTo: supportCard.leadingAnchor, constant: 16),
            supportStack.trailingAnchor.constraint(equalTo: supportCard.trailingAnchor, constant: -16),
            supportStack.topAnchor.constraint(equalTo: supportCard.topAnchor, constant: 16),
            supportStack.bottomAnchor.constraint(equalTo: supportCard.bottomAnchor, constant: -16)
        ])
        contentStack.addArrangedSubview(supportCard)

        let wipeCard = UIView()
        wipeCard.backgroundColor = .yaCard
        wipeCard.layer.cornerRadius = 16
        wipeCard.layer.borderWidth = 1
        wipeCard.layer.borderColor = UIColor.yaBorder.cgColor
        wipeCard.translatesAutoresizingMaskIntoConstraints = false
        wipeCard.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(confirmWipe)))

        let wipeIcon = UILabel()
        wipeIcon.text = "🧨"
        wipeIcon.font = .systemFont(ofSize: 16)
        wipeIcon.backgroundColor = .yaBackground
        wipeIcon.textAlignment = .center
        wipeIcon.layer.cornerRadius = 10
        wipeIcon.clipsToBounds = true
        wipeIcon.translatesAutoresizingMaskIntoConstraints = false
        wipeIcon.widthAnchor.constraint(equalToConstant: 40).isActive = true
        wipeIcon.heightAnchor.constraint(equalToConstant: 40).isActive = true

        let wipeTitleLabel = UILabel()
        wipeTitleLabel.text = wipeTitle
        wipeTitleLabel.font = .systemFont(ofSize: 16, weight: .bold)
        wipeTitleLabel.textColor = .yaTextPrimary

        let wipeDescLabel = UILabel()
        wipeDescLabel.text = "Видалити локальні дані (ID, базу, контакти)"
        wipeDescLabel.font = .systemFont(ofSize: 13)
        wipeDescLabel.textColor = .yaTextSecondary
        wipeDescLabel.numberOfLines = 0

        let wipeInfo = UIStackView(arrangedSubviews: [wipeTitleLabel, wipeDescLabel])
        wipeInfo.axis = .vertical
        wipeInfo.spacing = 2

        let arrow = UILabel()
        arrow.text = "›"
        arrow.font = .systemFont(ofSize: 18)
        arrow.textColor = .yaTextSecondary

        let wipeRow = UIStackView(arrangedSubviews: [wipeIcon, wipeInfo, arrow])
        wipeRow.axis = .horizontal
        wipeRow.spacing = 12
        wipeRow.alignment = .center
        wipeRow.translatesAutoresizingMaskIntoConstraints = false

        wipeCard.addSubview(wipeRow)
        NSLayoutConstraint.activate([
            wipeRow.leadingAnchor.constraint(equalTo: wipeCard.leadingAnchor, constant: 16),
            wipeRow.trailingAnchor.constraint(equalTo: wipeCard.trailingAnchor, constant: -16),
            wipeRow.topAnchor.constraint(equalTo: wipeCard.topAnchor, constant: 12),
            wipeRow.bottomAnchor.constraint(equalTo: wipeCard.bottomAnchor, constant: -12)
        ])
        contentStack.addArrangedSubview(wipeCard)

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

    private func makeSettingCard(icon: String, title: String, summaryLabel: UILabel) -> UIView {
        let card = UIView()
        card.backgroundColor = .yaCard
        card.layer.cornerRadius = 16
        card.layer.borderWidth = 1
        card.layer.borderColor = UIColor.yaBorder.cgColor
        card.translatesAutoresizingMaskIntoConstraints = false

        let iconLabel = UILabel()
        iconLabel.text = icon
        iconLabel.font = .systemFont(ofSize: 16)
        iconLabel.backgroundColor = .yaBackground
        iconLabel.textAlignment = .center
        iconLabel.layer.cornerRadius = 10
        iconLabel.clipsToBounds = true
        iconLabel.translatesAutoresizingMaskIntoConstraints = false
        iconLabel.widthAnchor.constraint(equalToConstant: 40).isActive = true
        iconLabel.heightAnchor.constraint(equalToConstant: 40).isActive = true

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 16, weight: .bold)
        titleLabel.textColor = .yaTextPrimary

        summaryLabel.font = .systemFont(ofSize: 13)
        summaryLabel.textColor = .yaTextSecondary

        let infoStack = UIStackView(arrangedSubviews: [titleLabel, summaryLabel])
        infoStack.axis = .vertical
        infoStack.spacing = 2

        let arrow = UILabel()
        arrow.text = "›"
        arrow.font = .systemFont(ofSize: 18)
        arrow.textColor = .yaTextSecondary

        let row = UIStackView(arrangedSubviews: [iconLabel, infoStack, arrow])
        row.axis = .horizontal
        row.spacing = 12
        row.alignment = .center
        row.translatesAutoresizingMaskIntoConstraints = false

        card.addSubview(row)
        NSLayoutConstraint.activate([
            row.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            row.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            row.topAnchor.constraint(equalTo: card.topAnchor, constant: 12),
            row.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -12)
        ])
        return card
    }

    private func makeToggleCard(icon: String, title: String, summary: String?, toggle: UISwitch) -> UIView {
        let card = UIView()
        card.backgroundColor = .yaCard
        card.layer.cornerRadius = 16
        card.layer.borderWidth = 1
        card.layer.borderColor = UIColor.yaBorder.cgColor
        card.translatesAutoresizingMaskIntoConstraints = false

        let iconLabel = UILabel()
        iconLabel.text = icon
        iconLabel.font = .systemFont(ofSize: 16)
        iconLabel.backgroundColor = .yaBackground
        iconLabel.textAlignment = .center
        iconLabel.layer.cornerRadius = 10
        iconLabel.clipsToBounds = true
        iconLabel.translatesAutoresizingMaskIntoConstraints = false
        iconLabel.widthAnchor.constraint(equalToConstant: 40).isActive = true
        iconLabel.heightAnchor.constraint(equalToConstant: 40).isActive = true

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 16, weight: .bold)
        titleLabel.textColor = .yaTextPrimary

        let summaryLabel = UILabel()
        summaryLabel.text = summary
        summaryLabel.font = .systemFont(ofSize: 13)
        summaryLabel.textColor = .yaTextSecondary
        summaryLabel.isHidden = summary == nil

        let infoStack = UIStackView(arrangedSubviews: [titleLabel, summaryLabel])
        infoStack.axis = .vertical
        infoStack.spacing = 2

        let row = UIStackView(arrangedSubviews: [iconLabel, infoStack, toggle])
        row.axis = .horizontal
        row.spacing = 12
        row.alignment = .center
        row.translatesAutoresizingMaskIntoConstraints = false

        card.addSubview(row)
        NSLayoutConstraint.activate([
            row.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            row.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            row.topAnchor.constraint(equalTo: card.topAnchor, constant: 12),
            row.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -12)
        ])
        return card
    }

    private func refreshSummaries() {
        let minutes = SettingsStore.shared.reminderMinutes
        reminderSummary.text = "Кожен день о \(format(minutes: minutes))"
        warnSummary.text = "\(SettingsStore.shared.warnDays) дні без зв'язку"
    }

    @objc private func openReminderPicker() {
        let alert = UIAlertController(title: "Нагадування", message: "\n\n\n\n\n\n", preferredStyle: .actionSheet)
        let picker = UIDatePicker()
        picker.datePickerMode = .time
        picker.preferredDatePickerStyle = .wheels
        let minutes = SettingsStore.shared.reminderMinutes
        var components = DateComponents()
        components.hour = minutes / 60
        components.minute = minutes % 60
        picker.date = Calendar.current.date(from: components) ?? Date()
        picker.frame = CGRect(x: 0, y: 20, width: alert.view.bounds.width - 20, height: 160)
        alert.view.addSubview(picker)
        alert.addAction(UIAlertAction(title: "Зберегти", style: .default, handler: { _ in
            let comps = Calendar.current.dateComponents([.hour, .minute], from: picker.date)
            let total = (comps.hour ?? 0) * 60 + (comps.minute ?? 0)
            SettingsStore.shared.reminderMinutes = total
            self.refreshSummaries()
        }))
        alert.addAction(UIAlertAction(title: "Скасувати", style: .cancel))
        present(alert, animated: true)
    }

    @objc private func openWarnPicker() {
        let options = [1, 3, 7]
        let alert = UIAlertController(title: "Попередити близьких", message: nil, preferredStyle: .actionSheet)
        options.forEach { days in
            alert.addAction(UIAlertAction(title: "\(days) дні", style: .default, handler: { _ in
                SettingsStore.shared.warnDays = days
                self.refreshSummaries()
            }))
        }
        alert.addAction(UIAlertAction(title: "Скасувати", style: .cancel))
        present(alert, animated: true)
    }

    @objc private func toggleQuietMode() {
        SettingsStore.shared.quietMode = quietSwitch.isOn
    }

    @objc private func toggleTheme() {
        SettingsStore.shared.darkMode = themeSwitch.isOn
        view.window?.overrideUserInterfaceStyle = themeSwitch.isOn ? .dark : .light
    }

    @objc private func openSupportLink() {
        guard let url = supportUrl else {
            let alert = UIAlertController(title: nil, message: "Помилка посилання підтримки", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }

    @objc private func confirmWipe() {
        let alert = UIAlertController(title: wipeTitle, message: wipeMessage, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Скасувати", style: .cancel))
        alert.addAction(UIAlertAction(title: "Як видалити додаток", style: .default, handler: { [weak self] _ in
            self?.showUninstallHelp()
        }))
        alert.addAction(UIAlertAction(title: "Очистити", style: .destructive, handler: { [weak self] _ in
            self?.performWipe()
        }))
        present(alert, animated: true)
    }

    private func showUninstallHelp() {
        let msg = "iOS не дозволяє видаляти додатки програмно.\n\nШвидке видалення:\nНалаштування → Основні → Сховище iPhone → Ya Ok → Видалити додаток."
        let alert = UIAlertController(title: "Видалення додатку", message: msg, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    private func performWipe() {
        TransportCoordinator.shared.stop()

        // Clear app preferences & cached models.
        if let bundleId = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundleId)
            UserDefaults.standard.synchronize()
        }

        // Best-effort delete Application Support directory (core data lives there).
        if let baseUrl = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            try? FileManager.default.removeItem(at: baseUrl)
        }

        let result = CoreBridge.shared.wipeLocalData()
        if result != 0 {
            let alert = UIAlertController(title: nil, message: "Помилка очищення (\(result))", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }

        // Restart UI flow.
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            appDelegate.window?.rootViewController = RootViewController()
            appDelegate.window?.overrideUserInterfaceStyle = SettingsStore.shared.darkMode ? .dark : .light
            appDelegate.window?.makeKeyAndVisible()
        }
    }

    private func format(minutes: Int) -> String {
        let hours = minutes / 60
        let mins = minutes % 60
        return String(format: "%02d:%02d", hours, mins)
    }
}
