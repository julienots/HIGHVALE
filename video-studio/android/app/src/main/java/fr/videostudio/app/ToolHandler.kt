package fr.videostudio.app

import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.BatteryManager
import android.os.Environment
import android.os.StatFs
import org.json.JSONArray
import org.json.JSONObject
import kotlin.math.max
import kotlin.math.min

/** Exécute sur le téléphone les outils MCP appelés par Claude. Renvoie un résultat MCP ({content, isError}). */
class ToolHandler(private val ctx: Context) {
    private val lib = Library.get(ctx)
    private val tools = MediaTools(ctx)
    private val engine get() = App.engine(ctx)

    private fun text(s: String) = JSONObject().put("type", "text").put("text", s)
    private fun image(b64: String) = JSONObject().put("type", "image").put("data", b64).put("mimeType", "image/jpeg")
    private fun ok(vararg parts: JSONObject) = JSONObject().put("content", JSONArray(parts.toList()))
    private fun json(o: Any) = ok(text(if (o is JSONObject) o.toString(2) else (o as JSONArray).toString(2)))
    private fun err(msg: String) = JSONObject().put("content", JSONArray().put(text(msg))).put("isError", true)

    fun handle(tool: String, a: JSONObject): JSONObject = try {
        when (tool) {
            "list_media" -> {
                val items = lib.list(a.optString("type").ifEmpty { null }, a.optString("kind").ifEmpty { null }, a.optString("search").ifEmpty { null })
                json(JSONObject().put("count", items.size).put("items", JSONArray(items.map { it.publicJson() })))
            }
            "get_media_info" -> {
                val m = lib.mustGet(a.getString("media_id"))
                val o = m.publicJson().put("mime", m.mime)
                m.spec?.let { o.put("montageSpec", it) }
                json(o)
            }
            "view_frame" -> {
                val m = lib.mustGet(a.getString("media_id"))
                val t = a.optDouble("time", 0.0)
                val b = tools.frame(m, t, a.optInt("width", 768).coerceIn(160, 1280))
                ok(text("${m.name} @ ${MediaTools.fmtTime(t)}"), image(MediaTools.jpegBase64(b)))
            }
            "view_storyboard" -> {
                val m = lib.mustGet(a.getString("media_id"))
                val d = m.duration ?: 0.0
                val start = max(0.0, a.optDouble("start", 0.0))
                val end = min(if (a.has("end")) a.getDouble("end") else d, d)
                val (b, times) = tools.storyboard(m, start, end, a.optInt("columns", 4).coerceIn(1, 6), a.optInt("rows", 3).coerceIn(1, 6))
                ok(
                    text("${m.name} (${MediaTools.r2(d)} s) — images aux instants (s), de gauche à droite puis de haut en bas : ${times.joinToString(", ")}"),
                    image(MediaTools.jpegBase64(b, 70)),
                )
            }
            "detect_scenes" -> {
                val m = lib.mustGet(a.getString("media_id"))
                val cuts = tools.detectScenes(m, a.optDouble("threshold", 0.35), a.optDouble("interval", 0.5))
                json(JSONObject().put("media_id", m.id).put("duration", m.duration).put("sceneChanges", JSONArray(cuts))
                    .put("note", "Détection par échantillonnage : précision d'environ ±0,5 s, vérifie avec view_frame."))
            }
            "analyze_audio" -> {
                val m = lib.mustGet(a.getString("media_id"))
                json(tools.analyzeAudio(m, a.optDouble("noise_db", -35.0), a.optDouble("min_silence", 0.5)))
            }
            "create_montage" -> {
                val job = engine.start(a)
                json(job.toJson(lib).put("hint", "Rendu lancé sur le téléphone. Appelle get_job avec ce job_id pour suivre l'avancement."))
            }
            "get_job" -> {
                val job = engine.jobs[a.getString("job_id")] ?: return err("Montage introuvable (l'app a peut-être été redémarrée).")
                val until = System.currentTimeMillis() + (a.optDouble("wait_seconds", 40.0).coerceIn(0.0, 90.0) * 1000).toLong()
                while ((job.status == "queued" || job.status == "running") && System.currentTimeMillis() < until) Thread.sleep(500)
                json(job.toJson(lib))
            }
            "list_jobs" -> json(JSONArray(engine.jobs.values.sortedByDescending { it.createdAt }.take(20).map { it.toJson(lib) }))
            "update_media" -> {
                val tags = a.optJSONArray("tags")?.let { t -> List(t.length()) { t.getString(it) } }
                json(lib.update(a.getString("media_id"), a.optString("name").ifEmpty { null }, if (a.has("notes")) a.getString("notes") else null, tags).publicJson())
            }
            "delete_media" -> {
                val m = lib.remove(a.getString("media_id"))
                App.notifyChanged()
                json(JSONObject().put("deleted", m.id).put("name", m.name))
            }
            "import_from_url" -> {
                val m = tools.importFromUrl(a.getString("url"), a.optString("name").ifEmpty { null })
                App.notifyChanged()
                json(m.publicJson())
            }
            "device_status" -> {
                val st = StatFs(Environment.getExternalStorageDirectory().path)
                val bat = ctx.registerReceiver(null, IntentFilter(Intent.ACTION_BATTERY_CHANGED))
                val level = bat?.let { it.getIntExtra(BatteryManager.EXTRA_LEVEL, -1) * 100 / max(1, it.getIntExtra(BatteryManager.EXTRA_SCALE, 100)) }
                json(JSONObject().put("connected", true).put("device", android.os.Build.MODEL)
                    .put("freeSpaceGB", MediaTools.r2(st.availableBytes / 1e9)).put("batteryPercent", level)
                    .put("mediaCount", lib.list().size)
                    .put("runningJobs", engine.jobs.values.count { it.status == "running" || it.status == "queued" }))
            }
            else -> err("Outil inconnu sur le téléphone : $tool (mets à jour l'app)")
        }
    } catch (e: Throwable) {
        err(e.message ?: e.toString())
    }
}
