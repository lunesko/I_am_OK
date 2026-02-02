package app.poruch.ya_ok.transport

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.os.Build
import androidx.core.app.NotificationCompat
import app.poruch.ya_ok.R
import org.json.JSONArray

object NotificationHelper {
    const val CHANNEL_ID = "ya_ok_messages"
    const val FOREGROUND_ID = 1001

    fun createChannel(context: Context) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Ya OK messages",
                NotificationManager.IMPORTANCE_DEFAULT
            )
            val manager = context.getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }
    }

    fun buildForeground(context: Context): Notification {
        return NotificationCompat.Builder(context, CHANNEL_ID)
            .setContentTitle("Я ОК")
            .setContentText("Синхронізація активна")
            .setSmallIcon(android.R.drawable.stat_notify_sync)
            .setOngoing(true)
            .build()
    }

    fun showIncoming(context: Context, json: String) {
        val array = runCatching { JSONArray(json) }.getOrNull() ?: return
        if (array.length() == 0) return
        val first = array.optJSONObject(0) ?: return
        val title = "Я ОК"
        val body = buildBody(first)

        val notification = NotificationCompat.Builder(context, CHANNEL_ID)
            .setContentTitle(title)
            .setContentText(body)
            .setSmallIcon(android.R.drawable.stat_notify_chat)
            .setAutoCancel(true)
            .build()

        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        manager.notify(System.currentTimeMillis().toInt(), notification)
    }

    private fun buildBody(obj: org.json.JSONObject): String {
        val type = obj.optString("message_type")
        val status = obj.optString("status")
        val text = obj.optString("text")
        return when {
            type == "status" && status == "ok" -> "💚 Я ОК"
            type == "status" && status == "busy" -> "💛 Все нормально, зайнятий"
            type == "status" && status == "later" -> "💙 Зателефоную пізніше"
            type == "text" && text.isNotBlank() -> "💬 $text"
            type == "voice" -> "🎙️ Голос"
            else -> "Нове повідомлення"
        }
    }
    
    fun showContactAdded(context: Context, contactName: String) {
        val notification = NotificationCompat.Builder(context, CHANNEL_ID)
            .setContentTitle("Новий контакт")
            .setContentText("✅ $contactName додав(ла) вас у свої контакти")
            .setSmallIcon(android.R.drawable.stat_notify_chat)
            .setAutoCancel(true)
            .build()

        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        manager.notify(System.currentTimeMillis().toInt(), notification)
    }
}
