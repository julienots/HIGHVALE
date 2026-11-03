package fr.videostudio.app

import android.app.Activity
import android.app.DownloadManager
import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.Environment
import android.provider.OpenableColumns
import android.view.View
import android.view.ViewGroup
import android.view.WindowInsets
import android.view.WindowInsetsController
import android.webkit.CookieManager
import android.webkit.JavascriptInterface
import android.webkit.URLUtil
import android.webkit.ValueCallback
import android.webkit.WebChromeClient
import android.webkit.WebResourceError
import android.webkit.WebResourceRequest
import android.webkit.WebSettings
import android.webkit.WebView
import android.webkit.WebViewClient
import android.widget.FrameLayout
import android.widget.Toast
import org.json.JSONObject
import java.net.HttpURLConnection
import java.net.URL
import java.net.URLEncoder
import kotlin.concurrent.thread

class MainActivity : Activity() {

    private lateinit var web: WebView
    private lateinit var root: FrameLayout
    private var fileCallback: ValueCallback<Array<Uri>>? = null
    private var fullscreenView: View? = null
    private var fullscreenCallback: WebChromeClient.CustomViewCallback? = null
    private val prefs by lazy { getSharedPreferences("settings", Context.MODE_PRIVATE) }

    private val serverUrl get() = prefs.getString("url", "") ?: ""
    private val token get() = prefs.getString("token", "") ?: ""

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        root = FrameLayout(this)
        web = WebView(this)
        root.addView(web, FrameLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT))
        setContentView(root)
        // Respecte la barre d'état et la barre de navigation
        root.setOnApplyWindowInsetsListener { v, insets ->
            if (Build.VERSION.SDK_INT >= 30) {
                val bars = insets.getInsets(WindowInsets.Type.systemBars())
                v.setPadding(bars.left, bars.top, bars.right, bars.bottom)
            } else {
                @Suppress("DEPRECATION")
                v.setPadding(insets.systemWindowInsetLeft, insets.systemWindowInsetTop, insets.systemWindowInsetRight, insets.systemWindowInsetBottom)
            }
            insets
        }

        web.settings.apply {
            javaScriptEnabled = true
            domStorageEnabled = true
            mediaPlaybackRequiresUserGesture = false
            allowFileAccess = false
            mixedContentMode = WebSettings.MIXED_CONTENT_COMPATIBILITY_MODE
            userAgentString = "$userAgentString VideoStudioApp/1.0"
        }
        CookieManager.getInstance().setAcceptCookie(true)
        web.addJavascriptInterface(Bridge(), "VideoStudioApp")

        web.webViewClient = object : WebViewClient() {
            override fun shouldOverrideUrlLoading(view: WebView, request: WebResourceRequest): Boolean {
                val url = request.url.toString()
                // Les liens externes (claude.ai, etc.) s'ouvrent dans le navigateur
                if (url.startsWith("file:///android_asset/") || (serverUrl.isNotEmpty() && url.startsWith(serverUrl))) return false
                runCatching { startActivity(Intent(Intent.ACTION_VIEW, request.url)) }
                return true
            }

            override fun onReceivedError(view: WebView, request: WebResourceRequest, error: WebResourceError) {
                if (request.isForMainFrame && !request.url.toString().startsWith("file:")) {
                    showSetup("Serveur injoignable : ${error.description}")
                }
            }
        }

        web.webChromeClient = object : WebChromeClient() {
            override fun onShowFileChooser(view: WebView, callback: ValueCallback<Array<Uri>>, params: FileChooserParams): Boolean {
                fileCallback?.onReceiveValue(null)
                fileCallback = callback
                val intent = Intent(Intent.ACTION_GET_CONTENT).apply {
                    addCategory(Intent.CATEGORY_OPENABLE)
                    type = "*/*"
                    putExtra(Intent.EXTRA_MIME_TYPES, arrayOf("video/*", "image/*", "audio/*"))
                    putExtra(Intent.EXTRA_ALLOW_MULTIPLE, true)
                }
                return try {
                    startActivityForResult(Intent.createChooser(intent, "Ajouter des fichiers"), REQ_FILES)
                    true
                } catch (e: Exception) {
                    fileCallback = null
                    false
                }
            }

            override fun onShowCustomView(view: View, callback: CustomViewCallback) {
                fullscreenView = view
                fullscreenCallback = callback
                root.addView(view, FrameLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT))
                web.visibility = View.GONE
                setFullscreenBars(true)
            }

            override fun onHideCustomView() {
                fullscreenView?.let { root.removeView(it) }
                fullscreenView = null
                web.visibility = View.VISIBLE
                fullscreenCallback?.onCustomViewHidden()
                setFullscreenBars(false)
            }
        }

        // Téléchargement des montages dans le dossier Téléchargements
        web.setDownloadListener { url, userAgent, contentDisposition, mimeType, _ ->
            try {
                val name = URLUtil.guessFileName(url, contentDisposition, mimeType)
                val req = DownloadManager.Request(Uri.parse(url)).apply {
                    setMimeType(mimeType)
                    addRequestHeader("User-Agent", userAgent)
                    setTitle(name)
                    setNotificationVisibility(DownloadManager.Request.VISIBILITY_VISIBLE_NOTIFY_COMPLETED)
                    setDestinationInExternalPublicDir(Environment.DIRECTORY_DOWNLOADS, "VideoStudio/$name")
                }
                (getSystemService(DOWNLOAD_SERVICE) as DownloadManager).enqueue(req)
                toast("Téléchargement de $name…")
            } catch (e: Exception) {
                toast("Téléchargement impossible : ${e.message}")
            }
        }

        if (serverUrl.isEmpty() || token.isEmpty()) showSetup(null) else openStudio()
        handleShare(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleShare(intent)
    }

    private fun openStudio() {
        web.loadUrl("$serverUrl/?token=" + URLEncoder.encode(token, "UTF-8"))
    }

    private fun showSetup(error: String?) {
        val q = if (error != null) "?error=" + URLEncoder.encode(error, "UTF-8") else ""
        web.post { web.loadUrl("file:///android_asset/setup.html$q") }
    }

    private fun setFullscreenBars(on: Boolean) {
        if (Build.VERSION.SDK_INT >= 30) {
            window.insetsController?.let {
                if (on) {
                    it.hide(WindowInsets.Type.systemBars())
                    it.systemBarsBehavior = WindowInsetsController.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE
                } else it.show(WindowInsets.Type.systemBars())
            }
        }
    }

    // ---------- Partage depuis la galerie ----------
    private fun handleShare(intent: Intent?) {
        if (intent == null) return
        val uris = mutableListOf<Uri>()
        when (intent.action) {
            Intent.ACTION_SEND -> getUriExtra(intent)?.let { uris.add(it) }
            Intent.ACTION_SEND_MULTIPLE -> getUriListExtra(intent)?.let { uris.addAll(it) }
            else -> return
        }
        intent.action = null
        if (uris.isEmpty()) return
        if (serverUrl.isEmpty() || token.isEmpty()) {
            toast("Configure d'abord l'adresse du serveur.")
            return
        }
        toast("Envoi de ${uris.size} fichier(s)…")
        thread {
            var ok = 0
            val errors = mutableListOf<String>()
            for (uri in uris) {
                try {
                    uploadUri(uri); ok++
                } catch (e: Exception) {
                    errors.add(e.message ?: "erreur")
                }
            }
            runOnUiThread {
                toast(if (errors.isEmpty()) "✅ $ok fichier(s) ajouté(s)" else "❌ ${errors.size} échec(s) : ${errors.first()}")
                web.evaluateJavascript("window.vsRefresh && window.vsRefresh()", null)
            }
        }
    }

    @Suppress("DEPRECATION")
    private fun getUriExtra(i: Intent): Uri? =
        if (Build.VERSION.SDK_INT >= 33) i.getParcelableExtra(Intent.EXTRA_STREAM, Uri::class.java) else i.getParcelableExtra(Intent.EXTRA_STREAM)

    @Suppress("DEPRECATION")
    private fun getUriListExtra(i: Intent): List<Uri>? =
        if (Build.VERSION.SDK_INT >= 33) i.getParcelableArrayListExtra(Intent.EXTRA_STREAM, Uri::class.java) else i.getParcelableArrayListExtra(Intent.EXTRA_STREAM)

    private fun uploadUri(uri: Uri) {
        var name = "fichier"
        var size = -1L
        contentResolver.query(uri, null, null, null, null)?.use { c ->
            if (c.moveToFirst()) {
                val ni = c.getColumnIndex(OpenableColumns.DISPLAY_NAME)
                val si = c.getColumnIndex(OpenableColumns.SIZE)
                if (ni >= 0) name = c.getString(ni) ?: name
                if (si >= 0 && !c.isNull(si)) size = c.getLong(si)
            }
        }
        val mime = contentResolver.getType(uri) ?: "application/octet-stream"
        val url = URL("$serverUrl/api/upload-raw?name=" + URLEncoder.encode(name, "UTF-8"))
        val conn = url.openConnection() as HttpURLConnection
        try {
            conn.requestMethod = "PUT"
            conn.doOutput = true
            conn.connectTimeout = 20000
            conn.readTimeout = 600000
            conn.setRequestProperty("Authorization", "Bearer $token")
            conn.setRequestProperty("Content-Type", mime)
            if (size > 0) conn.setFixedLengthStreamingMode(size) else conn.setChunkedStreamingMode(1 shl 16)
            contentResolver.openInputStream(uri)!!.use { input ->
                conn.outputStream.use { out -> input.copyTo(out, 1 shl 16) }
            }
            val code = conn.responseCode
            if (code !in 200..299) {
                val msg = conn.errorStream?.bufferedReader()?.readText() ?: ""
                throw Exception("$name : HTTP $code ${runCatching { JSONObject(msg).optString("error") }.getOrDefault("")}")
            }
        } finally {
            conn.disconnect()
        }
    }

    // ---------- Pont JavaScript ----------
    inner class Bridge {
        @JavascriptInterface
        fun getSettings(): String = JSONObject().put("url", serverUrl).put("token", token).toString()

        @JavascriptInterface
        fun saveSettings(url: String, tok: String) {
            prefs.edit().putString("url", url).putString("token", tok).apply()
            runOnUiThread { openStudio() }
        }

        @JavascriptInterface
        fun resetSettings() {
            prefs.edit().remove("token").apply()
            showSetup(null)
        }

        @JavascriptInterface
        fun copy(text: String) {
            runOnUiThread {
                (getSystemService(CLIPBOARD_SERVICE) as ClipboardManager).setPrimaryClip(ClipData.newPlainText("Video Studio", text))
            }
        }
    }

    private fun toast(msg: String) = Toast.makeText(this, msg, Toast.LENGTH_LONG).show()

    @Deprecated("Deprecated in Java")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != REQ_FILES) return
        val cb = fileCallback ?: return
        fileCallback = null
        if (resultCode != RESULT_OK || data == null) {
            cb.onReceiveValue(null); return
        }
        val list = mutableListOf<Uri>()
        data.clipData?.let { clip -> for (i in 0 until clip.itemCount) list.add(clip.getItemAt(i).uri) }
        if (list.isEmpty()) data.data?.let { list.add(it) }
        cb.onReceiveValue(list.toTypedArray())
    }

    @Deprecated("Deprecated in Java")
    override fun onBackPressed() {
        when {
            fullscreenView != null -> web.webChromeClient?.onHideCustomView()
            web.canGoBack() -> web.goBack()
            else -> @Suppress("DEPRECATION") super.onBackPressed()
        }
    }

    companion object {
        private const val REQ_FILES = 42
    }
}
