import UIKit

final class MainTabBarController: UITabBarController {
    override func viewDidLoad() {
        super.viewDidLoad()

        let main = UINavigationController(rootViewController: MainViewController())
        main.navigationBar.isHidden = true
        main.tabBarItem = UITabBarItem(title: "Я ОК", image: nil, selectedImage: nil)

        let inbox = UINavigationController(rootViewController: InboxViewController())
        inbox.navigationBar.isHidden = true
        inbox.tabBarItem = UITabBarItem(title: "Вхідні", image: nil, selectedImage: nil)

        let family = UINavigationController(rootViewController: FamilyViewController())
        family.navigationBar.isHidden = true
        family.tabBarItem = UITabBarItem(title: "Мої люди", image: nil, selectedImage: nil)

        let settings = UINavigationController(rootViewController: SettingsViewController())
        settings.navigationBar.isHidden = true
        settings.tabBarItem = UITabBarItem(title: "Налаштування", image: nil, selectedImage: nil)

        viewControllers = [main, inbox, family, settings]
        tabBar.tintColor = .yaPrimary
        tabBar.backgroundColor = .yaCard
    }
}
