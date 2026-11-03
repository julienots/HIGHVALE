package fr.videostudio.app

import android.Manifest
import android.app.Activity
import android.content.ClipData
import android.content.ClipboardManager
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.view.View
import android.view.ViewGroup
import android.view.WindowInsets
import android.view.WindowInsetsController
import android.webkit.JavascriptInterface
import android.webkit.WebChromeClient
import android.webkit.WebResourceRequest
import android.webkit.WebResourceResponse
import android.webkit.WebView
import android.webkit.WebViewClient
import android.widget.FrameLayout
import android.widget.Toast
import org.json.JSONArray
import org.json.JSONObject
import java.io.File
import java.io.InputStream
import kotlin.concurrent.thread

class MainActivity : Activity() {
    private lateinit var web: WebView
    private lateinit var root: FrameLayout
    private var fullscreenView: View? = null
    private var fullscreenCallback: WebChromeClient.CustomViewCallback? = null
    private val lib by lazy { Library.get(this) }
    private val tools by lazy { MediaTools(this) }
    private val changed: () -> Unit = { runOnUiThread { web.evaluateJavascript("window.vsRefresh && window.vsRefresh()", null) } }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        root = FrameLayout(this)
        web = WebView(this)
        root.addView(web, FrameLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT))
        setContentView(root)
        root.setOnApplyWindowInsetsListener { v, insets ->
            val bars = insets.getInsets(WindowInsets.Type.systemBars())
            v.setPadding(bars.left, bars.top, bars.right, bars.bottom)
            insets
        }
        web.settings.javaScriptEnabled = true
        web.settings.domStorageEnabled = true
        web.settings.mediaPlaybackRequiresUserGesture = false
        web.settings.allowFileAccess = false
        web.addJavascriptInterface(Bridge(), "VS")
        web.webViewClient = object : WebViewClient() {
            override fun shouldInterceptRequest(view: WebView, request: WebResourceRequest): WebResourceResponse? =
                if (request.url.host == HOST) serve(request) else null

            override fun shouldOverrideUrlLoading(view: WebView, request: WebResourceRequest): Boolean {
                if (request.url.host == HOST) return false
                runCatching { startActivity(Intent(Intent.ACTION_VIEW, request.url)) }
                return true
            }
        }
        web.webChromeClient = object : WebChromeClient() {
            override fun onShowCustomView(view: View, callback: CustomViewCallback) {
                fullscreenView = view
                fullscreenCallback = callback
                root.addView(view, FrameLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT))
                web.visibility = View.GONE
                window.insetsController?.let {
                    it.hide(WindowInsets.Type.systemBars())
                    it.systemBarsBehavior = WindowInsetsController.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE
                }
            }

            override fun onHideCustomView() {
                fullscreenView?.let { root.removeView(it) }
                fullscreenView = null
                web.visibility = View.VISIBLE
                fullscreenCallback?.onCustomViewHidden()
                window.insetsController?.show(WindowInsets.Type.systemBars())
            }
        }
        web.loadUrl("https://$HOST/index.html")
        App.onChanged(changed)

        // Démarré après l'affichage pour ne pas bloquer le thread principal pendant l'init de la WebView
        if (App.prefs(this).getBoolean("connected", false)) root.postDelayed({ RelayService.start(this) }, 1500)
        handleShare(intent)
    }

    override fun onDestroy() {
        App.offChanged(changed)
        super.onDestroy()
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleShare(intent)
    }

    // ------------------------------------------------------------------ fichiers servis à la WebView
    private fun serve(req: WebResourceRequest): WebResourceResponse {
        val path = req.url.path ?: "/"
        return try {
            when {
                path.startsWith("/thumb/") -> {
                    val f = lib.thumbFile(path.removePrefix("/thumb/"))
                    if (f.exists()) WebResourceResponse("image/jpeg", null, f.inputStream()) else notFound()
                }
                path.startsWith("/media/") -> {
                    val m = lib.get(path.removePrefix("/media/")) ?: return notFound()
                    streamMedia(m, req.requestHeaders["Range"] ?: req.requestHeaders["range"])
                }
                else -> {
                    val name = path.trimStart('/').ifEmpty { "index.html" }
                    val mime = when {
                        name.endsWith(".js") -> "application/javascript"
                        name.endsWith(".css") -> "text/css"
                        else -> "text/html"
                    }
                    WebResourceResponse(mime, "utf-8", assets.open("web/$name"))
                }
            }
        } catch (e: Exception) {
            notFound()
        }
    }

    private fun notFound() = WebResourceResponse("text/plain", "utf-8", 404, "Not Found", mapOf(), "".byteInputStream())

    /** Lecture vidéo avec prise en charge des requêtes partielles (avance rapide dans le lecteur). */
    private fun streamMedia(m: Media, range: String?): WebResourceResponse {
        val uri = Uri.parse(m.uri)
        val size = if (uri.scheme == "file") File(uri.path!!).length() else
            contentResolver.openAssetFileDescriptor(uri, "r")?.use { it.length }?.takeIf { it > 0 } ?: m.sizeBytes
        val open: () -> InputStream = { if (uri.scheme == "file") File(uri.path!!).inputStream() else contentResolver.openInputStream(uri)!! }
        val headers = mutableMapOf("Accept-Ranges" to "bytes", "Access-Control-Allow-Origin" to "*")
        val match = range?.let { Regex("bytes=(\\d*)-(\\d*)").find(it) }
        if (match == null || size <= 0) {
            if (size > 0) headers["Content-Length"] = size.toString()
            return WebResourceResponse(m.mime.ifEmpty { "video/mp4" }, null, 200, "OK", headers, open())
        }
        val start = match.groupValues[1].toLongOrNull() ?: 0L
        val end = match.groupValues[2].toLongOrNull()?.coerceAtMost(size - 1) ?: (size - 1)
        val input = open()
        var skipped = 0L
        while (skipped < start) {
            val s = input.skip(start - skipped)
            if (s <= 0) break
            skipped += s
        }
        val len = end - start + 1
        headers["Content-Range"] = "bytes $start-$end/$size"
        headers["Content-Length"] = len.toString()
        return WebResourceResponse(m.mime.ifEmpty { "video/mp4" }, null, 206, "Partial Content", headers, LimitedStream(input, len))
    }

    private class LimitedStream(private val inner: InputStream, private var left: Long) : InputStream() {
        override fun read(): Int = if (left <= 0) -1 else inner.read().also { if (it >= 0) left-- }
        override fun read(b: ByteArray, off: Int, len: Int): Int {
            if (left <= 0) return -1
            val n = inner.read(b, off, minOf(len.toLong(), left).toInt())
            if (n > 0) left -= n
            return n
        }
        override fun close() = inner.close()
    }

    // ------------------------------------------------------------------ ajout de fichiers
    private fun pickFiles() {
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = "*/*"
            putExtra(Intent.EXTRA_MIME_TYPES, arrayOf("video/*", "image/*", "audio/*"))
            putExtra(Intent.EXTRA_ALLOW_MULTIPLE, true)
            addFlags(Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION or Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }
        startActivityForResult(intent, REQ_PICK)
    }

    @Deprecated("Deprecated in Java")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != REQ_PICK || resultCode != RESULT_OK || data == null) return
        val uris = mutableListOf<Uri>()
        data.clipData?.let { c -> for (i in 0 until c.itemCount) uris.add(c.getItemAt(i).uri) }
        if (uris.isEmpty()) data.data?.let { uris.add(it) }
        addAll(uris, shared = false)
    }

    private fun handleShare(intent: Intent?) {
        intent ?: return
        val uris = mutableListOf<Uri>()
        when (intent.action) {
            Intent.ACTION_SEND -> intent.getParcelableExtra(Intent.EXTRA_STREAM, Uri::class.java)?.let { uris.add(it) }
            Intent.ACTION_SEND_MULTIPLE -> intent.getParcelableArrayListExtra(Intent.EXTRA_STREAM, Uri::class.java)?.let { uris.addAll(it) }
            else -> return
        }
        intent.action = null
        addAll(uris, shared = true)
    }

    private fun addAll(uris: List<Uri>, shared: Boolean) {
        if (uris.isEmpty()) return
        toast("Ajout de ${uris.size} fichier(s)…")
        web.evaluateJavascript("window.vsBusy && window.vsBusy(${uris.size})", null)
        thread {
            var ok = 0
            val errors = mutableListOf<String>()
            for (u in uris) {
                try {
                    if (shared) tools.ingestShared(u) else tools.ingestPicked(u)
                    ok++
                } catch (e: Exception) {
                    errors.add(e.message ?: "erreur")
                }
            }
            runOnUiThread {
                toast(if (errors.isEmpty()) "✅ $ok fichier(s) ajouté(s)" else "⚠️ $ok ajouté(s), ${errors.size} échec(s) : ${errors.first()}")
                web.evaluateJavascript("window.vsBusy && window.vsBusy(0)", null)
                App.notifyChanged()
            }
        }
    }

    // ------------------------------------------------------------------ pont JavaScript
    inner class Bridge {
        @JavascriptInterface
        fun state(): String = JSONObject()
            .put("mcpUrl", App.mcpUrl(this@MainActivity))
            .put("connected", App.prefs(this@MainActivity).getBoolean("connected", false))
            .put("relayState", App.relayState)
            .put("relayMessage", App.relayMessage)
            .put("lastCommand", App.lastCommand)
            .put("version", BuildConfig.VERSION_NAME)
            .toString()

        @JavascriptInterface
        fun items(): String = JSONArray(lib.list().map { m ->
            m.publicJson().put("hasThumb", lib.thumbFile(m.id).exists())
        }).toString()

        @JavascriptInterface
        fun jobs(): String = JSONArray(App.engine(this@MainActivity).jobs.values.sortedByDescending { it.createdAt }.take(10).map { it.toJson(lib) }).toString()

        @JavascriptInterface
        fun pick() = runOnUiThread { pickFiles() }

        @JavascriptInterface
        fun update(id: String, name: String, notes: String) {
            lib.update(id, name, notes, null)
        }

        @JavascriptInterface
        fun remove(id: String) {
            lib.remove(id)
        }

        @JavascriptInterface
        fun setConnected(on: Boolean) = runOnUiThread {
            if (on) {
                if (Build.VERSION.SDK_INT >= 33 && checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED) {
                    requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), 7)
                }
                RelayService.start(this@MainActivity)
            } else RelayService.stop(this@MainActivity)
            App.notifyChanged()
        }

        @JavascriptInterface
        fun copy(text: String) = runOnUiThread {
            (getSystemService(CLIPBOARD_SERVICE) as ClipboardManager).setPrimaryClip(ClipData.newPlainText("Video Studio", text))
            toast("Adresse copiée")
        }

        @JavascriptInterface
        fun resetToken() = runOnUiThread {
            App.newToken(this@MainActivity)
            if (App.prefs(this@MainActivity).getBoolean("connected", false)) {
                RelayService.stop(this@MainActivity); RelayService.start(this@MainActivity)
            }
            toast("Nouvelle adresse créée : mets à jour le connecteur dans Claude")
            App.notifyChanged()
        }

        @JavascriptInterface
        fun openExternal(id: String) = runOnUiThread {
            val m = lib.get(id) ?: return@runOnUiThread
            val uri = Uri.parse(m.uri)
            if (uri.scheme == "file") { toast("Lecture dans l'app uniquement pour ce fichier"); return@runOnUiThread }
            runCatching {
                startActivity(Intent(Intent.ACTION_VIEW).setDataAndType(uri, m.mime).addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION))
            }.onFailure { toast("Aucune app pour ouvrir ce fichier") }
        }

        @JavascriptInterface
        fun share(id: String) = runOnUiThread {
            val m = lib.get(id) ?: return@runOnUiThread
            val uri = Uri.parse(m.uri)
            if (uri.scheme == "file") { toast("Partage indisponible pour ce fichier"); return@runOnUiThread }
            startActivity(Intent.createChooser(Intent(Intent.ACTION_SEND).setType(m.mime).putExtra(Intent.EXTRA_STREAM, uri)
                .addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION), "Partager"))
        }
    }

    private fun toast(msg: String) = Toast.makeText(this, msg, Toast.LENGTH_LONG).show()

    @Deprecated("Deprecated in Java")
    override fun onBackPressed() {
        when {
            fullscreenView != null -> web.webChromeClient?.onHideCustomView()
            else -> web.evaluateJavascript("window.vsBack ? window.vsBack() : false") { r ->
                if (r != "true") @Suppress("DEPRECATION") super.onBackPressed()
            }
        }
    }

    companion object {
        private const val HOST = "vs.local"
        private const val REQ_PICK = 42
    }
}
