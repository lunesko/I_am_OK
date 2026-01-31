package app.poruch.ya_ok.util

import android.content.Context
import android.location.LocationManager
import androidx.core.location.LocationManagerCompat

object LocationUtils {
    fun isLocationEnabled(context: Context): Boolean {
        val lm = context.getSystemService(Context.LOCATION_SERVICE) as? LocationManager
            ?: return false
        return LocationManagerCompat.isLocationEnabled(lm)
    }
}

