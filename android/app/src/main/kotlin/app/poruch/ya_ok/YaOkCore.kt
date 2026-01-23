package app.poruch.ya_ok

object YaOkCore {
    init {
        System.loadLibrary("ya_ok_core")
    }

    @JvmStatic external fun init(): Int
    @JvmStatic external fun initWithPath(baseDir: String): Int
    @JvmStatic external fun createIdentity(): Int
    @JvmStatic external fun getIdentityId(): String?
    @JvmStatic external fun sendStatus(statusType: Int): Int
    @JvmStatic external fun sendText(text: String): Int
    @JvmStatic external fun sendVoice(data: ByteArray): Int
    @JvmStatic external fun startListening(): Int
    @JvmStatic external fun stopListening(): Int
    @JvmStatic external fun setPolicy(policyType: Int): Int
    @JvmStatic external fun getStats(): String?
    @JvmStatic external fun getRecentMessages(limit: Int): String?
    @JvmStatic external fun getRecentMessagesFull(limit: Int): String?
    @JvmStatic external fun exportPendingPackets(limit: Int): String?
    @JvmStatic external fun exportPendingMessages(limit: Int): String?
    @JvmStatic external fun importPackets(packetsBase64: String): Int
    @JvmStatic external fun importPacketsWithPeer(packetsBase64: String, transportType: Int, address: String): Int
    @JvmStatic external fun importMessages(json: String): Int
    @JvmStatic external fun markDelivered(messageId: String): Int
}
