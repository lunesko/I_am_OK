package app.poruch.ya_ok.ui

interface Navigator {
    fun showOnboarding()
    fun showMain(clearBackStack: Boolean = false)
    fun showSuccess()
    fun showInbox()
    fun showFamily()
    fun showSettings()
    fun navigateBack()
}
