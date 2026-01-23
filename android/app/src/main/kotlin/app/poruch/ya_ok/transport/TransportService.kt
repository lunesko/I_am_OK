package app.poruch.ya_ok.transport

import android.app.Notification
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import app.poruch.ya_ok.core.CoreGateway
import app.poruch.ya_ok.data.ContactStore
import org.json.JSONArray

class TransportService : Service() {
    private val handler = Handler(Looper.getMainLooper())
    private lateinit var udpTransport: UdpTransport
    private lateinit var bleTransport: BleTransport
    private lateinit var wifiDirectController: WifiDirectController

    private val syncRunnable = object : Runnable {
        override fun run() {
            syncOutgoing()
            handler.postDelayed(this, SYNC_INTERVAL_MS)
        }
    }

    override fun onCreate() {
        super.onCreate()
        NotificationHelper.createChannel(this)
        startForeground(NotificationHelper.FOREGROUND_ID, NotificationHelper.buildForeground(this))

        udpTransport = UdpTransport(this) { payload, address ->
            handleIncoming(payload, TRANSPORT_UDP, address)
        }
        bleTransport = BleTransport(this) { payload, address ->
            handleIncoming(payload, TRANSPORT_BLE, address)
        }
        wifiDirectController = WifiDirectController(this, udpTransport::addPeer)

        udpTransport.start()
        bleTransport.start()
        wifiDirectController.start()

        handler.post(syncRunnable)
    }

    override fun onDestroy() {
        handler.removeCallbacksAndMessages(null)
        udpTransport.stop()
        bleTransport.stop()
        wifiDirectController.stop()
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun syncOutgoing() {
        val packets = CoreGateway.exportPendingPackets(50).orEmpty()
        if (packets.isBlank()) return

        udpTransport.send(packets)
        bleTransport.send(packets)

        // Временно сохраняем совместимость: помечаем отправленные сообщения как доставленные
        val json = CoreGateway.exportPendingMessages(50).orEmpty()
        if (json.length > 2) {
            markDelivered(json)
        }
    }

    private fun handleIncoming(payload: String, transportType: Int, address: String) {
        val importedPackets = CoreGateway.importPacketsWithPeer(payload, transportType, address)
        if (importedPackets > 0) {
            val recent = CoreGateway.getRecentMessages(20).orEmpty()
            if (recent.length > 2) {
                updateContacts(recent)
                NotificationHelper.showIncoming(this, recent)
            }
            return
        }

        // Fallback для старых клиентов (JSON)
        val imported = CoreGateway.importMessages(payload)
        if (imported <= 0) return

        updateContacts(payload)
        NotificationHelper.showIncoming(this, payload)
    }

    private fun updateContacts(json: String) {
        val array = runCatching { JSONArray(json) }.getOrNull() ?: return
        val now = System.currentTimeMillis()
        for (i in 0 until array.length()) {
            val obj = array.optJSONObject(i) ?: continue
            val senderId = obj.optString("sender_id")
            if (senderId.isNotBlank()) {
                ContactStore.updateLastCheckin(this, senderId, now)
            }
        }
    }

    private fun markDelivered(json: String) {
        val array = runCatching { JSONArray(json) }.getOrNull() ?: return
        for (i in 0 until array.length()) {
            val obj = array.optJSONObject(i) ?: continue
            val id = obj.optString("id")
            if (id.isNotBlank()) {
                CoreGateway.markDelivered(id)
            }
        }
    }

    companion object {
        private const val SYNC_INTERVAL_MS = 15_000L
        private const val TRANSPORT_BLE = 0
        private const val TRANSPORT_WIFI_DIRECT = 1
        private const val TRANSPORT_UDP = 2
        private const val TRANSPORT_SATELLITE = 3

        fun start(context: Context) {
            val intent = Intent(context, TransportService::class.java)
            if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
        }
    }
}
