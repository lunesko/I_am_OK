package app.poruch.ya_ok.ui

import android.app.AlertDialog
import android.content.Intent
import android.os.Bundle
import android.text.InputType
import android.text.format.DateUtils
import android.view.LayoutInflater
import android.view.View
import android.widget.EditText
import android.widget.LinearLayout
import android.widget.TextView
import android.widget.Toast
import androidx.activity.result.contract.ActivityResultContracts
import androidx.fragment.app.Fragment
import app.poruch.ya_ok.R
import app.poruch.ya_ok.core.CoreGateway
import app.poruch.ya_ok.data.Contact
import app.poruch.ya_ok.data.ContactStore
import com.google.android.material.button.MaterialButton

class FamilyFragment : Fragment(R.layout.fragment_family) {
    private lateinit var contactsContainer: LinearLayout
    
    private val qrScannerLauncher = registerForActivityResult(
        ActivityResultContracts.StartActivityForResult()
    ) { result ->
        if (result.resultCode == android.app.Activity.RESULT_OK) {
            val scannedId = result.data?.getStringExtra("scanned_id")
            if (!scannedId.isNullOrBlank()) {
                showAddContactDialogWithId(scannedId)
            }
        }
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)
        view.findViewById<TextView>(R.id.backButton).setOnClickListener {
            (activity as? Navigator)?.navigateBack()
        }

        contactsContainer = view.findViewById(R.id.contactsContainer)
        view.findViewById<View>(R.id.addContactCard).setOnClickListener {
            showAddContactDialog()
        }
        view.findViewById<View>(R.id.showQrCard).setOnClickListener {
            startActivity(Intent(requireContext(), QrCodeActivity::class.java))
        }
        view.findViewById<View>(R.id.scanQrCard).setOnClickListener {
            qrScannerLauncher.launch(Intent(requireContext(), QrScannerActivity::class.java))
        }
        view.findViewById<MaterialButton>(R.id.feedbackButton).setOnClickListener {
            val result = CoreGateway.sendText("Вдома все добре")
            if (result == 0) {
                Toast.makeText(requireContext(), "Повідомлення надіслано", Toast.LENGTH_SHORT).show()
            } else {
                Toast.makeText(requireContext(), "Помилка ($result)", Toast.LENGTH_SHORT).show()
            }
        }

        renderContacts()
    }

    private fun renderContacts() {
        contactsContainer.removeAllViews()
        val contacts = ContactStore.getContacts(requireContext())
        if (contacts.isEmpty()) {
            val empty = TextView(requireContext()).apply {
                text = "Поки немає людей"
                setTextColor(resources.getColor(R.color.text_secondary, null))
                textSize = 14f
            }
            contactsContainer.addView(empty)
            return
        }

        val inflater = LayoutInflater.from(requireContext())
        contacts.forEach { contact ->
            val item = inflater.inflate(R.layout.item_contact, contactsContainer, false)
            item.findViewById<TextView>(R.id.contactAvatar).text =
                contact.name.firstOrNull()?.uppercase() ?: "?"
            item.findViewById<TextView>(R.id.contactName).text = contact.name
            val timeText = contact.lastCheckin?.let {
                DateUtils.getRelativeTimeSpanString(it, System.currentTimeMillis(), DateUtils.MINUTE_IN_MILLIS)
                    .toString()
            } ?: "Ще не бачив"
            item.findViewById<TextView>(R.id.contactTime).text = timeText
            contactsContainer.addView(item)
        }
    }

    private fun showAddContactDialog() {
        showAddContactDialogWithId(null)
    }

    private fun showAddContactDialogWithId(scannedId: String?) {
        val nameInput = EditText(requireContext()).apply {
            hint = "Ім'я"
            inputType = InputType.TYPE_CLASS_TEXT
        }
        val idInput = EditText(requireContext()).apply {
            hint = "ID (необов'язково)"
            inputType = InputType.TYPE_CLASS_TEXT
            if (scannedId != null) {
                setText(scannedId)
                isEnabled = false
            }
        }
        val container = LinearLayout(requireContext()).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(50, 20, 50, 0)
            addView(nameInput)
            addView(idInput)
        }

        AlertDialog.Builder(requireContext())
            .setTitle("Додати людину")
            .setView(container)
            .setPositiveButton("Додати") { _, _ ->
                val name = nameInput.text?.toString()?.trim().orEmpty()
                val id = idInput.text?.toString()?.trim().orEmpty()
                if (name.isBlank()) {
                    Toast.makeText(requireContext(), "Вкажіть ім'я", Toast.LENGTH_SHORT).show()
                    return@setPositiveButton
                }
                val contactId = if (id.isBlank()) "local_${System.currentTimeMillis()}" else id
                ContactStore.addContact(requireContext(), Contact(contactId, name))
                renderContacts()
                Toast.makeText(requireContext(), "Людину додано", Toast.LENGTH_SHORT).show()
            }
            .setNegativeButton("Скасувати", null)
            .show()
    }
}
