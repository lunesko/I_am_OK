import UIKit
import LocalAuthentication

final class RootViewController: UIViewController {
    private var current: UIViewController?
    private var isUnlocked: Bool = false
    private var unlockInProgress: Bool = false
    private var pendingAddContactId: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .yaBackground
        CoreBridge.shared.initialize()
        TransportCoordinator.shared.start()
        showInitial()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }

    private func showInitial() {
        if CoreBridge.shared.getIdentityId() == nil {
            showOnboarding()
        } else {
            showLockedAndAuthenticate()
        }
    }

    private func showOnboarding() {
        let onboarding = OnboardingViewController()
        onboarding.onComplete = { [weak self] in
            self?.isUnlocked = true
            self?.showMain()
        }
        setChild(onboarding)
    }

    private func showMain() {
        let tabBar = MainTabBarController()
        setChild(tabBar)

        if let id = pendingAddContactId {
            pendingAddContactId = nil
            openAddContact(id: id)
        }
    }

    private func showLockedAndAuthenticate() {
        if unlockInProgress { return }
        unlockInProgress = true

        let lock = LockedViewController()
        lock.onUnlock = { [weak self] in
            self?.authenticate()
        }
        setChild(lock)
        authenticate()
    }

    private func authenticate() {
        let context = LAContext()
        context.localizedCancelTitle = "Скасувати"

        var error: NSError?
        let can = context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error)
        guard can else {
            // If device doesn't support passcode/biometrics, allow app to continue.
            isUnlocked = true
            unlockInProgress = false
            showMain()
            return
        }

        context.evaluatePolicy(
            .deviceOwnerAuthentication,
            localizedReason: "Підтвердіть біометрією або PIN/паролем телефону"
        ) { [weak self] success, _ in
            DispatchQueue.main.async {
                guard let self else { return }
                self.unlockInProgress = false
                if success {
                    self.isUnlocked = true
                    self.showMain()
                } else {
                    self.isUnlocked = false
                    self.showLockedAndAuthenticate()
                }
            }
        }
    }

    @objc private func appWillEnterForeground() {
        guard CoreBridge.shared.getIdentityId() != nil else { return }
        isUnlocked = false
        showLockedAndAuthenticate()
    }

    func handleIncomingUrl(_ url: URL) {
        guard url.scheme?.lowercased() == "yaok" else { return }
        guard url.host?.lowercased() == "add" else { return }
        let comps = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let id = comps?.queryItems?.first(where: { $0.name == "id" })?.value
        let x = comps?.queryItems?.first(where: { $0.name == "x" })?.value
        guard let contactId = id?.trimmingCharacters(in: .whitespacesAndNewlines),
              !contactId.isEmpty else { return }

        // If QR/deeplink includes X25519 public key, register it in core for E2E packet encryption.
        if let x = x?.trimmingCharacters(in: .whitespacesAndNewlines), !x.isEmpty {
            _ = CoreBridge.shared.addPeer(peerId: contactId, x25519PublicKeyHex: x)
        }

        pendingAddContactId = contactId

        if CoreBridge.shared.getIdentityId() == nil {
            showOnboarding()
            return
        }

        if isUnlocked {
            showMain()
        } else {
            showLockedAndAuthenticate()
        }
    }

    private func openAddContact(id: String) {
        guard let tabBar = current as? MainTabBarController else { return }
        guard let viewControllers = tabBar.viewControllers, viewControllers.count > 2 else { return }
        tabBar.selectedIndex = 2

        DispatchQueue.main.async {
            guard let nav = tabBar.viewControllers?[2] as? UINavigationController,
                  let family = nav.viewControllers.first as? FamilyViewController else {
                return
            }
            family.openAddContact(prefillId: id)
        }
    }

    private func setChild(_ controller: UIViewController) {
        current?.willMove(toParent: nil)
        current?.view.removeFromSuperview()
        current?.removeFromParent()

        addChild(controller)
        controller.view.frame = view.bounds
        controller.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(controller.view)
        controller.didMove(toParent: self)
        current = controller
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

private final class LockedViewController: UIViewController {
    var onUnlock: (() -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .yaBackground

        let title = UILabel()
        title.text = "🔒"
        title.font = .systemFont(ofSize: 48)
        title.translatesAutoresizingMaskIntoConstraints = false

        let text = UILabel()
        text.text = "Додаток заблоковано"
        text.font = .systemFont(ofSize: 18, weight: .bold)
        text.textColor = .yaTextPrimary
        text.translatesAutoresizingMaskIntoConstraints = false

        let button = UIButton(type: .system)
        button.setTitle("Розблокувати", for: .normal)
        button.backgroundColor = .yaSuccess
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 16
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .bold)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.heightAnchor.constraint(equalToConstant: 52).isActive = true
        button.addTarget(self, action: #selector(unlockTapped), for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [title, text, button])
        stack.axis = .vertical
        stack.spacing = 16
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            button.widthAnchor.constraint(equalTo: stack.widthAnchor)
        ])
    }

    @objc private func unlockTapped() {
        onUnlock?()
    }
}
