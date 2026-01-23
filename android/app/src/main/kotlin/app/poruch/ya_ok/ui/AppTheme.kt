package app.poruch.ya_ok.ui

import android.content.Context
import androidx.appcompat.app.AppCompatDelegate
import app.poruch.ya_ok.data.AppPreferences

object AppTheme {
    fun apply(context: Context) {
        val mode = AppPreferences.getThemeMode(context)
        AppCompatDelegate.setDefaultNightMode(mode)
    }
}
