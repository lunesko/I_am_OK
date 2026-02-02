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
        println("🔵 TransportService onCreate() - initializing...")
        NotificationHelper.createChannel(this)
        startForeground(NotificationHelper.FOREGROUND_ID, NotificationHelper.buildForeground(this))

        println("🔵 Creating UdpTransport...")
        udpTransport = UdpTransport(this) { payload, address ->
            handleIncoming(payload, TRANSPORT_UDP, address)
        }
        bleTransport = BleTransport(this) { payload, address ->
            handleIncoming(payload, TRANSPORT_BLE, address)
        }
        wifiDirectController = WifiDirectController(this, udpTransport::addPeer)

        println("🔵 Starting UDP transport...")
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

        println("📤 syncOutgoing: ${packets.length} bytes to send")
        udpTransport.send(packets)
        bleTransport.send(packets)
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
            
            // Handle contact add request
            val content = obj.optString("content")
            println("🔵 Message content: $content")
            if (content.contains("\"type\":\"contact_add_request\"")) {
                println("🔵 Found contact_add_request, processing...")
                handleContactAddRequest(content, senderId)
            }
        }
    }
    
    private fun handleContactAddRequest(jsonContent: String, senderId: String) {
        try {
            println("🔵 handleContactAddRequest: $jsonContent")
            val requestObj = org.json.JSONObject(jsonContent)
            val requestType = requestObj.optString("type")
            if (requestType != "contact_add_request") {
                println("❌ Not a contact_add_request: $requestType")
                return
            }
            
            val contactId = requestObj.optString("id")
            val contactName = requestObj.optString("name", "Користувач")
            val x25519Key = requestObj.optString("x25519")
            
            println("🔵 Parsed: id=$contactId, name=$contactName, x25519=${x25519Key.isNotBlank()}")
            
            if (contactId.isBlank()) {
                println("❌ Empty contactId")
                return
            }
            
            // Check if contact already exists
            val existingContacts = ContactStore.getContacts(this)
            if (existingContacts.any { it.id == contactId }) {
                println("⚠️ Contact $contactId already exists")
                return
            }
            
            println("✅ Adding new contact: $contactName")
            
            // Auto-add contact
            val contact = app.poruch.ya_ok.data.Contact(
                id = contactId,
                name = contactName,
                lastCheckin = System.currentTimeMillis()
            )
            ContactStore.addContact(this, contact)
            
            // Sync peer if x25519 key available
            if (x25519Key.isNotBlank()) {
                val result = CoreGateway.addPeer(contactId, x25519Key)
                println("🔵 addPeer result: $result")
            }
            
            // Show notification
            println("🔵 Showing notification for $contactName")
            NotificationHelper.showContactAdded(this, contactName)
            
        } catch (e: Exception) {
            println("❌ Error handling contact add request: ${e.message}")
            e.printStackTrace()
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
