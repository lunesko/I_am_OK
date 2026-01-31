package app.poruch.ya_ok.transport

import android.Manifest
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.net.wifi.p2p.WifiP2pConfig
import android.net.wifi.p2p.WifiP2pManager
import android.os.Build
import androidx.core.content.ContextCompat
import app.poruch.ya_ok.util.LocationUtils
import java.net.InetAddress

class WifiDirectController(
    private val context: Context,
    private val onPeerAddress: (InetAddress) -> Unit
) {
    private val manager = context.getSystemService(Context.WIFI_P2P_SERVICE) as WifiP2pManager
    private val channel = manager.initialize(context, context.mainLooper, null)
    private var receiver: BroadcastReceiver? = null

    fun start() {
        // Wi‑Fi Direct discovery can trigger system prompts to enable Location services.
        // We only start discovery when the device Location toggle is ON and required permissions are already granted.
        if (!canDiscoverPeers()) return

        val filter = IntentFilter().apply {
            addAction(WifiP2pManager.WIFI_P2P_STATE_CHANGED_ACTION)
            addAction(WifiP2pManager.WIFI_P2P_PEERS_CHANGED_ACTION)
            addAction(WifiP2pManager.WIFI_P2P_CONNECTION_CHANGED_ACTION)
        }
        receiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context, intent: Intent) {
                when (intent.action) {
                    WifiP2pManager.WIFI_P2P_CONNECTION_CHANGED_ACTION -> {
                        manager.requestConnectionInfo(channel) { info ->
                            if (info.groupFormed) {
                                onPeerAddress(info.groupOwnerAddress)
                            }
                        }
                    }
                    WifiP2pManager.WIFI_P2P_PEERS_CHANGED_ACTION -> {
                        manager.requestPeers(channel) { peers ->
                            val device = peers.deviceList.firstOrNull() ?: return@requestPeers
                            val config = WifiP2pConfig().apply {
                                deviceAddress = device.deviceAddress
                            }
                            manager.connect(channel, config, null)
                        }
                    }
                }
            }
        }
        try {
            context.registerReceiver(receiver, filter)
            manager.discoverPeers(channel, null)
        } catch (_: SecurityException) {
            // Missing runtime permission (e.g. NEARBY_WIFI_DEVICES / LOCATION) - skip Wi‑Fi Direct silently.
            stop()
        }
    }

    fun stop() {
        receiver?.let { runCatching { context.unregisterReceiver(it) } }
        receiver = null
    }

    private fun canDiscoverPeers(): Boolean {
        // If location services are OFF, Android may show a prompt when starting discovery.
        if (!LocationUtils.isLocationEnabled(context)) return false

        val hasPermission = if (Build.VERSION.SDK_INT >= 33) {
            has(Manifest.permission.NEARBY_WIFI_DEVICES)
        } else {
            has(Manifest.permission.ACCESS_FINE_LOCATION) || has(Manifest.permission.ACCESS_COARSE_LOCATION)
        }
        return hasPermission
    }

    private fun has(permission: String): Boolean {
        return ContextCompat.checkSelfPermission(context, permission) == PackageManager.PERMISSION_GRANTED
    }
}
