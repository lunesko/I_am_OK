package app.poruch.ya_ok.ui

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.LinearLayout
import android.widget.TextView
import androidx.fragment.app.Fragment
import app.poruch.ya_ok.R
import app.poruch.ya_ok.data.ContactStore

class SuccessFragment : Fragment(R.layout.fragment_success) {
    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)
        view.findViewById<TextView>(R.id.closeButton).setOnClickListener {
            (activity as? Navigator)?.showMain(clearBackStack = true)
        }

        val list = view.findViewById<LinearLayout>(R.id.recipientList)
        list.removeAllViews()

        val contacts = ContactStore.getContacts(requireContext())
        if (contacts.isEmpty()) {
            val empty = TextView(requireContext()).apply {
                text = "Немає доданих людей"
                setTextColor(resources.getColor(R.color.text_secondary, null))
                textSize = 14f
            }
            list.addView(empty)
            return
        }

        val inflater = LayoutInflater.from(requireContext())
        contacts.forEach { contact ->
            val item = inflater.inflate(R.layout.item_contact, list, false)
            item.findViewById<TextView>(R.id.contactAvatar).text =
                contact.name.firstOrNull()?.uppercase() ?: "?"
            item.findViewById<TextView>(R.id.contactName).text = contact.name
            item.findViewById<TextView>(R.id.contactTime).text = "Відправлено"
            item.findViewById<TextView>(R.id.contactStatus).text = "✓"
            list.addView(item)
        }
    }
}
