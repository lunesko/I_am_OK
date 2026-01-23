package app.poruch.ya_ok.transport

import android.content.Context
import java.net.DatagramPacket
import java.net.DatagramSocket
import java.net.InetAddress
import java.net.InetSocketAddress
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.Executors

class UdpTransport(
    private val context: Context,
    private val onMessage: (String, String) -> Unit
) {
    private val executor = Executors.newSingleThreadExecutor()
    private var socket: DatagramSocket? = null
    private val peers = ConcurrentHashMap<String, InetSocketAddress>()

    fun start() {
        executor.execute {
            try {
                val udp = DatagramSocket(null)
                udp.reuseAddress = true
                udp.broadcast = true
                udp.bind(InetSocketAddress(PORT))
                socket = udp
                val buffer = ByteArray(65_000)

                while (!Thread.currentThread().isInterrupted) {
                    val packet = DatagramPacket(buffer, buffer.size)
                    udp.receive(packet)
                    val text = String(packet.data, packet.offset, packet.length, Charsets.UTF_8)
                    peers[packet.address.hostAddress] = InetSocketAddress(packet.address, PORT)
                    val address = "${packet.address.hostAddress}:${PORT}"
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
        val udp = socket ?: return
        val data = json.toByteArray(Charsets.UTF_8)
        val destinations = mutableListOf<InetSocketAddress>()
        destinations.add(InetSocketAddress(InetAddress.getByName(BROADCAST_ADDRESS), PORT))
        destinations.addAll(peers.values)

        destinations.forEach { address ->
            runCatching {
                val packet = DatagramPacket(data, data.size, address.address, PORT)
                udp.send(packet)
            }
        }
    }

    fun addPeer(address: InetAddress) {
        peers[address.hostAddress] = InetSocketAddress(address, PORT)
    }

    companion object {
        private const val PORT = 45678
        private const val BROADCAST_ADDRESS = "255.255.255.255"
    }
}
