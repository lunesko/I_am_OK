package app.poruch.ya_ok

import android.os.Bundle
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import androidx.fragment.app.Fragment
import app.poruch.ya_ok.core.CoreGateway
import app.poruch.ya_ok.ui.AppTheme
import app.poruch.ya_ok.ui.FamilyFragment
import app.poruch.ya_ok.ui.InboxFragment
import app.poruch.ya_ok.ui.MainFragment
import app.poruch.ya_ok.ui.Navigator
import app.poruch.ya_ok.ui.OnboardingFragment
import app.poruch.ya_ok.ui.SettingsFragment
import app.poruch.ya_ok.ui.SuccessFragment
import app.poruch.ya_ok.transport.TransportService
import android.Manifest
import androidx.activity.result.contract.ActivityResultContracts
import android.content.pm.PackageManager
import androidx.core.content.ContextCompat

class MainActivity : AppCompatActivity(), Navigator {
    private var permissionsGranted = false
    
    private val notificationPermissionLauncher =
        registerForActivityResult(ActivityResultContracts.RequestPermission()) { }
    private val bluetoothPermissionLauncher =
        registerForActivityResult(ActivityResultContracts.RequestMultiplePermissions()) { granted ->
            permissionsGranted = granted.values.all { it }
            if (permissionsGranted) {
                TransportService.start(this)
            }
        }

    override fun onCreate(savedInstanceState: Bundle?) {
        AppTheme.apply(this)
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main_container)

        val initResult = CoreGateway.init(this)
        if (initResult != 0) {
            Toast.makeText(this, "Core init error ($initResult)", Toast.LENGTH_SHORT).show()
            finish()
            return
        }

        requestNotificationPermission()
        requestBluetoothPermissions()

        if (savedInstanceState == null) {
            if (CoreGateway.getIdentityId() == null) {
                showOnboarding()
            } else {
                showMain()
            }
        }
    }

    private fun requestNotificationPermission() {
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.TIRAMISU) {
            val permission = Manifest.permission.POST_NOTIFICATIONS
            if (ContextCompat.checkSelfPermission(this, permission) != PackageManager.PERMISSION_GRANTED) {
                notificationPermissionLauncher.launch(permission)
            }
        }
    }

    private fun requestBluetoothPermissions() {
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.S) {
            val permissions = arrayOf(
                Manifest.permission.BLUETOOTH_SCAN,
                Manifest.permission.BLUETOOTH_CONNECT,
                Manifest.permission.BLUETOOTH_ADVERTISE,
                Manifest.permission.ACCESS_FINE_LOCATION
            )
            val missing = permissions.filter {
                ContextCompat.checkSelfPermission(this, it) != PackageManager.PERMISSION_GRANTED
            }
            if (missing.isNotEmpty()) {
                bluetoothPermissionLauncher.launch(missing.toTypedArray())
            } else {
                // Permissions already granted
                permissionsGranted = true
                TransportService.start(this)
            }
        } else {
            // Pre-Android 12 - no runtime permissions needed
            permissionsGranted = true
            TransportService.start(this)
        }
    }

    override fun showOnboarding() {
        showFragment(OnboardingFragment(), addToBackStack = false)
    }

    override fun showMain(clearBackStack: Boolean) {
        if (clearBackStack) {
            supportFragmentManager.popBackStack(null, androidx.fragment.app.FragmentManager.POP_BACK_STACK_INCLUSIVE)
        }
        showFragment(MainFragment(), addToBackStack = false)
    }

    override fun showSuccess() {
        showFragment(SuccessFragment(), addToBackStack = true)
    }

    override fun showInbox() {
        showFragment(InboxFragment(), addToBackStack = true)
    }

    override fun showFamily() {
        showFragment(FamilyFragment(), addToBackStack = true)
    }

    override fun showSettings() {
        showFragment(SettingsFragment(), addToBackStack = true)
    }

    override fun navigateBack() {
        onBackPressedDispatcher.onBackPressed()
    }

    private fun showFragment(fragment: Fragment, addToBackStack: Boolean) {
        supportFragmentManager.beginTransaction().apply {
            setReorderingAllowed(true)
            replace(R.id.mainContainer, fragment)
            if (addToBackStack) {
                addToBackStack(fragment::class.java.simpleName)
            }
            commit()
        }
    }
}
