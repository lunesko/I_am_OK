package app.poruch.ya_ok.voice

import android.content.Context
import android.media.MediaRecorder
import java.io.File

class VoiceRecorder(private val context: Context) {
    private var recorder: MediaRecorder? = null
    private var outputFile: File? = null

    val isRecording: Boolean
        get() = recorder != null

    fun start(): Boolean {
        if (recorder != null) return false
        return try {
            val file = File(context.cacheDir, "voice_${System.currentTimeMillis()}.m4a")
            val mediaRecorder = MediaRecorder().apply {
                setAudioSource(MediaRecorder.AudioSource.MIC)
                setOutputFormat(MediaRecorder.OutputFormat.MPEG_4)
                setAudioEncoder(MediaRecorder.AudioEncoder.AAC)
                setAudioEncodingBitRate(32_000)
                setAudioSamplingRate(16_000)
                setMaxDuration(7_000)
                setOutputFile(file.absolutePath)
                prepare()
                start()
            }
            outputFile = file
            recorder = mediaRecorder
            true
        } catch (_: Exception) {
            recorder?.release()
            recorder = null
            outputFile = null
            false
        }
    }

    fun stop(): File? {
        val mediaRecorder = recorder ?: return null
        return try {
            mediaRecorder.stop()
            mediaRecorder.release()
            recorder = null
            outputFile
        } catch (_: Exception) {
            recorder = null
            outputFile?.delete()
            outputFile = null
            null
        }
    }

    fun discardLast() {
        outputFile?.delete()
        outputFile = null
    }

    fun cancel() {
        recorder?.run {
            try {
                stop()
            } catch (_: Exception) {
            }
            release()
        }
        recorder = null
        discardLast()
    }
}
