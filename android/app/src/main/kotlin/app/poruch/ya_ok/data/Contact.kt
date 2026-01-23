package app.poruch.ya_ok.data

data class Contact(
    val id: String,
    val name: String,
    val lastCheckin: Long? = null
)
