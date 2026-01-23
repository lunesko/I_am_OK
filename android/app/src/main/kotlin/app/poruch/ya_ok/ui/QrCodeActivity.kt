package app.poruch.ya_ok.ui

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

        findViewById<TextView>(R.id.identityIdText).text = identityId
        findViewById<ImageView>(R.id.qrCodeImage).setImageBitmap(generateQrCode(identityId))
        findViewById<TextView>(R.id.closeButton).setOnClickListener { finish() }
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
