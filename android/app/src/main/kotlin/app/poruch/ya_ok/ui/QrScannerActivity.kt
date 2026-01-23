package app.poruch.ya_ok.ui

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Bundle
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import com.journeyapps.barcodescanner.CaptureManager
import com.journeyapps.barcodescanner.DecoratedBarcodeView

class QrScannerActivity : AppCompatActivity() {
    private lateinit var barcodeView: DecoratedBarcodeView
    private lateinit var capture: CaptureManager

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        barcodeView = DecoratedBarcodeView(this)
        setContentView(barcodeView)

        if (ContextCompat.checkSelfPermission(this, Manifest.permission.CAMERA) 
            != PackageManager.PERMISSION_GRANTED) {
            ActivityCompat.requestPermissions(this, arrayOf(Manifest.permission.CAMERA), 100)
        } else {
            startScanning(savedInstanceState)
        }
    }

    private fun startScanning(savedInstanceState: Bundle?) {
        capture = CaptureManager(this, barcodeView)
        capture.initializeFromIntent(intent, savedInstanceState)
        capture.decode()

        barcodeView.decodeContinuous { result ->
            result?.let {
                val scannedId = it.text
                if (scannedId.isNotBlank()) {
                    val resultIntent = Intent().apply {
                        putExtra("scanned_id", scannedId)
                    }
                    setResult(RESULT_OK, resultIntent)
                    finish()
                } else {
                    Toast.makeText(this, "Невірний QR-код", Toast.LENGTH_SHORT).show()
                }
            }
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == 100 && grantResults.isNotEmpty() 
            && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
            startScanning(null)
        } else {
            Toast.makeText(this, "Потрібен доступ до камери", Toast.LENGTH_SHORT).show()
            finish()
        }
    }

    override fun onResume() {
        super.onResume()
        if (::capture.isInitialized) {
            capture.onResume()
        }
    }

    override fun onPause() {
        super.onPause()
        if (::capture.isInitialized) {
            capture.onPause()
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        if (::capture.isInitialized) {
            capture.onDestroy()
        }
    }

    override fun onSaveInstanceState(outState: Bundle) {
        super.onSaveInstanceState(outState)
        if (::capture.isInitialized) {
            capture.onSaveInstanceState(outState)
        }
    }
}
