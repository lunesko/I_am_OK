package app.poruch.ya_ok.ui

import android.content.Intent
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.Typeface
import android.os.Bundle
import android.widget.ImageView
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity
import androidx.core.content.FileProvider
import app.poruch.ya_ok.R
import app.poruch.ya_ok.core.CoreGateway
import com.google.zxing.BarcodeFormat
import com.google.zxing.qrcode.QRCodeWriter
import java.io.File
import java.io.FileOutputStream

class QrCodeActivity : AppCompatActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_qr_code)

        val identityId = CoreGateway.getIdentityId()
        if (identityId == null) {
            finish()
            return
        }

        val x25519Hex = try {
            CoreGateway.getIdentityX25519PublicKeyHex().orEmpty()
        } catch (e: UnsatisfiedLinkError) {
            ""  // Fallback if JNI function not available yet
        }
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
        val userName = getSharedPreferences("ya_ok_prefs", MODE_PRIVATE)
            .getString("user_name", null)
            ?.trim()
            ?.takeIf { it.isNotBlank() }
        
        // Use HTTPS link for messengers (clickable)
        val params = buildString {
            append("id=$identityId")
            if (x25519Hex.isNotBlank()) {
                append("&x=$x25519Hex")
            }
            if (userName != null) {
                append("&name=${android.net.Uri.encode(userName)}")
            }
        }
        val httpsLink = "https://i-am-ok-relay.fly.dev/add?$params"
        
        // Generate QR code image with branding
        val qrBitmap = generateShareableQrCode(buildQrLink(identityId, x25519Hex), userName, httpsLink)
        
        // Save to cache and share
        try {
            val cachePath = File(cacheDir, "images")
            cachePath.mkdirs()
            val file = File(cachePath, "ya_ok_qr.png")
            FileOutputStream(file).use { out ->
                qrBitmap.compress(Bitmap.CompressFormat.PNG, 100, out)
            }
            
            val contentUri = FileProvider.getUriForFile(this, "${packageName}.fileprovider", file)
            
            val text = buildString {
                append("💚 ")
                if (userName != null) {
                    append("$userName запрошує вас до Я ОК!\n\n")
                } else {
                    append("Запрошую вас до Я ОК!\n\n")
                }
                append(httpsLink)
                append("\n\n")
                append("Відскануйте QR або перейдіть за посиланням.\n")
                append("Швидке повідомлення про безпеку для близьких 🇺🇦")
            }
            
            val intent = Intent(Intent.ACTION_SEND).apply {
                type = "image/png"
                putExtra(Intent.EXTRA_STREAM, contentUri)
                putExtra(Intent.EXTRA_TEXT, text)
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            }
            startActivity(Intent.createChooser(intent, "Поділитися QR кодом"))
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }
    
    private fun generateShareableQrCode(qrText: String, userName: String?, httpsLink: String): Bitmap {
        val qrSize = 512
        val padding = 60
        val textHeight = 180
        val totalWidth = qrSize + padding * 2
        val totalHeight = qrSize + padding * 2 + textHeight
        
        // Generate QR code
        val writer = QRCodeWriter()
        val bitMatrix = writer.encode(qrText, BarcodeFormat.QR_CODE, qrSize, qrSize)
        
        // Create bitmap with white background
        val bitmap = Bitmap.createBitmap(totalWidth, totalHeight, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        canvas.drawColor(Color.WHITE)
        
        // Draw QR code
        for (x in 0 until qrSize) {
            for (y in 0 until qrSize) {
                if (bitMatrix[x, y]) {
                    bitmap.setPixel(x + padding, y + padding, Color.BLACK)
                }
            }
        }
        
        // Draw text
        val paint = Paint().apply {
            color = Color.BLACK
            textAlign = Paint.Align.CENTER
            isAntiAlias = true
        }
        
        val centerX = totalWidth / 2f
        var yPos = qrSize + padding + 50f
        
        // Title
        paint.textSize = 40f
        paint.typeface = Typeface.create(Typeface.DEFAULT, Typeface.BOLD)
        val title = if (userName != null) "💚 $userName запрошує вас!" else "💚 Я ОК"
        canvas.drawText(title, centerX, yPos, paint)
        
        yPos += 50f
        
        // Link (truncated)
        paint.textSize = 24f
        paint.typeface = Typeface.DEFAULT
        paint.color = Color.parseColor("#0066CC")
        val shortLink = "i-am-ok-relay.fly.dev/add"
        canvas.drawText(shortLink, centerX, yPos, paint)
        
        yPos += 40f
        
        // Description
        paint.textSize = 20f
        paint.color = Color.GRAY
        canvas.drawText("Відскануйте QR або перейдіть за посиланням.", centerX, yPos, paint)
        
        return bitmap
    }

    private fun buildQrLink(identityId: String, x25519Hex: String): String {
        // Include X25519 public key for initial key exchange (needed for E2E encryption).
        val userName = getSharedPreferences("ya_ok_prefs", MODE_PRIVATE)
            .getString("user_name", null)
            ?.trim()
            ?.takeIf { it.isNotBlank() }
        
        val params = buildString {
            append("id=$identityId")
            if (x25519Hex.isNotBlank()) {
                append("&x=$x25519Hex")
            }
            if (userName != null) {
                append("&name=${android.net.Uri.encode(userName)}")
            }
        }
        return "yaok://add?$params"
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
