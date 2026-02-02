package app.poruch.ya_ok.ui

import android.app.AlertDialog
import android.content.Context
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
    private var initialAddContactId: String? = null

    companion object {
        private const val ARG_ADD_CONTACT_ID = "add_contact_id"

        fun newInstance(addContactId: String?): FamilyFragment {
            return FamilyFragment().apply {
                arguments = Bundle().apply {
                    putString(ARG_ADD_CONTACT_ID, addContactId)
                }
            }
        }
    }
    
    private val qrScannerLauncher = registerForActivityResult(
        ActivityResultContracts.StartActivityForResult()
    ) { result ->
        if (result.resultCode == android.app.Activity.RESULT_OK) {
            val scannedId = result.data?.getStringExtra("scanned_id")
            if (!scannedId.isNullOrBlank()) {
                val parsed = parseContactQr(scannedId)
                // Register peer keys in core if present (enables decryptable packets).
                parsed.x25519Hex?.let { x ->
                    CoreGateway.addPeer(parsed.id, x)
                }
                showAddContactDialogWithId(parsed.id)
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        initialAddContactId = arguments?.getString(ARG_ADD_CONTACT_ID)?.takeIf { it.isNotBlank() }
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

        // Deep link / prefill: open "add contact" dialog.
        initialAddContactId?.let { addId ->
            initialAddContactId = null
            view.post { showAddContactDialogWithId(addId) }
        }
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
        // Try to get name from deep link first (stored in pending_peers)
        var prefillName: String? = null
        if (scannedId != null) {
            prefillName = requireContext().getSharedPreferences("ya_ok_pending_peers", Context.MODE_PRIVATE)
                .getString("peer_name_$scannedId", null)
        }
        
        // Parse QR to get name if available
        val qrData = if (scannedId != null) parseContactQr(scannedId) else null
        if (prefillName == null) {
            prefillName = qrData?.name
        }
        
        val nameInput = EditText(requireContext()).apply {
            hint = "Ім'я"
            inputType = InputType.TYPE_CLASS_TEXT
            // Auto-fill name from deep link or QR if available
            if (!prefillName.isNullOrBlank()) {
                setText(prefillName)
            }
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
                
                // Parse QR to get x25519 key if available
                val qrData = if (scannedId != null) parseContactQr(scannedId) else ContactQr(contactId, null, null)
                
                ContactStore.addContact(requireContext(), Contact(qrData.id, name))
                
                // Sync peer with Core for E2E encryption
                if (!qrData.x25519Hex.isNullOrBlank()) {
                    val result = CoreGateway.addPeer(qrData.id, qrData.x25519Hex)
                    if (result == 0) {
                        // Send auto-add request to other user
                        val myId = CoreGateway.getIdentityId()
                        val myName = requireContext().getSharedPreferences("ya_ok_prefs", Context.MODE_PRIVATE)
                            .getString("user_name", "Користувач")
                        val myX25519 = try {
                            CoreGateway.getIdentityX25519PublicKeyHex()
                        } catch (e: UnsatisfiedLinkError) {
                            null
                        }
                        
                        println("🔵 Sending contact_add_request: id=$myId, name=$myName")
                        
                        // Send special message with contact info for auto-add
                        val addRequestJson = buildString {
                            append("{\"type\":\"contact_add_request\",")
                            append("\"id\":\"$myId\",")
                            append("\"name\":\"$myName\"")
                            if (!myX25519.isNullOrBlank()) {
                                append(",\"x25519\":\"$myX25519\"")
                            }
                            append("}")
                        }
                        val sendResult = CoreGateway.sendText(addRequestJson)
                        println("🔵 SendText result: $sendResult")
                        
                        Toast.makeText(requireContext(), "✅ Людину додано і синхронізовано", Toast.LENGTH_SHORT).show()
                    } else {
                        Toast.makeText(requireContext(), "⚠️ Людину додано (код синхронізації: $result)", Toast.LENGTH_SHORT).show()
                    }
                } else {
                    Toast.makeText(requireContext(), "Людину додано", Toast.LENGTH_SHORT).show()
                }
                
                renderContacts()
            }
            .setNegativeButton("Скасувати", null)
            .show()
    }

    private fun normalizeContactId(raw: String): String {
        val trimmed = raw.trim()
        if (trimmed.startsWith("yaok://", ignoreCase = true)) {
            val uri = runCatching { android.net.Uri.parse(trimmed) }.getOrNull()
            val fromQuery = uri?.getQueryParameter("id")?.trim()
            if (!fromQuery.isNullOrBlank()) return fromQuery
            val last = uri?.lastPathSegment?.trim()
            if (!last.isNullOrBlank() && !last.equals("add", ignoreCase = true)) return last
        }
        return trimmed
    }

    private data class ContactQr(val id: String, val x25519Hex: String?, val name: String?)

    private fun parseContactQr(raw: String): ContactQr {
        val trimmed = raw.trim()
        if (trimmed.startsWith("yaok://", ignoreCase = true)) {
            val uri = runCatching { android.net.Uri.parse(trimmed) }.getOrNull()
            val id = uri?.getQueryParameter("id")?.trim().orEmpty()
            val x = uri?.getQueryParameter("x")?.trim()
            val name = uri?.getQueryParameter("name")?.trim()
            val normalizedId = if (id.isNotBlank()) id else normalizeContactId(trimmed)
            return ContactQr(normalizedId, x?.takeIf { it.isNotBlank() }, name?.takeIf { it.isNotBlank() })
        }
        return ContactQr(normalizeContactId(trimmed), null, null)
    }
}
