import UIKit

final class RootViewController: UIViewController {
    private var current: UIViewController?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .yaBackground
        CoreBridge.shared.initialize()
        TransportCoordinator.shared.start()
        showInitial()
    }

    private func showInitial() {
        if CoreBridge.shared.getIdentityId() == nil {
            showOnboarding()
        } else {
            showMain()
        }
    }

    private func showOnboarding() {
        let onboarding = OnboardingViewController()
        onboarding.onComplete = { [weak self] in
            self?.showMain()
        }
        setChild(onboarding)
    }

    private func showMain() {
        let tabBar = MainTabBarController()
        setChild(tabBar)
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
}
