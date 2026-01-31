package app.poruch.ya_ok.ui

import android.os.Bundle
import android.view.View
import androidx.fragment.app.Fragment
import app.poruch.ya_ok.MainActivity
import app.poruch.ya_ok.R
import com.google.android.material.button.MaterialButton

class LockFragment : Fragment(R.layout.fragment_lock) {
    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)
        view.findViewById<MaterialButton>(R.id.unlockButton).setOnClickListener {
            (activity as? MainActivity)?.retryUnlock()
        }
    }
}

