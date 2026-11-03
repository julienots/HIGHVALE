package fr.videostudio.app

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.IBinder
import android.os.PowerManager
import org.json.JSONObject
import java.net.HttpURLConnection
import java.net.URL
import java.net.URLEncoder
import java.util.concurrent.Executors

/** Garde le téléphone connecté au relais : reçoit les commandes de Claude et renvoie les résultats. */
class RelayService : Service() {
    @Volatile private var running = false
    private var loop: Thread? = null
    private val pool = Executors.newFixedThreadPool(3)
    private var wakeLock: PowerManager.WakeLock? = null

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == ACTION_STOP) {
            App.prefs(this).edit().putBoolean("connected", false).apply()
            stopSelf()
            return START_NOT_STICKY
        }
        val n = notification("Connecté à Claude — en attente de demandes")
        if (android.os.Build.VERSION.SDK_INT >= 34) startForeground(1, n, ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE)
        else startForeground(1, n)
        if (!running) {
            running = true
            wakeLock = (getSystemService(Context.POWER_SERVICE) as PowerManager)
                .newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "VideoStudio:relay").apply { acquire(6 * 60 * 60 * 1000L) }
            loop = Thread { pollLoop() }.apply { start() }
        }
        return START_STICKY
    }

    override fun onDestroy() {
        running = false
        loop?.interrupt()
        pool.shutdownNow()
        runCatching { wakeLock?.release() }
        App.relayState = "off"
        App.notifyChanged()
        super.onDestroy()
    }

    private fun pollLoop() {
        val handler = ToolHandler(this)
        val token = App.token(this)
        val base = BuildConfig.RELAY_URL + "/device/" + token
        var backoff = 1000L
        App.relayState = "connecting"; App.notifyChanged()
        while (running) {
            try {
                val info = JSONObject().put("model", android.os.Build.MODEL).put("app", BuildConfig.VERSION_NAME).toString()
                val conn = URL("$base/next?info=" + URLEncoder.encode(info, "UTF-8")).openConnection() as HttpURLConnection
                conn.connectTimeout = 15000
                conn.readTimeout = 40000
                val code = conn.responseCode
                val body = (if (code in 200..299) conn.inputStream else conn.errorStream)?.bufferedReader()?.readText() ?: ""
                conn.disconnect()
                if (code !in 200..299) throw IllegalStateException("HTTP $code")
                if (App.relayState != "online") { App.relayState = "online"; App.relayMessage = ""; App.notifyChanged() }
                backoff = 1000L
                val cmd = JSONObject(body).optJSONObject("command") ?: continue
                val id = cmd.getString("id")
                val tool = cmd.getString("tool")
                val args = cmd.optJSONObject("args") ?: JSONObject()
                App.lastCommand = tool
                App.notifyChanged()
                updateNotification("Claude utilise : ${label(tool)}")
                pool.execute {
                    val result = handler.handle(tool, args)
                    postResult("$base/result/$id", result)
                    updateNotification("Connecté à Claude — en attente de demandes")
                    App.notifyChanged()
                }
            } catch (e: InterruptedException) {
                break
            } catch (e: Exception) {
                if (!running) break
                App.relayState = "error"; App.relayMessage = e.message ?: "réseau indisponible"; App.notifyChanged()
                try { Thread.sleep(backoff) } catch (_: InterruptedException) { break }
                backoff = minOf(backoff * 2, 30000L)
            }
        }
    }

    private fun postResult(url: String, result: JSONObject) {
        repeat(3) { attempt ->
            try {
                val conn = URL(url).openConnection() as HttpURLConnection
                conn.requestMethod = "POST"
                conn.doOutput = true
                conn.connectTimeout = 15000
                conn.readTimeout = 30000
                conn.setRequestProperty("Content-Type", "application/json")
                conn.outputStream.use { it.write(result.toString().toByteArray()) }
                val code = conn.responseCode
                conn.disconnect()
                if (code in 200..299) return
            } catch (_: Exception) {
            }
            Thread.sleep(1000L * (attempt + 1))
        }
    }

    private fun label(tool: String) = when (tool) {
        "view_storyboard", "view_frame" -> "regarde une vidéo"
        "create_montage" -> "lance un montage"
        "get_job" -> "suit le montage"
        "detect_scenes" -> "cherche les plans"
        "analyze_audio" -> "écoute le son"
        else -> "consulte la bibliothèque"
    }

    private fun notification(text: String): Notification {
        val nm = getSystemService(NotificationManager::class.java)
        nm.createNotificationChannel(NotificationChannel(CHANNEL, "Connexion à Claude", NotificationManager.IMPORTANCE_LOW))
        val open = PendingIntent.getActivity(this, 0, Intent(this, MainActivity::class.java), PendingIntent.FLAG_IMMUTABLE)
        val stop = PendingIntent.getService(this, 1, Intent(this, RelayService::class.java).setAction(ACTION_STOP), PendingIntent.FLAG_IMMUTABLE)
        return Notification.Builder(this, CHANNEL)
            .setSmallIcon(R.drawable.ic_stat)
            .setContentTitle("Video Studio")
            .setContentText(text)
            .setContentIntent(open)
            .setOngoing(true)
            .addAction(Notification.Action.Builder(null, "Déconnecter", stop).build())
            .build()
    }

    private fun updateNotification(text: String) {
        if (running) getSystemService(NotificationManager::class.java).notify(1, notification(text))
    }

    companion object {
        private const val CHANNEL = "relay"
        const val ACTION_STOP = "stop"

        fun start(ctx: Context) {
            App.prefs(ctx).edit().putBoolean("connected", true).apply()
            ctx.startForegroundService(Intent(ctx, RelayService::class.java))
        }

        fun stop(ctx: Context) {
            App.prefs(ctx).edit().putBoolean("connected", false).apply()
            ctx.stopService(Intent(ctx, RelayService::class.java))
        }
    }
}
