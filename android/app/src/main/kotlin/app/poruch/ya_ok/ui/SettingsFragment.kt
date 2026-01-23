package app.poruch.ya_ok.ui

import android.app.AlertDialog
import android.app.TimePickerDialog
import android.os.Bundle
import android.text.format.DateFormat
import android.view.View
import android.widget.TextView
import android.widget.Toast
import androidx.appcompat.app.AppCompatDelegate
import androidx.fragment.app.Fragment
import app.poruch.ya_ok.R
import app.poruch.ya_ok.data.AppPreferences
import com.google.android.material.switchmaterial.SwitchMaterial
import java.util.Calendar

class SettingsFragment : Fragment(R.layout.fragment_settings) {
    private lateinit var reminderSummary: TextView
    private lateinit var warnSummary: TextView

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)
        view.findViewById<TextView>(R.id.backButton).setOnClickListener {
            (activity as? Navigator)?.navigateBack()
        }

        reminderSummary = view.findViewById(R.id.reminderSummary)
        warnSummary = view.findViewById(R.id.warnSummary)

        view.findViewById<View>(R.id.reminderCard).setOnClickListener { openTimePicker() }
        view.findViewById<View>(R.id.warnCard).setOnClickListener { openWarnPicker() }

        val quietSwitch = view.findViewById<SwitchMaterial>(R.id.quietSwitch)
        quietSwitch.isChecked = AppPreferences.isQuietMode(requireContext())
        quietSwitch.setOnCheckedChangeListener { _, isChecked ->
            AppPreferences.setQuietMode(requireContext(), isChecked)
        }

        val themeSwitch = view.findViewById<SwitchMaterial>(R.id.themeSwitch)
        themeSwitch.isChecked =
            AppPreferences.getThemeMode(requireContext()) == AppCompatDelegate.MODE_NIGHT_YES
        themeSwitch.setOnCheckedChangeListener { _, isChecked ->
            val mode = if (isChecked) AppCompatDelegate.MODE_NIGHT_YES else AppCompatDelegate.MODE_NIGHT_NO
            AppPreferences.setThemeMode(requireContext(), mode)
            AppTheme.apply(requireContext())
            requireActivity().recreate()
        }

        view.findViewById<View>(R.id.supportButton).setOnClickListener {
            Toast.makeText(requireContext(), "Дякуємо за підтримку!", Toast.LENGTH_SHORT).show()
        }

        refreshSummaries()
    }

    private fun refreshSummaries() {
        val minutes = AppPreferences.getReminderMinutes(requireContext())
        reminderSummary.text = getString(R.string.reminder_summary, formatMinutes(minutes))
        warnSummary.text = getString(R.string.warn_summary, AppPreferences.getWarnDays(requireContext()))
    }

    private fun openTimePicker() {
        val minutes = AppPreferences.getReminderMinutes(requireContext())
        val hour = minutes / 60
        val minute = minutes % 60
        val is24 = DateFormat.is24HourFormat(requireContext())
        TimePickerDialog(requireContext(), { _, h, m ->
            val total = h * 60 + m
            AppPreferences.setReminderMinutes(requireContext(), total)
            refreshSummaries()
        }, hour, minute, is24).show()
    }

    private fun openWarnPicker() {
        val options = arrayOf(1, 3, 7)
        val labels = options.map { "$it дні" }.toTypedArray()
        AlertDialog.Builder(requireContext())
            .setTitle(getString(R.string.warn_title))
            .setItems(labels) { _, which ->
                AppPreferences.setWarnDays(requireContext(), options[which])
                refreshSummaries()
            }
            .show()
    }

    private fun formatMinutes(minutes: Int): String {
        val calendar = Calendar.getInstance().apply {
            set(Calendar.HOUR_OF_DAY, minutes / 60)
            set(Calendar.MINUTE, minutes % 60)
        }
        val formatter = DateFormat.getTimeFormat(requireContext())
        return formatter.format(calendar.time)
    }
}
