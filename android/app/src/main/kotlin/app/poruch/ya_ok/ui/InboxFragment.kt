package app.poruch.ya_ok.ui

import android.os.Bundle
import android.text.format.DateUtils
import android.media.MediaPlayer
import android.view.LayoutInflater
import android.view.View
import android.widget.LinearLayout
import android.widget.TextView
import androidx.fragment.app.Fragment
import app.poruch.ya_ok.R
import app.poruch.ya_ok.core.CoreGateway
import com.google.android.material.tabs.TabLayout
import org.json.JSONArray
import org.json.JSONObject
import java.io.File
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import android.util.Base64

class InboxFragment : Fragment(R.layout.fragment_inbox) {
    private lateinit var messagesContainer: LinearLayout
    private var tabLayout: TabLayout? = null
    private var currentTab = TabType.ALL

    private enum class TabType {
        ALL, INCOMING, OUTGOING
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)
        view.findViewById<TextView>(R.id.backButton).setOnClickListener {
            (activity as? Navigator)?.navigateBack()
        }
        messagesContainer = view.findViewById(R.id.messagesContainer)
        
        // Setup tabs
        tabLayout = view.findViewById<TabLayout>(R.id.tabLayout)?.apply {
            addTab(newTab().setText("Всі"))
            addTab(newTab().setText("Вхідні"))
            addTab(newTab().setText("Вихідні"))
            
            addOnTabSelectedListener(object : TabLayout.OnTabSelectedListener {
                override fun onTabSelected(tab: TabLayout.Tab?) {
                    currentTab = when (tab?.position) {
                        1 -> TabType.INCOMING
                        2 -> TabType.OUTGOING
                        else -> TabType.ALL
                    }
                    renderMessages()
                }
                
                override fun onTabUnselected(tab: TabLayout.Tab?) {}
                override fun onTabReselected(tab: TabLayout.Tab?) {}
            })
        }
        
        if (tabLayout == null) {
            currentTab = TabType.ALL
        }
        
        renderMessages()
    }

    private fun renderMessages() {
        messagesContainer.removeAllViews()
        val json = CoreGateway.getRecentMessagesFull(50).orEmpty()
        val array = runCatching { JSONArray(json) }.getOrNull()
        if (array == null || array.length() == 0) {
            val empty = TextView(requireContext()).apply {
                text = getString(R.string.inbox_empty)
                setTextColor(resources.getColor(R.color.text_secondary, null))
                textSize = 14f
            }
            messagesContainer.addView(empty)
            return
        }

        val myId = CoreGateway.getIdentityId()
        val inflater = LayoutInflater.from(requireContext())
        var messageCount = 0
        
        for (i in 0 until array.length()) {
            val obj = array.optJSONObject(i) ?: continue
            val senderId = obj.optString("sender_id")
            
            // Filter by tab
            val isOutgoing = senderId == myId
            val shouldShow = when (currentTab) {
                TabType.ALL -> true
                TabType.INCOMING -> !isOutgoing
                TabType.OUTGOING -> isOutgoing
            }
            
            if (!shouldShow) continue
            messageCount++
            
            val item = inflater.inflate(R.layout.item_message, messagesContainer, false)

            val messageTitle = item.findViewById<TextView>(R.id.messageTitle)
            val messageSubtitle = item.findViewById<TextView>(R.id.messageSubtitle)
            val messageEmoji = item.findViewById<TextView>(R.id.messageEmoji)
            val messageMeta = item.findViewById<TextView>(R.id.messageMeta)

            val display = buildDisplay(obj)
            messageTitle.text = display.title
            messageEmoji.text = display.emoji
            
            // Add direction indicator
            val direction = if (isOutgoing) "➤" else "◀"
            messageSubtitle.text = "$direction ${display.time}"
            messageMeta.text = if (senderId.isNotBlank()) senderId.take(6) else "•"

            item.setOnClickListener {
                display.voiceBase64?.let { base64 ->
                    playVoice(base64)
                }
            }

            messagesContainer.addView(item)
        }
        
        if (messageCount == 0) {
            val empty = TextView(requireContext()).apply {
                text = when (currentTab) {
                    TabType.INCOMING -> "Немає вхідних повідомлень"
                    TabType.OUTGOING -> "Немає вихідних повідомлень"
                    else -> getString(R.string.inbox_empty)
                }
                setTextColor(resources.getColor(R.color.text_secondary, null))
                textSize = 14f
            }
            messagesContainer.addView(empty)
        }
    }

    private fun buildDisplay(obj: JSONObject): MessageDisplay {
        val messageType = obj.optString("message_type")
        val status = obj.optString("status")
        val text = obj.optString("text")
        val voiceBase64 = obj.optString("voice_base64").takeIf { it.isNotBlank() }

        val title = when {
            messageType == "status" && status == "ok" -> getString(R.string.status_ok)
            messageType == "status" && status == "busy" -> getString(R.string.status_busy)
            messageType == "status" && status == "later" -> getString(R.string.status_later)
            messageType == "text" && text.isNotBlank() -> text
            messageType == "voice" -> "🎙️ Голос"
            else -> "Сигнал"
        }

        val emoji = when {
            messageType == "status" && status == "ok" -> "💚"
            messageType == "status" && status == "busy" -> "💛"
            messageType == "status" && status == "later" -> "💙"
            messageType == "text" -> "💬"
            messageType == "voice" -> "🎙️"
            else -> "•"
        }

        val timestamp = obj.optString("timestamp")
        val timeText = formatRelativeTime(timestamp)
        return MessageDisplay(title = title, emoji = emoji, time = timeText, voiceBase64 = voiceBase64)
    }

    private fun formatRelativeTime(timestamp: String): String {
        val parsed = parseDate(timestamp)
        return if (parsed != null) {
            DateUtils.getRelativeTimeSpanString(
                parsed.time,
                System.currentTimeMillis(),
                DateUtils.MINUTE_IN_MILLIS
            ).toString()
        } else {
            "—"
        }
    }

    private fun parseDate(value: String): Date? {
        val formats = listOf(
            "yyyy-MM-dd'T'HH:mm:ss.SSSXXX",
            "yyyy-MM-dd'T'HH:mm:ssXXX"
        )
        for (pattern in formats) {
            val parsed = runCatching {
                SimpleDateFormat(pattern, Locale.getDefault()).parse(value)
            }.getOrNull()
            if (parsed != null) return parsed
        }
        return null
    }

    private data class MessageDisplay(
        val title: String,
        val emoji: String,
        val time: String,
        val voiceBase64: String?
    )

    private fun playVoice(base64: String) {
        val bytes = runCatching { Base64.decode(base64, Base64.DEFAULT) }.getOrNull() ?: return
        val file = File(requireContext().cacheDir, "voice_inbox_${System.currentTimeMillis()}.m4a")
        runCatching { file.writeBytes(bytes) }
        val player = MediaPlayer()
        runCatching {
            player.setDataSource(file.absolutePath)
            player.prepare()
            player.start()
            player.setOnCompletionListener {
                it.release()
                file.delete()
            }
        }.onFailure {
            player.release()
            file.delete()
        }
    }
}
