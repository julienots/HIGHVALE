package fr.videostudio.app

import android.app.Application
import android.content.Context
import android.util.Base64
import java.security.SecureRandom

class App : Application() {
    companion object {
        @Volatile private var engineInstance: MontageEngine? = null
        fun engine(ctx: Context): MontageEngine = engineInstance ?: synchronized(this) {
            engineInstance ?: MontageEngine(ctx.applicationContext).also { engineInstance = it }
        }

        /** État de la connexion au relais, affiché dans l'app. */
        @Volatile var relayState = "off"   // off | connecting | online | error
        @Volatile var relayMessage = ""
        @Volatile var lastCommand = ""

        private val listeners = mutableSetOf<() -> Unit>()
        fun onChanged(l: () -> Unit) = synchronized(listeners) { listeners.add(l) }
        fun offChanged(l: () -> Unit) = synchronized(listeners) { listeners.remove(l) }
        fun notifyChanged() = synchronized(listeners) { listeners.toList() }.forEach { it() }

        fun prefs(ctx: Context) = ctx.getSharedPreferences("settings", Context.MODE_PRIVATE)

        /** Jeton secret de ce téléphone (créé au premier lancement). */
        fun token(ctx: Context): String {
            val p = prefs(ctx)
            p.getString("token", null)?.let { return it }
            return newToken(ctx)
        }

        fun newToken(ctx: Context): String {
            val b = ByteArray(24).also { SecureRandom().nextBytes(it) }
            val t = Base64.encodeToString(b, Base64.URL_SAFE or Base64.NO_WRAP or Base64.NO_PADDING)
            prefs(ctx).edit().putString("token", t).apply()
            return t
        }

        fun mcpUrl(ctx: Context) = BuildConfig.RELAY_URL + "/mcp/" + token(ctx)
    }
}
