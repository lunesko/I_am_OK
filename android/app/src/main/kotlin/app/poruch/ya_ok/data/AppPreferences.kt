package app.poruch.ya_ok.data

import android.content.Context
import androidx.appcompat.app.AppCompatDelegate

object AppPreferences {
    private const val PREFS_NAME = "ya_ok_prefs"
    private const val KEY_THEME_MODE = "theme_mode"
    private const val KEY_LAST_CHECKIN = "last_checkin"
    private const val KEY_REMINDER_MINUTES = "reminder_minutes"
    private const val KEY_WARN_DAYS = "warn_days"
    private const val KEY_QUIET_MODE = "quiet_mode"
    private const val KEY_CONTACTS = "contacts"

    private fun prefs(context: Context) =
        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

    fun getThemeMode(context: Context): Int =
        prefs(context).getInt(KEY_THEME_MODE, AppCompatDelegate.MODE_NIGHT_FOLLOW_SYSTEM)

    fun setThemeMode(context: Context, mode: Int) {
        prefs(context).edit().putInt(KEY_THEME_MODE, mode).apply()
    }

    fun getLastCheckin(context: Context): Long =
        prefs(context).getLong(KEY_LAST_CHECKIN, 0L)

    fun setLastCheckin(context: Context, timeMillis: Long) {
        prefs(context).edit().putLong(KEY_LAST_CHECKIN, timeMillis).apply()
    }

    fun getReminderMinutes(context: Context): Int =
        prefs(context).getInt(KEY_REMINDER_MINUTES, 9 * 60)

    fun setReminderMinutes(context: Context, minutes: Int) {
        prefs(context).edit().putInt(KEY_REMINDER_MINUTES, minutes).apply()
    }

    fun getWarnDays(context: Context): Int =
        prefs(context).getInt(KEY_WARN_DAYS, 3)

    fun setWarnDays(context: Context, days: Int) {
        prefs(context).edit().putInt(KEY_WARN_DAYS, days).apply()
    }

    fun isQuietMode(context: Context): Boolean =
        prefs(context).getBoolean(KEY_QUIET_MODE, false)

    fun setQuietMode(context: Context, enabled: Boolean) {
        prefs(context).edit().putBoolean(KEY_QUIET_MODE, enabled).apply()
    }

    fun getContactsJson(context: Context): String =
        prefs(context).getString(KEY_CONTACTS, "[]") ?: "[]"

    fun setContactsJson(context: Context, json: String) {
        prefs(context).edit().putString(KEY_CONTACTS, json).apply()
    }
}
