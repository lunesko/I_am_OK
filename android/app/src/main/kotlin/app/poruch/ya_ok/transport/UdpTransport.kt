package app.poruch.ya_ok.transport

import android.content.Context
import app.poruch.ya_ok.security.RelaySecurityManager
import java.io.InputStream
import java.net.DatagramPacket
import java.net.DatagramSocket
import java.net.InetAddress
import java.net.InetSocketAddress
import java.util.Properties
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.Executors

class UdpTransport(
    private val context: Context,
    private val onMessage: (String, String) -> Unit
) {
    private val executor = Executors.newSingleThreadExecutor()
    private var socket: DatagramSocket? = null
    private val peers = ConcurrentHashMap<String, InetSocketAddress>()
    private val securityManager = RelaySecurityManager()
    
    // Relay configuration - Production Fly.io server
    private val relayConfig: Pair<String, Int> by lazy {
        try {
            val properties = Properties()
            val inputStream: InputStream = context.resources.openRawResource(
                context.resources.getIdentifier("relay_config", "raw", context.packageName)
            )
            properties.load(inputStream)
            val host = properties.getProperty("relay.primary.host", "i-am-ok-relay.fly.dev")
            val port = properties.getProperty("relay.primary.port", "40100").toIntOrNull() ?: 40100
            Pair(host, port)
        } catch (e: Exception) {
            // Fallback to production Fly.io relay
            Pair("i-am-ok-relay.fly.dev", 40100)
        }
    }
    
    @Volatile
    private var relayAddress: InetSocketAddress? = null

    fun start() {
        println("🔵 UDP Transport starting...")
        executor.execute {
            // Initialize relay address in background thread (DNS resolution)
            try {
                val (host, port) = relayConfig
                println("🔵 Relay config: $host:$port")
                val address = InetAddress.getByName(host)
                println("🔵 Relay resolved to: ${address.hostAddress}")
                // Security: Validate relay IP before creating connection
                if (!securityManager.validateRelayAddress(address)) {
                    println("⚠️ Relay address validation failed")
                    return@execute
                }
                relayAddress = InetSocketAddress(address, port)
                println("✅ Relay address validated: $host:$port")
            } catch (e: Exception) {
                println("❌ Relay config error: ${e.message}")
                e.printStackTrace()
            }

            try {
                val udp = DatagramSocket(null)
                udp.reuseAddress = true
                udp.broadcast = true
                udp.bind(InetSocketAddress(PORT))
                socket = udp
                println("✅ UDP socket bound to port $PORT, ready to receive")
                val buffer = ByteArray(65_000)

                while (!Thread.currentThread().isInterrupted) {
                    val packet = DatagramPacket(buffer, buffer.size)
                    udp.receive(packet)
                    
                    val srcPort = packet.port
                    
                    // Security: Validate packets from relay with rate limiting
                    if (srcPort == relayConfig.second) {
                        val data = packet.data.copyOfRange(packet.offset, packet.offset + packet.length)
                        if (!securityManager.validateIncomingPacket(srcPort, data)) {
                            println("⚠️ Relay packet validation failed")
                            continue
                        }
                    }
                    
                    val text = String(packet.data, packet.offset, packet.length, Charsets.UTF_8)
                    val host = packet.address.hostAddress ?: continue
                    
                    // Don't learn the relay as a "peer". Fly UDP replies can come from anycast IPs
                    // (not necessarily relay host), but they will always come from relay port.
                    if (srcPort != relayConfig.second) {
                        peers[host] = InetSocketAddress(packet.address, srcPort)
                    }
                    val address = "$host:$srcPort"
                    onMessage(text, address)
                }
            } catch (_: Exception) {
            }
        }
    }

    fun stop() {
        socket?.close()
        executor.shutdownNow()
    }

    fun send(json: String) {
        executor.execute {
            val udp = socket ?: run {
                println("⚠️ UDP socket not initialized")
                return@execute
            }
            val data = json.toByteArray(Charsets.UTF_8)
            val destinations = mutableListOf<InetSocketAddress>()
            destinations.add(InetSocketAddress(InetAddress.getByName(BROADCAST_ADDRESS), PORT))
            destinations.addAll(peers.values)
            relayAddress?.let { 
                destinations.add(it)
                println("📤 Sending to relay: ${it.hostString}:${it.port} (${data.size} bytes)")
            }

            var sent = 0
            destinations.forEach { address ->
                runCatching {
                    val packet = DatagramPacket(data, data.size, address.address, address.port)
                    udp.send(packet)
                    sent++
                }.onFailure { e ->
                    println("❌ Failed to send to ${address}: ${e.message}")
                    e.printStackTrace()
                }
            }
            println("📤 Sent ${sent}/${destinations.size} UDP packets")
        }
    }

    fun addPeer(address: InetAddress) {
        val host = address.hostAddress ?: return
        peers[host] = InetSocketAddress(address, PORT)
    }

    companion object {
        private const val PORT = 45678
        private const val BROADCAST_ADDRESS = "255.255.255.255"
    }
}
