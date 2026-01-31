package app.poruch.ya_ok.ui

import android.content.Intent
import android.graphics.Bitmap
import android.graphics.Color
import android.os.Bundle
import android.widget.ImageView
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity
import app.poruch.ya_ok.R
import app.poruch.ya_ok.core.CoreGateway
import com.google.zxing.BarcodeFormat
import com.google.zxing.qrcode.QRCodeWriter

class QrCodeActivity : AppCompatActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_qr_code)

        val identityId = CoreGateway.getIdentityId()
        if (identityId == null) {
            finish()
            return
        }

        val x25519Hex = CoreGateway.getIdentityX25519PublicKeyHex().orEmpty()
        val link = buildQrLink(identityId, x25519Hex)
        findViewById<TextView>(R.id.identityIdText).text = identityId
        // QR should encode a shareable deep link, not just raw ID.
        findViewById<ImageView>(R.id.qrCodeImage).setImageBitmap(generateQrCode(link))
        findViewById<TextView>(R.id.closeButton).setOnClickListener { finish() }
        findViewById<TextView>(R.id.shareButton).setOnClickListener {
            shareQrLink(identityId, x25519Hex)
        }
    }

    private fun shareQrLink(identityId: String, x25519Hex: String) {
        val link = buildQrLink(identityId, x25519Hex)
        val text = buildString {
            append("Додай мене в Я ОК:\n")
            append(link)
            append("\n\nID:\n")
            append(identityId)
        }
        val intent = Intent(Intent.ACTION_SEND).apply {
            type = "text/plain"
            putExtra(Intent.EXTRA_TEXT, text)
        }
        startActivity(Intent.createChooser(intent, "Поділитися"))
    }

    private fun buildQrLink(identityId: String, x25519Hex: String): String {
        // Include X25519 public key for initial key exchange (needed for E2E encryption).
        return if (x25519Hex.isBlank()) {
            "yaok://add?id=$identityId"
        } else {
            "yaok://add?id=$identityId&x=$x25519Hex"
        }
    }

    private fun generateQrCode(text: String): Bitmap {
        val size = 512
        val writer = QRCodeWriter()
        val bitMatrix = writer.encode(text, BarcodeFormat.QR_CODE, size, size)
        val bitmap = Bitmap.createBitmap(size, size, Bitmap.Config.RGB_565)
        for (x in 0 until size) {
            for (y in 0 until size) {
                bitmap.setPixel(x, y, if (bitMatrix[x, y]) Color.BLACK else Color.WHITE)
            }
        }
        return bitmap
    }
}
