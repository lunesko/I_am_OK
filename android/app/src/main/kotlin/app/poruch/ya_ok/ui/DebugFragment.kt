package app.poruch.ya_ok.ui

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.TextView
import androidx.fragment.app.Fragment
import androidx.lifecycle.lifecycleScope
import app.poruch.ya_ok.R
import app.poruch.ya_ok.YaOkCore
import kotlinx.coroutines.delay
import kotlinx.coroutines.isActive
import kotlinx.coroutines.launch
import org.json.JSONArray

/**
 * Debug screen showing real-time statistics and diagnostics
 * 
 * Features:
 * - Message counts (received, sent, pending)
 * - Active peer list
 * - ACK statistics
 * - Storage stats
 * - Connection status
 * - Build info
 */
class DebugFragment : Fragment() {

    private lateinit var statsText: TextView
    private var updateJob: kotlinx.coroutines.Job? = null

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View? {
        return inflater.inflate(R.layout.fragment_debug, container, false)
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)
        
        statsText = view.findViewById(R.id.debug_stats_text)
        
        // Start periodic stats update
        updateJob = viewLifecycleOwner.lifecycleScope.launch {
            while (isActive) {
                updateStats()
                delay(1000) // Update every second
            }
        }
    }

    override fun onDestroyView() {
        super.onDestroyView()
        updateJob?.cancel()
    }

    private fun updateStats() {
        val stats = StringBuilder()
        
        // Header
        stats.appendLine("=== Ya OK Debug Info ===\n")
        
        // Core Status
        stats.appendLine("CORE:")
        val identityId = YaOkCore.getIdentityId()
        stats.appendLine("  Identity: ${identityId?.take(16)}...")
        stats.appendLine("  Version: ${android.os.Build.VERSION.RELEASE}")
        stats.appendLine("  Build: ${app.poruch.ya_ok.BuildConfig.VERSION_NAME}\n")
        
        // Message Stats
        stats.appendLine("MESSAGES:")
        try {
            val recentJson = YaOkCore.getRecentMessages(100)
            val messages = if (recentJson != null) JSONArray(recentJson) else JSONArray()
            stats.appendLine("  Recent: ${messages.length()}")
            
            // Count by type
            var statusCount = 0
            var textCount = 0
            var voiceCount = 0
            for (i in 0 until messages.length()) {
                val msg = messages.getJSONObject(i)
                when (msg.optString("type")) {
                    "status" -> statusCount++
                    "text" -> textCount++
                    "voice" -> voiceCount++
                }
            }
            stats.appendLine("  Status: $statusCount")
            stats.appendLine("  Text: $textCount")
            stats.appendLine("  Voice: $voiceCount\n")
        } catch (e: Exception) {
            stats.appendLine("  Error: ${e.message}\n")
        }
        
        // Peer Stats
        stats.appendLine("PEERS:")
        try {
            val peersJson = YaOkCore.getPeerList()
            val peers = if (peersJson != null) JSONArray(peersJson) else JSONArray()
            stats.appendLine("  Active: ${peers.length()}")
            for (i in 0 until minOf(5, peers.length())) {
                val peer = peers.getJSONObject(i)
                val pkShort = peer.optString("public_key").take(16)
                val meta = peer.optString("meta", "unknown")
                stats.appendLine("  - $pkShort... ($meta)")
            }
            if (peers.length() > 5) {
                stats.appendLine("  ... and ${peers.length() - 5} more")
            }
            stats.appendLine()
        } catch (e: Exception) {
            stats.appendLine("  Error: ${e.message}\n")
        }
        
        // ACK Stats (for most recent message)
        stats.appendLine("ACK STATUS (last message):")
        try {
            val recentJson = YaOkCore.getRecentMessages(1)
            val messages = if (recentJson != null) JSONArray(recentJson) else JSONArray()
            if (messages.length() > 0) {
                val msg = messages.getJSONObject(0)
                val messageId = msg.optString("id")
                val acksJson = YaOkCore.getAcksForMessage(messageId)
                val acks = if (acksJson != null) JSONArray(acksJson) else JSONArray()
                
                stats.appendLine("  Message: ${messageId.take(16)}...")
                stats.appendLine("  ACKs: ${acks.length()}")
                
                var receivedCount = 0
                var deliveredCount = 0
                for (i in 0 until acks.length()) {
                    val ack = acks.getJSONObject(i)
                    when (ack.optString("ack_type")) {
                        "Received" -> receivedCount++
                        "Delivered" -> deliveredCount++
                    }
                }
                stats.appendLine("  Received: $receivedCount")
                stats.appendLine("  Delivered: $deliveredCount\n")
            } else {
                stats.appendLine("  No messages\n")
            }
        } catch (e: Exception) {
            stats.appendLine("  Error: ${e.message}\n")
        }
        
        // Transport Stats
        stats.appendLine("TRANSPORT:")
        stats.appendLine("  BLE: ${isBleEnabled()}")
        stats.appendLine("  WiFi: ${isWifiEnabled()}")
        stats.appendLine("  Internet: ${hasInternetConnection()}\n")
        
        // Memory Stats
        stats.appendLine("MEMORY:")
        val runtime = Runtime.getRuntime()
        val usedMB = (runtime.totalMemory() - runtime.freeMemory()) / 1024 / 1024
        val maxMB = runtime.maxMemory() / 1024 / 1024
        stats.appendLine("  Used: ${usedMB}MB / ${maxMB}MB")
        stats.appendLine("  Free: ${runtime.freeMemory() / 1024 / 1024}MB\n")
        
        // Footer
        stats.appendLine("======================")
        stats.appendLine("Last update: ${System.currentTimeMillis()}")
        
        statsText.text = stats.toString()
    }

    private fun isBleEnabled(): String {
        val bluetoothManager = requireContext().getSystemService(android.content.Context.BLUETOOTH_SERVICE) 
            as? android.bluetooth.BluetoothManager
        return if (bluetoothManager?.adapter?.isEnabled == true) "ON" else "OFF"
    }

    private fun isWifiEnabled(): String {
        val wifiManager = requireContext().applicationContext.getSystemService(android.content.Context.WIFI_SERVICE)
            as? android.net.wifi.WifiManager
        return if (wifiManager?.isWifiEnabled == true) "ON" else "OFF"
    }

    private fun hasInternetConnection(): String {
        val cm = requireContext().getSystemService(android.content.Context.CONNECTIVITY_SERVICE)
            as? android.net.ConnectivityManager
        val network = cm?.activeNetwork
        val capabilities = cm?.getNetworkCapabilities(network)
        return if (capabilities?.hasCapability(android.net.NetworkCapabilities.NET_CAPABILITY_INTERNET) == true) {
            "CONNECTED"
        } else {
            "OFFLINE"
        }
    }
}
