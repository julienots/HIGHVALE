package fr.videostudio.app

import android.content.ContentValues
import android.content.Context
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.RectF
import android.graphics.Typeface
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.provider.MediaStore
import android.text.Layout
import android.text.StaticLayout
import android.text.TextPaint
import androidx.annotation.OptIn
import androidx.media3.common.C
import androidx.media3.common.Effect
import androidx.media3.common.MediaItem
import androidx.media3.common.MimeTypes
import androidx.media3.common.audio.AudioProcessor
import androidx.media3.common.audio.BaseAudioProcessor
import androidx.media3.common.audio.SpeedProvider
import androidx.media3.common.util.UnstableApi
import androidx.media3.effect.BitmapOverlay
import androidx.media3.effect.OverlayEffect
import androidx.media3.effect.Presentation
import androidx.media3.effect.RgbMatrix
import androidx.media3.effect.TextureOverlay
import androidx.media3.transformer.Composition
import androidx.media3.transformer.EditedMediaItem
import androidx.media3.transformer.EditedMediaItemSequence
import androidx.media3.transformer.Effects
import androidx.media3.transformer.ExportException
import androidx.media3.transformer.ExportResult
import androidx.media3.transformer.ProgressHolder
import androidx.media3.transformer.Transformer
import com.google.common.collect.ImmutableList
import org.json.JSONArray
import org.json.JSONObject
import java.io.File
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.time.Instant
import java.util.concurrent.ConcurrentHashMap
import kotlin.math.max
import kotlin.math.min
import kotlin.math.roundToInt

class Job(val id: String, val name: String) {
    @Volatile var status = "queued"   // queued | running | done | error
    @Volatile var progress = 0
    @Volatile var error: String? = null
    @Volatile var resultId: String? = null
    val createdAt: String = Instant.now().toString()
    fun toJson(lib: Library): JSONObject = JSONObject().apply {
        put("job_id", id); put("name", name); put("status", status); put("progress", progress); put("createdAt", createdAt)
        error?.let { put("error", it) }
        resultId?.let { rid -> lib.get(rid)?.let { put("result", it.publicJson()) } }
    }
}

/** Montage sur le téléphone avec Media3 Transformer (encodage matériel). */
@OptIn(UnstableApi::class)
class MontageEngine(private val ctx: Context) {
    private val lib = Library.get(ctx)
    private val tools = MediaTools(ctx)
    private val main = Handler(Looper.getMainLooper())
    val jobs = ConcurrentHashMap<String, Job>()
    private val queue = ArrayDeque<Pair<Job, JSONObject>>()
    private var running = false

    fun start(spec: JSONObject): Job {
        // Validation immédiate pour renvoyer les erreurs à Claude tout de suite
        val clips = spec.optJSONArray("clips") ?: throw IllegalArgumentException("clips manquant")
        if (clips.length() == 0) throw IllegalArgumentException("Le montage doit contenir au moins un clip.")
        for (i in 0 until clips.length()) {
            val c = clips.getJSONObject(i)
            val m = lib.mustGet(c.getString("media_id"))
            if (m.type == "audio") throw IllegalArgumentException("Clip ${i + 1} : ${m.id} est un fichier audio (utilise \"music\").")
        }
        spec.optJSONObject("music")?.let { lib.mustGet(it.getString("media_id")) }
        val job = Job("job_" + Library.newId(8), spec.optString("name", "Montage"))
        jobs[job.id] = job
        synchronized(queue) { queue.addLast(job to spec) }
        main.post { pump() }
        return job
    }

    private fun pump() {
        if (running) return
        val next = synchronized(queue) { queue.removeFirstOrNull() } ?: return
        running = true
        val (job, spec) = next
        try {
            run(job, spec)
        } catch (e: Throwable) {
            android.util.Log.e("VideoStudio", "Montage impossible", e)
            job.status = "error"
            job.error = (e.message ?: e.toString()) + " [" + e.stackTrace.take(3).joinToString(" < ") { "${it.className.substringAfterLast('.')}.${it.methodName}:${it.lineNumber}" } + "]"
            running = false
            main.post { pump() }
        }
    }

    // ------------------------------------------------------------------ construction
    private data class Clip(val m: Media, val start: Double, val srcDur: Double, val speed: Double, val dur: Double, val json: JSONObject)

    private fun run(job: Job, spec: JSONObject) {
        job.status = "running"
        val draft = spec.optString("quality") == "draft"
        val fmt = spec.optJSONObject("format") ?: JSONObject()
        val fps = 30

        val clipsJson = spec.getJSONArray("clips")
        val clips = (0 until clipsJson.length()).map { i ->
            val c = clipsJson.getJSONObject(i)
            val m = lib.mustGet(c.getString("media_id"))
            if (m.type == "image") {
                val d = c.optDouble("duration", 3.0).takeIf { !it.isNaN() } ?: 3.0
                Clip(m, 0.0, d, 1.0, d, c)
            } else {
                val total = m.duration ?: 0.0
                val s = max(0.0, c.optDouble("start", 0.0))
                val e = min(if (c.has("end")) c.getDouble("end") else total, total)
                if (e - s < 0.1) throw IllegalArgumentException("Clip ${i + 1} : intervalle invalide ($s → $e, durée source ${total}s).")
                val sp = c.optDouble("speed", 1.0).coerceIn(0.25, 4.0)
                Clip(m, s, e - s, sp, (e - s) / sp, c)
            }
        }
        val total = clips.sumOf { it.dur }

        // Dimensions de sortie (height = petit côté)
        var small = fmt.optInt("height", 1080)
        if (draft) small = min(small, 480)
        val (aw, ah) = when (fmt.optString("aspect", "16:9")) {
            "9:16" -> 9 to 16; "1:1" -> 1 to 1; "4:5" -> 4 to 5; "4:3" -> 4 to 3
            "source" -> (clips.first().m.width ?: 16) to (clips.first().m.height ?: 9)
            else -> 16 to 9
        }
        val (W, H) = if (aw >= ah) even(small * aw.toDouble() / ah) to even(small.toDouble()) else even(small.toDouble()) to even(small * ah.toDouble() / aw)
        val layout = if (fmt.optString("fit", "cover") == "contain") Presentation.LAYOUT_SCALE_TO_FIT else Presentation.LAYOUT_SCALE_TO_FIT_WITH_CROP

        val trans = spec.optJSONObject("transition")
        val fadeT = if (trans != null && trans.optString("type") == "fade") trans.optDouble("duration", 0.4).coerceIn(0.1, 2.0) else 0.0
        val globalTexts = spec.optJSONArray("texts") ?: JSONArray()

        var offset = 0.0
        val items = clips.mapIndexed { i, c ->
            val fadeIn = if (i > 0) min(fadeT, c.dur / 2.5) else 0.0
            val fadeOut = if (i < clips.size - 1) min(fadeT, c.dur / 2.5) else 0.0

            // Textes actifs pendant ce clip (en temps local du clip)
            val texts = mutableListOf<TextEntry>()
            c.json.optString("text").takeIf { it.isNotBlank() }?.let {
                texts.add(TextEntry(it, 0.0, c.dur, c.json.optString("text_position", "bottom"), c.json.optString("text_size", "medium"), "white", true))
            }
            for (k in 0 until globalTexts.length()) {
                val t = globalTexts.getJSONObject(k)
                val s = t.optDouble("start", 0.0) - offset
                val e = t.optDouble("end", total) - offset
                if (e > 0 && s < c.dur) {
                    texts.add(TextEntry(t.getString("text"), max(0.0, s), min(c.dur, e), t.optString("position", "bottom"),
                        t.optString("size", "medium"), t.optString("color", "white"), t.optBoolean("box", true)))
                }
            }
            offset += c.dur

            val video = mutableListOf<Effect>()
            if (fadeIn > 0 || fadeOut > 0) video.add(FadeMatrix(c.dur, fadeIn, fadeOut))
            video.add(Presentation.createForWidthAndHeight(W, H, layout))
            if (texts.isNotEmpty()) video.add(OverlayEffect(ImmutableList.of<TextureOverlay>(TextLayer(W, H, texts))))

            val volume = if (c.json.optBoolean("mute")) 0.0 else c.json.optDouble("volume", 1.0)
            val audio = mutableListOf<AudioProcessor>()
            if (volume != 1.0 || fadeIn > 0 || fadeOut > 0) audio.add(GainProcessor(volume, fadeIn, fadeOut, c.dur))

            val uri = Uri.parse(c.m.uri)
            val b = if (c.m.type == "image") {
                EditedMediaItem.Builder(
                    MediaItem.Builder().setUri(uri).setImageDurationMs((c.dur * 1000).toLong()).build()
                ).setFrameRate(fps)
            } else {
                val clipping = MediaItem.ClippingConfiguration.Builder()
                    .setStartPositionMs((c.start * 1000).toLong())
                    .setEndPositionMs(((c.start + c.srcDur) * 1000).toLong())
                    .build()
                EditedMediaItem.Builder(MediaItem.Builder().setUri(uri).setClippingConfiguration(clipping).build()).apply {
                    if (c.speed != 1.0) setSpeed(ConstantSpeed(c.speed.toFloat()))
                    if (volume <= 0.0 || !c.m.hasAudio) setRemoveAudio(true)
                }
            }
            b.setEffects(Effects(audio, video)).build()
        }

        // Types de pistes explicites (sinon une photo dans la séquence est refusée par Media3)
        val sequences = mutableListOf(
            EditedMediaItemSequence.Builder(setOf(C.TRACK_TYPE_AUDIO, C.TRACK_TYPE_VIDEO))
                .addItems(items).build()
        )
        val music = spec.optJSONObject("music")
        if (music != null) {
            val mm = lib.mustGet(music.getString("media_id"))
            val mStart = music.optDouble("start", 0.0)
            val mi = MediaItem.Builder().setUri(Uri.parse(mm.uri)).setClippingConfiguration(
                MediaItem.ClippingConfiguration.Builder().setStartPositionMs((mStart * 1000).toLong()).build()
            ).build()
            val mfo = music.optDouble("fade_out", 2.0)
            val musicItem = EditedMediaItem.Builder(mi)
                .setRemoveVideo(true)
                .setEffects(Effects(listOf(MusicGain(music.optDouble("volume", 0.5), total, mfo)), listOf()))
                .build()
            sequences.add(EditedMediaItemSequence.Builder(setOf(C.TRACK_TYPE_AUDIO)).addItem(musicItem).setIsLooping(true).build())
        }

        val gIn = spec.optDouble("fade_in", 0.0)
        val gOut = spec.optDouble("fade_out", 0.0)
        val compBuilder = Composition.Builder(sequences)
            .experimentalSetForceAudioTrack(true)
            .setHdrMode(Composition.HDR_MODE_TONE_MAP_HDR_TO_SDR_USING_OPEN_GL)
        if (gIn > 0 || gOut > 0) {
            compBuilder.setEffects(Effects(listOf(GainProcessor(1.0, gIn, gOut, total)), listOf(FadeMatrix(total, gIn, gOut))))
        }
        val composition = compBuilder.build()

        val out = File(ctx.cacheDir, "${job.id}.mp4")
        val transformer = Transformer.Builder(ctx)
            .setVideoMimeType(MimeTypes.VIDEO_H264)
            .setAudioMimeType(MimeTypes.AUDIO_AAC)
            // Tolère les téléphones lents (et l'encodage logiciel) sans abandonner le rendu
            .setMaxDelayBetweenMuxerSamplesMs(180_000)
            .addListener(object : Transformer.Listener {
                override fun onCompleted(composition: Composition, exportResult: ExportResult) {
                    Thread {
                        try {
                            finish(job, spec, out)
                        } catch (e: Exception) {
                            job.status = "error"; job.error = "Enregistrement impossible : ${e.message}"
                        } finally {
                            out.delete()
                            main.post { running = false; pump() }
                        }
                    }.start()
                }

                override fun onError(composition: Composition, exportResult: ExportResult, exportException: ExportException) {
                    job.status = "error"
                    job.error = "${exportException.errorCodeName} : ${exportException.message} ${exportException.cause?.message ?: ""}".trim()
                    out.delete()
                    running = false
                    main.post { pump() }
                }
            })
            .build()
        transformer.start(composition, out.absolutePath)

        val holder = ProgressHolder()
        val tick = object : Runnable {
            override fun run() {
                if (job.status != "running") return
                if (transformer.getProgress(holder) == Transformer.PROGRESS_STATE_AVAILABLE) job.progress = min(99, holder.progress)
                main.postDelayed(this, 500)
            }
        }
        main.postDelayed(tick, 500)
    }

    /** Copie le rendu dans la galerie (Movies/VideoStudio) et l'ajoute à la bibliothèque. */
    private fun finish(job: Job, spec: JSONObject, out: File) {
        val name = spec.optString("name", "Montage").replace(Regex("[\\\\/:*?\"<>|]"), "_")
        val values = ContentValues().apply {
            put(MediaStore.Video.Media.DISPLAY_NAME, "$name.mp4")
            put(MediaStore.Video.Media.MIME_TYPE, "video/mp4")
            put(MediaStore.Video.Media.RELATIVE_PATH, "Movies/VideoStudio")
            put(MediaStore.Video.Media.IS_PENDING, 1)
        }
        val resolver = ctx.contentResolver
        val uri = resolver.insert(MediaStore.Video.Media.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY), values)
            ?: throw IllegalStateException("MediaStore refuse l'enregistrement")
        resolver.openOutputStream(uri)!!.use { o -> out.inputStream().use { it.copyTo(o, 1 shl 16) } }
        values.clear()
        values.put(MediaStore.Video.Media.IS_PENDING, 0)
        resolver.update(uri, values, null, null)
        val specCopy = JSONObject(spec.toString())
        val m = tools.ingest(uri, kind = "montage", ownsFile = true, forcedName = spec.optString("name", "Montage"), spec = specCopy, notes = spec.optString("notes", ""))
        job.resultId = m.id
        job.progress = 100
        job.status = "done"
    }

    private fun even(x: Double) = max(2, (x / 2).roundToInt() * 2)

    // ------------------------------------------------------------------ effets
    private class ConstantSpeed(private val speed: Float) : SpeedProvider {
        override fun getSpeed(timeUs: Long) = speed
        override fun getNextSpeedChangeTimeUs(timeUs: Long) = C.TIME_UNSET
    }

    /** Fondu au noir en entrée / sortie (temps relatif au premier frame reçu). */
    private class FadeMatrix(val dur: Double, val fadeIn: Double, val fadeOut: Double) : RgbMatrix {
        private var first = Long.MIN_VALUE
        override fun getMatrix(presentationTimeUs: Long, useHdr: Boolean): FloatArray {
            if (first == Long.MIN_VALUE) first = presentationTimeUs
            val t = (presentationTimeUs - first) / 1e6
            var f = 1.0
            if (fadeIn > 0 && t < fadeIn) f = min(f, t / fadeIn)
            if (fadeOut > 0 && t > dur - fadeOut) f = min(f, (dur - t) / fadeOut)
            val k = f.coerceIn(0.0, 1.0).toFloat()
            return floatArrayOf(k, 0f, 0f, 0f, 0f, k, 0f, 0f, 0f, 0f, k, 0f, 0f, 0f, 0f, 1f)
        }
    }

    data class TextEntry(val text: String, val start: Double, val end: Double, val position: String, val size: String, val color: String, val box: Boolean)

    /** Calque de textes plein cadre, recalculé seulement quand l'ensemble des textes visibles change. */
    private class TextLayer(val w: Int, val h: Int, val entries: List<TextEntry>) : BitmapOverlay() {
        private var first = Long.MIN_VALUE
        private val cache = HashMap<String, Bitmap>()
        override fun getBitmap(presentationTimeUs: Long): Bitmap {
            if (first == Long.MIN_VALUE) first = presentationTimeUs
            val t = (presentationTimeUs - first) / 1e6
            val active = entries.filter { t >= it.start && t < it.end }
            val key = active.joinToString("|") { it.hashCode().toString() }
            return cache.getOrPut(key) { render(active) }
        }

        private fun render(active: List<TextEntry>): Bitmap {
            val bmp = Bitmap.createBitmap(w, h, Bitmap.Config.ARGB_8888)
            if (active.isEmpty()) return bmp
            val c = Canvas(bmp)
            for (e in active) {
                val fs = h * when (e.size) { "small" -> 0.04f; "large" -> 0.08f; "huge" -> 0.11f; else -> 0.055f }
                val paint = TextPaint(Paint.ANTI_ALIAS_FLAG).apply {
                    textSize = fs
                    typeface = Typeface.create(Typeface.SANS_SERIF, Typeface.BOLD)
                    color = runCatching { Color.parseColor(e.color) }.getOrDefault(Color.WHITE)
                    if (!e.box) setShadowLayer(fs / 8, 0f, 0f, Color.BLACK)
                }
                val maxW = (w * 0.88f).toInt()
                val sl = StaticLayout.Builder.obtain(e.text, 0, e.text.length, paint, maxW)
                    .setAlignment(Layout.Alignment.ALIGN_CENTER).setLineSpacing(0f, 1.05f).build()
                val lw = (0 until sl.lineCount).maxOf { sl.getLineWidth(it) }
                val y = when (e.position) {
                    "top" -> h * 0.08f
                    "center" -> (h - sl.height) / 2f
                    else -> h - sl.height - h * 0.1f
                }
                if (e.box) {
                    val pad = fs * 0.35f
                    val bp = Paint(Paint.ANTI_ALIAS_FLAG).apply { color = Color.argb(115, 0, 0, 0) }
                    c.drawRoundRect(RectF((w - lw) / 2 - pad, y - pad, (w + lw) / 2 + pad, y + sl.height + pad), pad, pad, bp)
                }
                c.save()
                c.translate((w - maxW) / 2f, y)
                sl.draw(c)
                c.restore()
            }
            return bmp
        }
    }

    /** Volume + fondus d'un clip (PCM 16 bits). */
    private open class GainProcessor(val volume: Double, val fadeIn: Double, val fadeOut: Double, val dur: Double) : BaseAudioProcessor() {
        private var frames = 0L
        private var rate = 44100
        private var channels = 2

        override fun onConfigure(inputAudioFormat: AudioProcessor.AudioFormat): AudioProcessor.AudioFormat {
            if (inputAudioFormat.encoding != C.ENCODING_PCM_16BIT) throw AudioProcessor.UnhandledAudioFormatException(inputAudioFormat)
            rate = inputAudioFormat.sampleRate
            channels = inputAudioFormat.channelCount
            return inputAudioFormat
        }

        open fun gainAt(t: Double): Double {
            var g = volume
            if (fadeIn > 0 && t < fadeIn) g *= t / fadeIn
            if (fadeOut > 0 && t > dur - fadeOut) g *= max(0.0, (dur - t) / fadeOut)
            return g
        }

        override fun queueInput(inputBuffer: ByteBuffer) {
            val n = inputBuffer.remaining()
            if (n == 0) return
            val out = replaceOutputBuffer(n).order(ByteOrder.nativeOrder())
            val inb = inputBuffer.order(ByteOrder.nativeOrder())
            while (inb.remaining() >= 2 * channels) {
                val g = gainAt(frames.toDouble() / rate)
                for (ch in 0 until channels) {
                    val s = (inb.short * g).roundToInt().coerceIn(-32768, 32767)
                    out.putShort(s.toShort())
                }
                frames++
            }
            while (inb.hasRemaining()) out.put(inb.get())
            out.flip()
        }

        override fun onReset() { frames = 0 }
    }

    /** Musique : volume constant + fondu de fin calé sur la durée totale (même si la musique boucle). */
    private class MusicGain(volume: Double, total: Double, fadeOut: Double) : GainProcessor(volume, 0.0, min(fadeOut, total / 2), total)
}
