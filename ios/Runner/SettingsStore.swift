import Foundation

final class SettingsStore {
    static let shared = SettingsStore()
    private let defaults = UserDefaults.standard

    private init() {}

    private enum Keys {
        static let lastCheckin = "ya_ok_last_checkin"
        static let reminderMinutes = "ya_ok_reminder_minutes"
        static let warnDays = "ya_ok_warn_days"
        static let quietMode = "ya_ok_quiet_mode"
        static let darkMode = "ya_ok_dark_mode"
    }

    var lastCheckin: TimeInterval {
        get { defaults.double(forKey: Keys.lastCheckin) }
        set { defaults.set(newValue, forKey: Keys.lastCheckin) }
    }

    var reminderMinutes: Int {
        get {
            let value = defaults.integer(forKey: Keys.reminderMinutes)
            return value == 0 ? 9 * 60 : value
        }
        set { defaults.set(newValue, forKey: Keys.reminderMinutes) }
    }

    var warnDays: Int {
        get {
            let value = defaults.integer(forKey: Keys.warnDays)
            return value == 0 ? 3 : value
        }
        set { defaults.set(newValue, forKey: Keys.warnDays) }
    }

    var quietMode: Bool {
        get { defaults.bool(forKey: Keys.quietMode) }
        set { defaults.set(newValue, forKey: Keys.quietMode) }
    }

    var darkMode: Bool {
        get { defaults.bool(forKey: Keys.darkMode) }
        set { defaults.set(newValue, forKey: Keys.darkMode) }
    }
}
