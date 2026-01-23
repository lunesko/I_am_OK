package app.poruch.ya_ok.data

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject

object ContactStore {
    fun getContacts(context: Context): MutableList<Contact> {
        val json = AppPreferences.getContactsJson(context)
        val array = JSONArray(json)
        val contacts = mutableListOf<Contact>()
        for (i in 0 until array.length()) {
            val obj = array.getJSONObject(i)
            contacts.add(
                Contact(
                    id = obj.optString("id"),
                    name = obj.optString("name"),
                    lastCheckin = if (obj.has("lastCheckin")) obj.optLong("lastCheckin") else null
                )
            )
        }
        return contacts
    }

    fun saveContacts(context: Context, contacts: List<Contact>) {
        val array = JSONArray()
        contacts.forEach { contact ->
            val obj = JSONObject()
            obj.put("id", contact.id)
            obj.put("name", contact.name)
            contact.lastCheckin?.let { obj.put("lastCheckin", it) }
            array.put(obj)
        }
        AppPreferences.setContactsJson(context, array.toString())
    }

    fun addContact(context: Context, contact: Contact) {
        val contacts = getContacts(context)
        contacts.add(contact)
        saveContacts(context, contacts)
    }

    fun updateLastCheckin(context: Context, contactId: String, timeMillis: Long) {
        val contacts = getContacts(context)
        val updated = contacts.map { contact ->
            if (contact.id == contactId) contact.copy(lastCheckin = timeMillis) else contact
        }
        saveContacts(context, updated)
    }
}
