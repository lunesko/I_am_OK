import UIKit

extension UIColor {
    static var yaBackground: UIColor {
        UIColor { traits in
            traits.userInterfaceStyle == .dark ? .black : UIColor(red: 0.96, green: 0.96, blue: 0.97, alpha: 1)
        }
    }

    static var yaCard: UIColor {
        UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 1) : .white
        }
    }

    static var yaPrimary: UIColor { UIColor(red: 0.0, green: 0.34, blue: 0.72, alpha: 1) }
    static var yaSuccess: UIColor { UIColor(red: 0.20, green: 0.78, blue: 0.35, alpha: 1) }
    static var yaWarning: UIColor { UIColor(red: 1.0, green: 0.58, blue: 0.0, alpha: 1) }

    static var yaTextPrimary: UIColor {
        UIColor { traits in
            traits.userInterfaceStyle == .dark ? .white : .black
        }
    }

    static var yaTextSecondary: UIColor {
        UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(white: 0.6, alpha: 1) : UIColor(white: 0.4, alpha: 1)
        }
    }

    static var yaBorder: UIColor {
        UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(white: 0.22, alpha: 1) : UIColor(white: 0.9, alpha: 1)
        }
    }
}
