package app.poruch.ya_ok.ui

import android.os.Bundle
import android.view.View
import android.widget.Toast
import androidx.fragment.app.Fragment
import app.poruch.ya_ok.R
import app.poruch.ya_ok.core.CoreGateway
import com.google.android.material.button.MaterialButton

class OnboardingFragment : Fragment(R.layout.fragment_onboarding) {
    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)

        val nameInput = view.findViewById<android.widget.EditText>(R.id.userNameInput)
        val primaryButton = view.findViewById<MaterialButton>(R.id.primaryActionButton)
        val secondaryButton = view.findViewById<MaterialButton>(R.id.secondaryActionButton)

        primaryButton.setOnClickListener {
            val userName = nameInput.text?.toString()?.trim().orEmpty()
            if (userName.isBlank()) {
                Toast.makeText(requireContext(), "Введіть ваше ім'я", Toast.LENGTH_SHORT).show()
                return@setOnClickListener
            }
            
            val ok = CoreGateway.ensureIdentity()
            if (ok) {
                // Save user name
                requireContext().getSharedPreferences("ya_ok_prefs", android.content.Context.MODE_PRIVATE)
                    .edit()
                    .putString("user_name", userName)
                    .apply()
                
                (activity as? Navigator)?.showMain(clearBackStack = true)
            } else {
                Toast.makeText(requireContext(), "Не вдалося створити ідентичність", Toast.LENGTH_SHORT).show()
            }
        }

        secondaryButton.setOnClickListener {
            Toast.makeText(requireContext(), "Відновлення поки не доступне", Toast.LENGTH_SHORT).show()
        }
    }
}
