package app.poruch.ya_ok

import android.os.Bundle
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import androidx.fragment.app.Fragment
import app.poruch.ya_ok.core.CoreGateway
import app.poruch.ya_ok.ui.AppTheme
import app.poruch.ya_ok.ui.FamilyFragment
import app.poruch.ya_ok.ui.InboxFragment
import app.poruch.ya_ok.ui.LockFragment
import app.poruch.ya_ok.ui.MainFragment
import app.poruch.ya_ok.ui.Navigator
import app.poruch.ya_ok.ui.OnboardingFragment
import app.poruch.ya_ok.ui.SettingsFragment
import app.poruch.ya_ok.ui.SuccessFragment
import app.poruch.ya_ok.transport.TransportService
import app.poruch.ya_ok.security.AppLock
import android.Manifest
import android.net.Uri
import androidx.activity.result.contract.ActivityResultContracts
import android.content.pm.PackageManager
import androidx.core.content.ContextCompat
import androidx.biometric.BiometricPrompt

class MainActivity : AppCompatActivity(), Navigator {
    private var permissionsGranted = false
    private var pendingAddContactId: String? = null

    private var isUnlocked: Boolean = false
    private var unlockInProgress: Boolean = false
    private var postUnlockAction: (() -> Unit)? = null

    private companion object {
        private const val LOCK_TAG = "lock_fragment"
    }
    
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

        handleIncomingIntent(intent)
        requestNotificationPermission()
        requestBluetoothPermissions()

        if (savedInstanceState == null) {
            if (CoreGateway.getIdentityId() == null) {
                showOnboarding()
            } else {
                postUnlockAction = { showMain() }
                startUnlockIfNeeded()
            }
        }
    }

    override fun onStart() {
        super.onStart()
        // Re-lock when the app returns from background.
        if (CoreGateway.getIdentityId() != null && !isUnlocked) {
            startUnlockIfNeeded()
        }
    }

    override fun onStop() {
        // Require auth next time we return to foreground.
        if (CoreGateway.getIdentityId() != null) {
            isUnlocked = false
        }
        super.onStop()
    }

    override fun onNewIntent(intent: android.content.Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleIncomingIntent(intent)

        // If we're already running and received a deep link, navigate immediately.
        val addId = pendingAddContactId
        if (!addId.isNullOrBlank()) {
            if (CoreGateway.getIdentityId() == null) {
                showOnboarding()
            } else {
                postUnlockAction = { showFamily(addId) }
                startUnlockIfNeeded()
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
                Manifest.permission.BLUETOOTH_ADVERTISE
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

        // Deep link: open "add contact" flow if requested.
        val addId = pendingAddContactId
        if (!addId.isNullOrBlank()) {
            pendingAddContactId = null
            showFamily(addId)
        }
    }

    override fun showSuccess() {
        showFragment(SuccessFragment(), addToBackStack = true)
    }

    override fun showInbox() {
        showFragment(InboxFragment(), addToBackStack = true)
    }

    override fun showFamily(addContactId: String?) {
        showFragment(FamilyFragment.newInstance(addContactId), addToBackStack = true)
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

    fun retryUnlock() {
        if (CoreGateway.getIdentityId() == null) return
        startUnlockIfNeeded(force = true)
    }

    private fun startUnlockIfNeeded(force: Boolean = false) {
        if (CoreGateway.getIdentityId() == null) return
        if (isUnlocked && !force) {
            hideLockScreen()
            return
        }
        if (unlockInProgress) return
        unlockInProgress = true

        showLockScreen()

        if (!AppLock.isSupported(this)) {
            // Can't prompt (no biometrics / no device credential). Allow app to continue.
            isUnlocked = true
            unlockInProgress = false
            hideLockScreen()
            postUnlockAction?.invoke()
            postUnlockAction = null
            return
        }

        AppLock.authenticate(
            activity = this,
            title = "Розблокувати",
            subtitle = "Підтвердіть біометрією або PIN/паролем телефону",
            onSuccess = {
                isUnlocked = true
                unlockInProgress = false
                hideLockScreen()
                postUnlockAction?.invoke()
                postUnlockAction = null
            },
            onFailureOrError = { errorCode, message ->
                unlockInProgress = false
                // Keep app locked on cancel/error; allow retry from lock screen.
                val isCancel =
                    errorCode == BiometricPrompt.ERROR_USER_CANCELED ||
                        errorCode == BiometricPrompt.ERROR_NEGATIVE_BUTTON ||
                        errorCode == BiometricPrompt.ERROR_CANCELED
                if (!isCancel && !message.isNullOrBlank()) {
                    Toast.makeText(this, message, Toast.LENGTH_SHORT).show()
                }
                showLockScreen()
            }
        )
    }

    private fun showLockScreen() {
        val fm = supportFragmentManager
        if (fm.findFragmentByTag(LOCK_TAG) != null) return
        fm.beginTransaction().apply {
            setReorderingAllowed(true)
            // Add (not replace) so we don't lose current screen state.
            add(R.id.mainContainer, LockFragment(), LOCK_TAG)
            commit()
        }
    }

    private fun hideLockScreen() {
        val fm = supportFragmentManager
        val lock = fm.findFragmentByTag(LOCK_TAG) ?: return
        fm.beginTransaction().apply {
            setReorderingAllowed(true)
            remove(lock)
            commit()
        }
    }

    private fun handleIncomingIntent(intent: android.content.Intent?) {
        val addId = extractAddContactId(intent)
        if (!addId.isNullOrBlank()) {
            pendingAddContactId = addId
        }
    }

    private fun extractAddContactId(intent: android.content.Intent?): String? {
        val data: Uri = intent?.data ?: return null
        
        // Support both yaok:// and https:// schemes
        val isYaok = data.scheme.equals("yaok", ignoreCase = true)
        val isHttps = data.scheme.equals("https", ignoreCase = true) && 
                      data.host.equals("i-am-ok-relay.fly.dev", ignoreCase = true)
        
        if (!isYaok && !isHttps) return null
        
        val path = data.path ?: ""
        if (!path.contains("add", ignoreCase = true) && 
            !data.host.equals("add", ignoreCase = true)) return null
        
        val id = data.getQueryParameter("id") ?: data.lastPathSegment
        val x25519Key = data.getQueryParameter("x")
        val name = data.getQueryParameter("name")
        
        // Store x25519 key and name for later peer sync
        if (!id.isNullOrBlank()) {
            val prefs = getSharedPreferences("ya_ok_pending_peers", MODE_PRIVATE).edit()
            if (!x25519Key.isNullOrBlank()) {
                prefs.putString("peer_key_$id", x25519Key)
            }
            if (!name.isNullOrBlank()) {
                prefs.putString("peer_name_$id", name)
            }
            prefs.apply()
        }
        
        return id?.trim()?.takeIf { it.isNotBlank() }
    }
}
