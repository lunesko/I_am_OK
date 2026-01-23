package app.poruch.ya_ok.ui

import android.Manifest
import android.media.MediaPlayer
import android.os.Bundle
import android.os.CountDownTimer
import android.text.format.DateFormat
import android.view.View
import android.widget.TextView
import android.widget.Toast
import androidx.activity.result.contract.ActivityResultContracts
import androidx.core.content.ContextCompat
import androidx.fragment.app.Fragment
import app.poruch.ya_ok.R
import app.poruch.ya_ok.core.CoreGateway
import app.poruch.ya_ok.data.AppPreferences
import app.poruch.ya_ok.voice.VoiceRecorder
import com.google.android.material.button.MaterialButton
import com.google.android.material.card.MaterialCardView
import com.google.android.material.textfield.TextInputEditText
import java.util.Date

class MainFragment : Fragment(R.layout.fragment_main) {
    private enum class StatusOption { OK, BUSY, LATER, HUG }
    private companion object {
        private const val MAX_VOICE_BYTES = 56_000
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

    private var selectedStatus = StatusOption.OK
    private var recordedVoice: ByteArray? = null
    private var recordedVoiceFile: java.io.File? = null
    private var voiceRecorder: VoiceRecorder? = null
    private var countdown: CountDownTimer? = null
    private var mediaPlayer: MediaPlayer? = null

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
    }

    override fun onDestroyView() {
        super.onDestroyView()
        countdown?.cancel()
        stopPlayback()
        voiceRecorder?.cancel()
        voiceRecorder = null
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
}
