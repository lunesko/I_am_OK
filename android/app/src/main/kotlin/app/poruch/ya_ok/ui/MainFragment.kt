package app.poruch.ya_ok.ui

import android.Manifest
import android.bluetooth.BluetoothAdapter
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.location.LocationManager
import android.media.MediaPlayer
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.os.Bundle
import android.os.CountDownTimer
import android.text.format.DateFormat
import android.view.View
import android.widget.TextView
import android.widget.Toast
import androidx.activity.result.contract.ActivityResultContracts
import androidx.appcompat.app.AlertDialog
import androidx.core.content.ContextCompat
import androidx.fragment.app.Fragment
import app.poruch.ya_ok.R
import app.poruch.ya_ok.core.CoreGateway
import app.poruch.ya_ok.data.AppPreferences
import app.poruch.ya_ok.util.LocationUtils
import app.poruch.ya_ok.voice.VoiceRecorder
import com.google.android.material.button.MaterialButton
import com.google.android.material.card.MaterialCardView
import com.google.android.material.textfield.TextInputEditText
import java.util.Date

class MainFragment : Fragment(R.layout.fragment_main) {
    private enum class StatusOption { OK, BUSY, LATER, HUG }
    private companion object {
        private const val MAX_VOICE_BYTES = 56_000
        private const val CONNECTION_STATUS_UPDATE_INTERVAL = 5000L // 5 seconds
        private const val TRUNCATED_ID_LENGTH = 6
        private const val PENDING_PACKETS_SAMPLE_SIZE = 10
    }

    private lateinit var statusOkCard: MaterialCardView
    private lateinit var statusBusyCard: MaterialCardView
    private lateinit var statusLaterCard: MaterialCardView
    private lateinit var statusHugCard: MaterialCardView
    private lateinit var statusOkCheck: TextView
    private lateinit var statusBusyCheck: TextView
    private lateinit var statusLaterCheck: TextView
    private lateinit var statusHugCheck: TextView
    private lateinit var textInput: TextInputEditText
    private lateinit var recordVoiceButton: MaterialButton
    private lateinit var playVoiceButton: MaterialButton
    private lateinit var clearVoiceButton: MaterialButton
    private lateinit var voiceStatus: TextView
    private lateinit var lastCheckin: TextView
    private lateinit var locationWarningText: TextView
    private lateinit var bluetoothStatusIcon: TextView
    private lateinit var bluetoothStatusText: TextView
    private lateinit var meshStatusIcon: TextView
    private lateinit var meshStatusText: TextView
    private lateinit var internetStatusIcon: TextView
    private lateinit var internetStatusText: TextView

    private var locationReceiver: BroadcastReceiver? = null
    private var locationReceiverRegistered: Boolean = false

    private var selectedStatus = StatusOption.OK
    private var recordedVoice: ByteArray? = null
    private var recordedVoiceFile: java.io.File? = null
    private var voiceRecorder: VoiceRecorder? = null
    private var countdown: CountDownTimer? = null
    private var mediaPlayer: MediaPlayer? = null
    
    private val handler = android.os.Handler(android.os.Looper.getMainLooper())
    private val connectionStatusUpdateRunnable = object : Runnable {
        override fun run() {
            updateConnectionStatus()
            handler.postDelayed(this, CONNECTION_STATUS_UPDATE_INTERVAL)
        }
    }

    private val micPermissionLauncher =
        registerForActivityResult(ActivityResultContracts.RequestPermission()) { granted ->
            if (granted) {
                startRecording()
            } else {
                Toast.makeText(requireContext(), "Потрібен доступ до мікрофона", Toast.LENGTH_SHORT)
                    .show()
            }
        }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)
        voiceRecorder = VoiceRecorder(requireContext())

        view.findViewById<TextView>(R.id.familyButton).setOnClickListener {
            (activity as? Navigator)?.showFamily()
        }
        view.findViewById<TextView>(R.id.inboxButton).setOnClickListener {
            (activity as? Navigator)?.showInbox()
        }
        view.findViewById<TextView>(R.id.settingsButton).setOnClickListener {
            (activity as? Navigator)?.showSettings()
        }

        statusOkCard = view.findViewById(R.id.statusOkCard)
        statusBusyCard = view.findViewById(R.id.statusBusyCard)
        statusLaterCard = view.findViewById(R.id.statusLaterCard)
        statusHugCard = view.findViewById(R.id.statusHugCard)
        statusOkCheck = view.findViewById(R.id.statusOkCheck)
        statusBusyCheck = view.findViewById(R.id.statusBusyCheck)
        statusLaterCheck = view.findViewById(R.id.statusLaterCheck)
        statusHugCheck = view.findViewById(R.id.statusHugCheck)

        statusOkCard.setOnClickListener { updateStatus(StatusOption.OK) }
        statusBusyCard.setOnClickListener { updateStatus(StatusOption.BUSY) }
        statusLaterCard.setOnClickListener { updateStatus(StatusOption.LATER) }
        statusHugCard.setOnClickListener { updateStatus(StatusOption.HUG) }
        updateStatus(StatusOption.OK)

        textInput = view.findViewById(R.id.textInput)
        recordVoiceButton = view.findViewById(R.id.recordVoiceButton)
        playVoiceButton = view.findViewById(R.id.playVoiceButton)
        clearVoiceButton = view.findViewById(R.id.clearVoiceButton)
        voiceStatus = view.findViewById(R.id.voiceStatus)
        lastCheckin = view.findViewById(R.id.lastCheckin)
        locationWarningText = view.findViewById(R.id.locationWarningText)
        bluetoothStatusIcon = view.findViewById(R.id.bluetoothStatusIcon)
        bluetoothStatusText = view.findViewById(R.id.bluetoothStatusText)
        meshStatusIcon = view.findViewById(R.id.meshStatusIcon)
        meshStatusText = view.findViewById(R.id.meshStatusText)
        internetStatusIcon = view.findViewById(R.id.internetStatusIcon)
        internetStatusText = view.findViewById(R.id.internetStatusText)

        recordVoiceButton.setOnClickListener {
            if (voiceRecorder?.isRecording == true) {
                stopRecording()
            } else {
                requestMicPermission()
            }
        }

        playVoiceButton.setOnClickListener {
            togglePlayback()
        }

        clearVoiceButton.setOnClickListener {
            // Re-record: discard current clip and start recording again
            stopPlayback()
            discardRecordedVoice()
            requestMicPermission()
        }

        view.findViewById<MaterialButton>(R.id.sendButton).setOnClickListener {
            sendCheckin()
        }

        updateLastCheckin()
        updateLocationWarning()
        updateConnectionStatus()
    }

    override fun onStart() {
        super.onStart()
        registerLocationReceiverIfNeeded()
        updateLocationWarning()
        updateConnectionStatus()
        // Start periodic connection status updates
        handler.post(connectionStatusUpdateRunnable)
    }

    override fun onStop() {
        // Stop periodic updates
        handler.removeCallbacks(connectionStatusUpdateRunnable)
        unregisterLocationReceiverIfNeeded()
        super.onStop()
    }

    override fun onDestroyView() {
        super.onDestroyView()
        countdown?.cancel()
        stopPlayback()
        voiceRecorder?.cancel()
        voiceRecorder = null
    }

    private fun registerLocationReceiverIfNeeded() {
        if (locationReceiverRegistered) return
        val receiver = locationReceiver ?: object : BroadcastReceiver() {
            override fun onReceive(context: android.content.Context, intent: Intent) {
                when (intent.action) {
                    LocationManager.MODE_CHANGED_ACTION,
                    LocationManager.PROVIDERS_CHANGED_ACTION -> updateLocationWarning()
                }
            }
        }.also { locationReceiver = it }

        val filter = IntentFilter().apply {
            addAction(LocationManager.MODE_CHANGED_ACTION)
            addAction(LocationManager.PROVIDERS_CHANGED_ACTION)
        }
        ContextCompat.registerReceiver(
            requireContext(),
            receiver,
            filter,
            ContextCompat.RECEIVER_NOT_EXPORTED
        )
        locationReceiverRegistered = true
    }

    private fun unregisterLocationReceiverIfNeeded() {
        if (!locationReceiverRegistered) return
        val receiver = locationReceiver ?: return
        runCatching { requireContext().unregisterReceiver(receiver) }
        locationReceiverRegistered = false
    }

    private fun updateLocationWarning() {
        if (!this::locationWarningText.isInitialized) return
        val enabled = LocationUtils.isLocationEnabled(requireContext())
        locationWarningText.setText(if (enabled) R.string.warning_geo_on else R.string.warning_no_geo)
    }
    
    private fun updateConnectionStatus() {
        if (!this::bluetoothStatusIcon.isInitialized) return
        if (!isAdded || context == null) return
        
        println("🔍 === CONNECTION STATUS UPDATE ===")
        
        val bluetoothEnabled = isBluetoothEnabled()
        val hasInternet = hasInternetConnection()
        val peerCount = getPeerCount()
        
        updateBluetoothIndicator(bluetoothEnabled)
        updateMeshIndicator(peerCount)
        updateInternetIndicator(hasInternet)
        
        println("📊 Status: BT=$bluetoothEnabled, Mesh=$peerCount, Internet=$hasInternet")
        println("🔍 === CONNECTION STATUS END ===")
    }
    
    private fun updateBluetoothIndicator(enabled: Boolean) {
        bluetoothStatusIcon.text = if (enabled) "📶" else "📵"
        bluetoothStatusText.text = if (enabled) "Bluetooth" else "Bluetooth OFF"
        bluetoothStatusText.setTextColor(
            ContextCompat.getColor(
                requireContext(),
                if (enabled) R.color.success else R.color.text_secondary
            )
        )
    }

    private fun updateMeshIndicator(peerCount: Int) {
        meshStatusIcon.text = if (peerCount > 0) "🔗" else "⛓️‍💥"
        meshStatusText.text = "Mesh ($peerCount)"
        meshStatusText.setTextColor(
            ContextCompat.getColor(
                requireContext(),
                if (peerCount > 0) R.color.success else R.color.text_secondary
            )
        )
    }

    private fun updateInternetIndicator(hasInternet: Boolean) {
        internetStatusIcon.text = if (hasInternet) "🌐" else "🚫"
        internetStatusText.text = if (hasInternet) "Relay" else "Relay OFF"
        internetStatusText.setTextColor(
            ContextCompat.getColor(
                requireContext(),
                if (hasInternet) R.color.success else R.color.text_secondary
            )
        )
    }

    private fun updateStatus(status: StatusOption) {
        selectedStatus = status
        val selectedColor = ContextCompat.getColor(requireContext(), R.color.primary)
        val borderColor = ContextCompat.getColor(requireContext(), R.color.border)

        fun apply(card: MaterialCardView, check: TextView, active: Boolean) {
            card.strokeColor = if (active) selectedColor else borderColor
            check.visibility = if (active) View.VISIBLE else View.INVISIBLE
        }

        apply(statusOkCard, statusOkCheck, status == StatusOption.OK)
        apply(statusBusyCard, statusBusyCheck, status == StatusOption.BUSY)
        apply(statusLaterCard, statusLaterCheck, status == StatusOption.LATER)
        apply(statusHugCard, statusHugCheck, status == StatusOption.HUG)
    }

    private fun requestMicPermission() {
        val permission = Manifest.permission.RECORD_AUDIO
        if (ContextCompat.checkSelfPermission(requireContext(), permission) ==
            android.content.pm.PackageManager.PERMISSION_GRANTED
        ) {
            startRecording()
        } else {
            micPermissionLauncher.launch(permission)
        }
    }

    private fun startRecording() {
        stopPlayback()
        // discard previous clip BEFORE starting new recording (so we don't delete active file)
        discardRecordedVoice()

        val started = voiceRecorder?.start() == true
        if (!started) {
            Toast.makeText(requireContext(), "Не вдалося почати запис", Toast.LENGTH_SHORT).show()
            return
        }
        recordVoiceButton.text = "⏹"
        voiceStatus.text = "00:07"

        countdown?.cancel()
        countdown = object : CountDownTimer(7_000, 1_000) {
            override fun onTick(millisUntilFinished: Long) {
                val seconds = (millisUntilFinished / 1000) + 1
                voiceStatus.text = "00:0$seconds"
            }

            override fun onFinish() {
                stopRecording()
            }
        }.start()
    }

    private fun stopRecording() {
        countdown?.cancel()
        val file = voiceRecorder?.stop()
        recordVoiceButton.text = "🎙️"

        if (file == null || !file.exists() || file.length() == 0L) {
            voiceStatus.text = ""
            Toast.makeText(requireContext(), "Запис не збережено", Toast.LENGTH_SHORT).show()
            return
        }

        recordedVoiceFile = file
        recordedVoice = runCatching { file.readBytes() }.getOrNull()
        if (recordedVoice == null || recordedVoice?.isEmpty() == true) {
            discardRecordedVoice()
            Toast.makeText(requireContext(), "Запис не збережено", Toast.LENGTH_SHORT).show()
            return
        }
        if ((recordedVoice?.size ?: 0) > MAX_VOICE_BYTES) {
            discardRecordedVoice()
            Toast.makeText(requireContext(), "Голос занадто довгий, перезапишіть", Toast.LENGTH_SHORT).show()
            return
        }
        voiceStatus.text = getString(R.string.voice_ready)
        playVoiceButton.visibility = View.VISIBLE
        playVoiceButton.text = "▶️"
        clearVoiceButton.visibility = View.VISIBLE
    }

    private fun sendCheckin() {
        if (!CoreGateway.ensureIdentity()) {
            Toast.makeText(requireContext(), "Ідентичність недоступна", Toast.LENGTH_SHORT).show()
            return
        }

        stopPlayback()

        // Check if we have contacts to show selection dialog
        val contacts = app.poruch.ya_ok.data.ContactStore.getContacts(requireContext())
        if (contacts.isNotEmpty()) {
            // Show contact selection dialog
            showContactSelectionForSend()
            return
        }

        // No contacts, send as broadcast
        sendToAll()
    }
    
    private fun showContactSelectionForSend() {
        val contacts = app.poruch.ya_ok.data.ContactStore.getContacts(requireContext())
        val contactNames = contacts.map { it.name }.toTypedArray()
        val selectedIndices = mutableSetOf<Int>()
        
        AlertDialog.Builder(requireContext())
            .setTitle("Оберіть одержувачів")
            .setMultiChoiceItems(contactNames, null) { _, which, isChecked ->
                if (isChecked) {
                    selectedIndices.add(which)
                } else {
                    selectedIndices.remove(which)
                }
            }
            .setPositiveButton("Надіслати") { _, _ ->
                if (selectedIndices.isEmpty()) {
                    Toast.makeText(requireContext(), "Оберіть хоча б одного одержувача", Toast.LENGTH_SHORT).show()
                    return@setPositiveButton
                }
                val selectedIds = selectedIndices.map { contacts[it].id }
                sendToRecipients(selectedIds)
            }
            .setNeutralButton("Всім") { _, _ ->
                sendToRecipients(contacts.map { it.id })
            }
            .setNegativeButton("Скасувати", null)
            .show()
    }
    
    private fun sendToRecipients(recipientIds: List<String>) {
        if (!isAdded || context == null) {
            println("❌ Fragment not attached, cannot send")
            return
        }
        
        // 🔍 DIAGNOSTIC: Log pre-send state
        println("📤 === SEND DIAGNOSTICS START ===")
        println("📤 Recipients: ${recipientIds.size} contacts")
        
        // Check peer registration (temporarily disabled - JNI binding not ready)
        // val peerList = CoreGateway.getPeerList()
        // println("📤 Registered peers: $peerList")
        
        // Check core stats (temporarily disabled - JNI binding not ready)
        // val stats = CoreGateway.getStats()
        // println("📤 Core stats: $stats")
        
        var successCount = 0
        var failCount = 0
        val failedContacts = mutableListOf<String>()
        
        recipientIds.forEach { recipientId ->
            println("📤 Sending to: $recipientId")
            
            val statusResult = when (selectedStatus) {
                StatusOption.OK -> CoreGateway.sendStatusTo(0, recipientId)
                StatusOption.BUSY -> CoreGateway.sendStatusTo(1, recipientId)
                StatusOption.LATER -> CoreGateway.sendStatusTo(2, recipientId)
                StatusOption.HUG -> CoreGateway.sendTextTo(getString(R.string.status_hug), recipientId)
            }
            
            println("📤 Status send result: $statusResult")
            
            if (statusResult == 0) {
                successCount++
                
                val text = textInput.text?.toString()?.trim().orEmpty()
                if (text.isNotEmpty()) {
                    val textResult = CoreGateway.sendTextTo(text, recipientId)
                    println("📤 Text send result: $textResult")
                }
                
                val voice = recordedVoice
                if (voice != null && voice.isNotEmpty()) {
                    val voiceResult = CoreGateway.sendVoiceTo(voice, recipientId)
                    println("📤 Voice send result: $voiceResult")
                }
            } else {
                failCount++
                failedContacts.add(recipientId.take(TRUNCATED_ID_LENGTH))
                println("❌ Failed to send to: $recipientId (error: $statusResult)")
            }
        }
        
        // Check pending packets after send
        val pending = CoreGateway.exportPendingPackets(PENDING_PACKETS_SAMPLE_SIZE)
        println("📤 Pending packets in queue: ${pending?.length ?: 0} bytes")
        println("📤 === SEND DIAGNOSTICS END ===")
        
        if (failCount == 0) {
            onSendSuccess()
        } else {
            val failedIds = failedContacts.joinToString(", ")
            Toast.makeText(
                requireContext(), 
                "⚠️ Помилка відправки: $failCount з ${recipientIds.size}\nКонтакти: $failedIds", 
                Toast.LENGTH_LONG
            ).show()
            
            // Show diagnostic dialog
            showSendDiagnostics(recipientIds, failedContacts)
        }
    }
    
    private fun showSendDiagnostics(allRecipients: List<String>, failedIds: List<String>) {
        if (!isAdded || context == null) return
        
        val bluetoothEnabled = isBluetoothEnabled()
        val hasInternet = hasInternetConnection()
        val peerCount = getPeerCount()
        
        val diagnosticInfo = buildDiagnosticMessage(
            bluetoothEnabled, 
            hasInternet, 
            peerCount, 
            failedIds, 
            allRecipients.size
        )
        
        AlertDialog.Builder(requireContext())
            .setTitle("Діагностика відправки")
            .setMessage(diagnosticInfo)
            .setPositiveButton("Зрозуміло", null)
            .setNeutralButton("Спробувати ще раз") { _, _ ->
                retryFailedContacts(allRecipients, failedIds)
            }
            .show()
    }
    
    private fun buildDiagnosticMessage(
        bluetoothEnabled: Boolean,
        hasInternet: Boolean,
        peerCount: Int,
        failedIds: List<String>,
        totalRecipients: Int
    ): String = buildString {
        append("🔍 Діагностика відправки:\n\n")
        
        append("📶 Bluetooth: ${if (bluetoothEnabled) "✅ Увімкнено" else "❌ Вимкнено"}\n")
        append("🌐 Інтернет: ${if (hasInternet) "✅ Доступний" else "❌ Відсутній"}\n")
        append("👥 Зареєстровані peer'и: $peerCount\n\n")
        
        if (failedIds.isNotEmpty()) {
            append("❌ Не вдалося відправити:\n")
            failedIds.forEach { append("  • $it\n") }
            append("\n")
        }
        
        append(buildRecommendations(bluetoothEnabled, hasInternet, peerCount, totalRecipients))
    }
    
    private fun buildRecommendations(
        bluetoothEnabled: Boolean,
        hasInternet: Boolean,
        peerCount: Int,
        totalRecipients: Int
    ): String = buildString {
        append("💡 Рекомендації:\n")
        if (!bluetoothEnabled) append("  • Увімкніть Bluetooth\n")
        if (!hasInternet) append("  • Перевірте інтернет підключення\n")
        if (peerCount == 0) append("  • Переконайтесь, що контакти додані з QR-кодом (з ключем)\n")
        if (peerCount < totalRecipients) append("  • Деякі контакти не зареєстровані. Відскануйте їх QR заново\n")
    }
    
    private fun retryFailedContacts(allRecipients: List<String>, failedShortIds: List<String>) {
        val failedFullIds = allRecipients.filter { fullId ->
            failedShortIds.any { shortId -> fullId.take(TRUNCATED_ID_LENGTH) == shortId }
        }
        if (failedFullIds.isNotEmpty()) {
            sendToRecipients(failedFullIds)
        }
    }
    
    private fun sendToAll() {
        val statusResult = when (selectedStatus) {
            StatusOption.OK -> CoreGateway.sendStatus(0)
            StatusOption.BUSY -> CoreGateway.sendStatus(1)
            StatusOption.LATER -> CoreGateway.sendStatus(2)
            StatusOption.HUG -> CoreGateway.sendText(getString(R.string.status_hug))
        }

        if (statusResult != 0) {
            Toast.makeText(requireContext(), "Помилка відправки ($statusResult)", Toast.LENGTH_SHORT).show()
            return
        }

        val text = textInput.text?.toString()?.trim().orEmpty()
        if (text.isNotEmpty()) {
            val textResult = CoreGateway.sendText(text)
            if (textResult != 0) {
                Toast.makeText(requireContext(), "Помилка тексту ($textResult)", Toast.LENGTH_SHORT).show()
                return
            }
        }

        recordedVoice?.let {
            val voiceResult = CoreGateway.sendVoice(it)
            if (voiceResult != 0) {
                Toast.makeText(requireContext(), "Помилка голосу ($voiceResult)", Toast.LENGTH_SHORT).show()
                return
            }
        }

        onSendSuccess()
    }
    
    private fun onSendSuccess() {
        AppPreferences.setLastCheckin(requireContext(), System.currentTimeMillis())
        updateLastCheckin()
        textInput.setText("")
        discardRecordedVoice()

        (activity as? Navigator)?.showSuccess()
    }

    private fun discardRecordedVoice() {
        recordedVoice = null
        recordedVoiceFile = null
        clearVoiceButton.visibility = View.GONE
        playVoiceButton.visibility = View.GONE
        voiceStatus.text = ""
        // Best-effort cleanup of last recorded file (avoid touching file while recording)
        if (voiceRecorder?.isRecording != true) {
            voiceRecorder?.discardLast()
        }
    }

    private fun togglePlayback() {
        val file = recordedVoiceFile
        if (file == null || !file.exists()) {
            Toast.makeText(requireContext(), "Немає запису для прослуховування", Toast.LENGTH_SHORT).show()
            return
        }

        val player = mediaPlayer
        if (player == null) {
            mediaPlayer = MediaPlayer().apply {
                setDataSource(file.absolutePath)
                setOnCompletionListener {
                    playVoiceButton.text = "▶️"
                    stopPlayback()
                }
                prepare()
                start()
            }
            playVoiceButton.text = "⏸"
            return
        }

        if (player.isPlaying) {
            player.pause()
            playVoiceButton.text = "▶️"
        } else {
            player.start()
            playVoiceButton.text = "⏸"
        }
    }

    private fun stopPlayback() {
        mediaPlayer?.runCatching { stop() }
        mediaPlayer?.runCatching { release() }
        mediaPlayer = null
        if (this::playVoiceButton.isInitialized) {
            playVoiceButton.text = "▶️"
        }
    }

    private fun updateLastCheckin() {
        val last = AppPreferences.getLastCheckin(requireContext())
        val formatted = if (last == 0L) "—" else {
            val formatter = DateFormat.getMediumDateFormat(requireContext())
            val timeFormatter = DateFormat.getTimeFormat(requireContext())
            "${formatter.format(Date(last))}, ${timeFormatter.format(Date(last))}"
        }
        lastCheckin.text = getString(R.string.last_checkin_format, formatted)
    }
    
    // ============================================================================
    // HELPER METHODS FOR STATUS CHECKS (Refactored)
    // ============================================================================
    
    private fun isBluetoothEnabled(): Boolean {
        return try {
            @Suppress("DEPRECATION")
            val adapter = BluetoothAdapter.getDefaultAdapter()
            adapter?.isEnabled == true
        } catch (e: Exception) {
            println("❌ Bluetooth check error: ${e.message}")
            false
        } catch (e: SecurityException) {
            println("❌ Bluetooth security error: ${e.message}")
            false
        }
    }

    private fun hasInternetConnection(): Boolean {
        return try {
            val cm = ContextCompat.getSystemService(requireContext(), ConnectivityManager::class.java)
            val network = cm?.activeNetwork
            val capabilities = cm?.getNetworkCapabilities(network)
            capabilities?.hasCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET) == true
        } catch (e: Exception) {
            println("❌ Internet check error: ${e.message}")
            false
        }
    }

    private fun getPeerCount(): Int {
        // TODO: Re-enable when getPeerList JNI binding is working
        // val peerList = CoreGateway.getPeerList() ?: return 0
        // return try {
        //     org.json.JSONArray(peerList).length()
        // } catch (e: Exception) {
        //     println("❌ Peer count parse error: ${e.message}")
        //     0
        // }
        return 0 // Temporary: return 0 peers
    }
}
