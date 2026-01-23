package app.poruch.ya_ok.transport

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.net.wifi.p2p.WifiP2pConfig
import android.net.wifi.p2p.WifiP2pManager
import java.net.InetAddress

class WifiDirectController(
    private val context: Context,
    private val onPeerAddress: (InetAddress) -> Unit
) {
    private val manager = context.getSystemService(Context.WIFI_P2P_SERVICE) as WifiP2pManager
    private val channel = manager.initialize(context, context.mainLooper, null)
    private var receiver: BroadcastReceiver? = null

    fun start() {
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
        context.registerReceiver(receiver, filter)
        manager.discoverPeers(channel, null)
    }

    fun stop() {
        receiver?.let { context.unregisterReceiver(it) }
        receiver = null
    }
}
