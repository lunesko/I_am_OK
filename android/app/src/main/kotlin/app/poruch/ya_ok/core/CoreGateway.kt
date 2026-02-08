package app.poruch.ya_ok.core

import android.content.Context
import app.poruch.ya_ok.YaOkCore

object CoreGateway {
    fun init(context: Context): Int {
        val path = context.filesDir.absolutePath
        android.util.Log.d("CoreGateway", "Initializing with path:  $path")
        val result = YaOkCore.initWithPath(path)
        android.util.Log.d("CoreGateway", "Init result code: $result")
        return result
    }

    fun getIdentityId(): String? = YaOkCore.getIdentityId()
    fun getIdentityX25519PublicKeyHex(): String? = YaOkCore.getIdentityX25519PublicKeyHex()
    fun addPeer(peerId: String, x25519PublicKeyHex: String): Int = YaOkCore.addPeer(peerId, x25519PublicKeyHex)

    fun ensureIdentity(): Boolean {
        if (YaOkCore.getIdentityId() != null) return true
        return YaOkCore.createIdentity() == 0
    }

    fun sendStatus(statusType: Int): Int = YaOkCore.sendStatus(statusType)

    fun sendText(text: String): Int = YaOkCore.sendText(text)

    fun sendVoice(data: ByteArray): Int = YaOkCore.sendVoice(data)
    
    fun sendStatusTo(statusType: Int, recipientId: String): Int = YaOkCore.sendStatusTo(statusType, recipientId)

    fun sendTextTo(text: String, recipientId: String): Int = YaOkCore.sendTextTo(text, recipientId)

    fun sendVoiceTo(data: ByteArray, recipientId: String): Int = YaOkCore.sendVoiceTo(data, recipientId)

    fun getRecentMessages(limit: Int): String? = YaOkCore.getRecentMessages(limit)

    fun getRecentMessagesFull(limit: Int): String? = YaOkCore.getRecentMessagesFull(limit)

    fun getStats(): String? = YaOkCore.getStats()

    fun getPeerList(): String? = YaOkCore.getPeerList()

    fun exportPendingPackets(limit: Int): String? = YaOkCore.exportPendingPackets(limit)

    fun exportPendingMessages(limit: Int): String? = YaOkCore.exportPendingMessages(limit)

    fun importPackets(packetsBase64: String): Int = YaOkCore.importPackets(packetsBase64)

    fun importPacketsWithPeer(packetsBase64: String, transportType: Int, address: String): Int =
        YaOkCore.importPacketsWithPeer(packetsBase64, transportType, address)

    fun importMessages(json: String): Int = YaOkCore.importMessages(json)

    fun markDelivered(messageId: String): Int = YaOkCore.markDelivered(messageId)

    fun wipeLocalData(): Int = YaOkCore.wipeLocalData()
}
