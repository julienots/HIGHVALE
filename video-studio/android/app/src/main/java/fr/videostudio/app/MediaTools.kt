package fr.videostudio.app

import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.ImageDecoder
import android.graphics.Paint
import android.graphics.RectF
import android.graphics.Typeface
import android.media.MediaCodec
import android.media.MediaExtractor
import android.media.MediaFormat
import android.media.MediaMetadataRetriever
import android.net.Uri
import android.provider.OpenableColumns
import android.util.Base64
import java.io.ByteArrayOutputStream
import java.io.File
import java.io.FileOutputStream
import java.net.HttpURLConnection
import java.net.URL
import java.nio.ByteOrder
import kotlin.math.abs
import kotlin.math.log10
import kotlin.math.max
import kotlin.math.min
import kotlin.math.roundToInt
import kotlin.math.sqrt

/** Analyse et extraction d'images, entièrement sur le téléphone. */
class MediaTools(private val ctx: Context) {
    private val lib = Library.get(ctx)

    // ------------------------------------------------------------------ ajout
    fun typeOf(mime: String, name: String): String? {
        val ext = name.substringAfterLast('.', "").lowercase()
        return when {
            mime.startsWith("video/") || ext in setOf("mp4", "mov", "mkv", "webm", "3gp", "m4v") -> "video"
            mime.startsWith("audio/") || ext in setOf("mp3", "wav", "m4a", "aac", "ogg", "flac", "opus") -> "audio"
            mime.startsWith("image/") || ext in setOf("jpg", "jpeg", "png", "webp", "heic", "heif", "gif") -> "image"
            else -> null
        }
    }

    private fun queryNameSize(uri: Uri): Pair<String, Long> {
        if (uri.scheme == "file") {
            val f = File(uri.path!!)
            return f.name to f.length()
        }
        var name = "fichier"
        var size = 0L
        runCatching {
            ctx.contentResolver.query(uri, null, null, null, null)?.use { c ->
                if (c.moveToFirst()) {
                    val ni = c.getColumnIndex(OpenableColumns.DISPLAY_NAME)
                    val si = c.getColumnIndex(OpenableColumns.SIZE)
                    if (ni >= 0) name = c.getString(ni) ?: name
                    if (si >= 0 && !c.isNull(si)) size = c.getLong(si)
                }
            }
        }
        return name to size
    }

    /** Ajoute un fichier déjà accessible (URI persistante, fichier de l'app ou de la galerie). */
    fun ingest(uri: Uri, kind: String = "upload", ownsFile: Boolean = false, forcedName: String? = null, spec: org.json.JSONObject? = null, notes: String = ""): Media {
        val (fname, size) = queryNameSize(uri)
        val mime = (if (uri.scheme == "file") null else ctx.contentResolver.getType(uri))
            ?: android.webkit.MimeTypeMap.getSingleton().getMimeTypeFromExtension(fname.substringAfterLast('.', "").lowercase()) ?: ""
        val type = typeOf(mime, fname) ?: throw IllegalArgumentException("Type de fichier non pris en charge : $fname")
        var duration: Double? = null
        var width: Int? = null
        var height: Int? = null
        var hasAudio = type == "audio"
        if (type == "image") {
            val o = android.graphics.BitmapFactory.Options().apply { inJustDecodeBounds = true }
            ctx.contentResolver.openInputStream(uri)?.use { android.graphics.BitmapFactory.decodeStream(it, null, o) }
            if (o.outWidth > 0) { width = o.outWidth; height = o.outHeight }
            if (width == null) runCatching { decodeImage(uri, 64).let { width = it.width; height = it.height } }
        } else {
            val r = MediaMetadataRetriever()
            try {
                r.setDataSource(ctx, uri)
                duration = r.extractMetadata(MediaMetadataRetriever.METADATA_KEY_DURATION)?.toLongOrNull()?.let { it / 1000.0 }
                hasAudio = r.extractMetadata(MediaMetadataRetriever.METADATA_KEY_HAS_AUDIO) == "yes"
                if (type == "video") {
                    val w = r.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_WIDTH)?.toIntOrNull()
                    val h = r.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_HEIGHT)?.toIntOrNull()
                    val rot = r.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_ROTATION)?.toIntOrNull() ?: 0
                    if (rot % 180 != 0) { width = h; height = w } else { width = w; height = h }
                }
            } catch (e: Exception) {
                throw IllegalArgumentException("Fichier illisible : $fname")
            } finally {
                r.release()
            }
        }
        val m = Media(
            id = Library.newId(), name = forcedName ?: fname.substringBeforeLast('.'), type = type, kind = kind,
            uri = uri.toString(), mime = mime, duration = duration, width = width, height = height,
            hasAudio = hasAudio, sizeBytes = size, notes = notes, spec = spec, ownsFile = ownsFile,
        )
        runCatching { makeThumb(m) }
        lib.add(m)
        return m
    }

    /** Fichier choisi dans le sélecteur (accès permanent, pas de copie). */
    fun ingestPicked(uri: Uri): Media {
        runCatching { ctx.contentResolver.takePersistableUriPermission(uri, Intent.FLAG_GRANT_READ_URI_PERMISSION) }
        lib.list().find { it.uri == uri.toString() }?.let { return it }
        return ingest(uri)
    }

    /** Fichier partagé depuis une autre app : accès temporaire, donc copie dans le dossier de l'app. */
    fun ingestShared(uri: Uri): Media {
        val persisted = runCatching {
            ctx.contentResolver.takePersistableUriPermission(uri, Intent.FLAG_GRANT_READ_URI_PERMISSION); true
        }.getOrDefault(false)
        if (persisted) return ingest(uri)
        val (name, _) = queryNameSize(uri)
        val dest = uniqueFile(lib.importDir, name)
        ctx.contentResolver.openInputStream(uri)!!.use { input -> FileOutputStream(dest).use { input.copyTo(it, 1 shl 16) } }
        return try { ingest(Uri.fromFile(dest), ownsFile = true) } catch (e: Exception) { dest.delete(); throw e }
    }

    fun importFromUrl(url: String, name: String?): Media {
        val conn = URL(url).openConnection() as HttpURLConnection
        conn.instanceFollowRedirects = true
        conn.connectTimeout = 20000
        conn.readTimeout = 60000
        if (conn.responseCode !in 200..299) throw IllegalStateException("Téléchargement impossible (HTTP ${conn.responseCode})")
        var fname = name ?: Uri.parse(url).lastPathSegment ?: "import"
        if (!fname.contains('.')) {
            val ext = android.webkit.MimeTypeMap.getSingleton().getExtensionFromMimeType(conn.contentType?.substringBefore(';') ?: "")
            if (ext != null) fname += ".$ext"
        }
        val dest = uniqueFile(lib.importDir, fname)
        conn.inputStream.use { input -> FileOutputStream(dest).use { input.copyTo(it, 1 shl 16) } }
        return try { ingest(Uri.fromFile(dest), ownsFile = true) } catch (e: Exception) { dest.delete(); throw e }
    }

    private fun uniqueFile(dir: File, name: String): File {
        val safe = name.replace(Regex("[^\\w.\\- ]"), "_").ifBlank { "fichier" }
        var f = File(dir, safe)
        var i = 1
        while (f.exists()) f = File(dir, safe.substringBeforeLast('.') + "_${i++}." + safe.substringAfterLast('.', "bin"))
        return f
    }

    // ------------------------------------------------------------------ images
    fun decodeImage(uri: Uri, maxSide: Int): Bitmap {
        val src = if (uri.scheme == "file") ImageDecoder.createSource(File(uri.path!!)) else ImageDecoder.createSource(ctx.contentResolver, uri)
        return ImageDecoder.decodeBitmap(src) { dec, info, _ ->
            val s = info.size
            val scale = min(1f, maxSide.toFloat() / max(s.width, s.height))
            dec.setTargetSize(max(1, (s.width * scale).roundToInt()), max(1, (s.height * scale).roundToInt()))
            dec.allocator = ImageDecoder.ALLOCATOR_SOFTWARE
        }
    }

    private fun <T> withRetriever(m: Media, block: (MediaMetadataRetriever) -> T): T {
        val r = MediaMetadataRetriever()
        try {
            r.setDataSource(ctx, Uri.parse(m.uri))
            return block(r)
        } finally {
            r.release()
        }
    }

    private fun scaledFrame(r: MediaMetadataRetriever, timeS: Double, w: Int, h: Int, exact: Boolean): Bitmap? {
        val us = (timeS * 1_000_000).toLong()
        val opt = if (exact) MediaMetadataRetriever.OPTION_CLOSEST else MediaMetadataRetriever.OPTION_CLOSEST_SYNC
        return r.getScaledFrameAtTime(us, opt, w, h) ?: r.getFrameAtTime(us, opt)
    }

    fun frame(m: Media, timeS: Double, width: Int): Bitmap {
        if (m.type == "audio") throw IllegalArgumentException("Fichier audio : pas d'image.")
        if (m.type == "image") return decodeImage(Uri.parse(m.uri), width)
        val (w, h) = fitSize(m, width)
        return withRetriever(m) { r ->
            val t = min(timeS, max(0.0, (m.duration ?: 0.0) - 0.05))
            scaledFrame(r, t, w, h, true) ?: throw IllegalStateException("Impossible d'extraire l'image à ${t}s")
        }
    }

    private fun fitSize(m: Media, width: Int): Pair<Int, Int> {
        val ar = (m.width ?: 16).toDouble() / (m.height ?: 9)
        return if (ar >= 1) width to (width / ar).roundToInt() else (width * ar).roundToInt() to width
    }

    fun makeThumb(m: Media) {
        if (m.type == "audio") return
        val bmp = if (m.type == "image") decodeImage(Uri.parse(m.uri), 480)
        else withRetriever(m) { r -> scaledFrame(r, min(1.0, (m.duration ?: 0.0) / 2), fitSize(m, 480).first, fitSize(m, 480).second, false) }
        bmp ?: return
        FileOutputStream(lib.thumbFile(m.id)).use { bmp.compress(Bitmap.CompressFormat.JPEG, 75, it) }
    }

    fun storyboard(m: Media, start: Double, end: Double, cols: Int, rows: Int): Pair<Bitmap, List<Double>> {
        if (m.type != "video") throw IllegalArgumentException("view_storyboard ne fonctionne que sur les vidéos.")
        val ar = (m.width ?: 16).toDouble() / (m.height ?: 9)
        val tileW = 320
        val tileH = (min(tileW * 1.8, tileW / ar)).roundToInt()
        val n = cols * rows
        val span = max(0.1, end - start)
        val times = List(n) { start + span / n * (it + 0.5) }
        val sheet = Bitmap.createBitmap(tileW * cols, tileH * rows, Bitmap.Config.ARGB_8888)
        val c = Canvas(sheet)
        c.drawColor(Color.BLACK)
        val (fw, fh) = fitSize(m, tileW)
        val label = Paint(Paint.ANTI_ALIAS_FLAG).apply { color = Color.WHITE; textSize = 20f; typeface = Typeface.DEFAULT_BOLD }
        val box = Paint().apply { color = Color.argb(160, 0, 0, 0) }
        withRetriever(m) { r ->
            times.forEachIndexed { i, t ->
                val x = (i % cols) * tileW
                val y = (i / cols) * tileH
                scaledFrame(r, t, fw, fh, true)?.let { f ->
                    val s = min(tileW.toFloat() / f.width, tileH.toFloat() / f.height)
                    val dw = f.width * s
                    val dh = f.height * s
                    c.drawBitmap(f, null, RectF(x + (tileW - dw) / 2, y + (tileH - dh) / 2, x + (tileW + dw) / 2, y + (tileH + dh) / 2), null)
                    f.recycle()
                }
                val txt = fmtTime(t)
                c.drawRect(x + 2f, y + 2f, x + 14f + label.measureText(txt), y + 30f, box)
                c.drawText(txt, x + 8f, y + 24f, label)
            }
        }
        return sheet to times.map { (it * 100).roundToInt() / 100.0 }
    }

    /** Changements de plan : différence d'histogrammes entre images échantillonnées. */
    fun detectScenes(m: Media, threshold: Double, interval: Double): List<Double> {
        if (m.type != "video") throw IllegalArgumentException("Uniquement pour les vidéos.")
        val dur = m.duration ?: return emptyList()
        val step = max(interval, dur / 600)
        val cuts = mutableListOf<Double>()
        var prev: FloatArray? = null
        withRetriever(m) { r ->
            var t = 0.0
            while (t < dur) {
                val f = scaledFrame(r, t, 64, 36, false)
                if (f != null) {
                    val h = histogram(f)
                    f.recycle()
                    prev?.let { p ->
                        var d = 0f
                        for (i in h.indices) d += abs(h[i] - p[i])
                        if (d / 2 > threshold) cuts.add((t * 100).roundToInt() / 100.0)
                    }
                    prev = h
                }
                t += step
            }
        }
        return cuts
    }

    private fun histogram(b: Bitmap): FloatArray {
        val px = IntArray(b.width * b.height)
        b.getPixels(px, 0, b.width, 0, 0, b.width, b.height)
        val h = FloatArray(48)
        for (p in px) {
            h[Color.red(p) shr 4]++; h[16 + (Color.green(p) shr 4)]++; h[32 + (Color.blue(p) shr 4)]++
        }
        val n = px.size * 3f
        for (i in h.indices) h[i] /= n
        return h
    }

    /** Silences et niveau moyen, en décodant la piste audio. */
    fun analyzeAudio(m: Media, noiseDb: Double, minSilence: Double): org.json.JSONObject {
        val ex = MediaExtractor()
        ex.setDataSource(ctx, Uri.parse(m.uri), null)
        val track = (0 until ex.trackCount).firstOrNull { ex.getTrackFormat(it).getString(MediaFormat.KEY_MIME)?.startsWith("audio/") == true }
            ?: run { ex.release(); throw IllegalArgumentException("Ce média n'a pas de son.") }
        ex.selectTrack(track)
        val fmt = ex.getTrackFormat(track)
        val codec = MediaCodec.createDecoderByType(fmt.getString(MediaFormat.KEY_MIME)!!)
        codec.configure(fmt, null, null, 0)
        codec.start()
        var sampleRate = fmt.getInteger(MediaFormat.KEY_SAMPLE_RATE)
        var channels = fmt.getInteger(MediaFormat.KEY_CHANNEL_COUNT)
        val window = 0.05
        val levels = ArrayList<Double>()
        var acc = 0.0
        var accN = 0
        var winSamples = (sampleRate * window).toInt() * channels
        val info = MediaCodec.BufferInfo()
        var inDone = false
        var outDone = false
        val t0 = System.currentTimeMillis()
        try {
            while (!outDone && System.currentTimeMillis() - t0 < 80_000) {
                if (!inDone) {
                    val ii = codec.dequeueInputBuffer(5000)
                    if (ii >= 0) {
                        val buf = codec.getInputBuffer(ii)!!
                        val n = ex.readSampleData(buf, 0)
                        if (n < 0) { codec.queueInputBuffer(ii, 0, 0, 0, MediaCodec.BUFFER_FLAG_END_OF_STREAM); inDone = true }
                        else { codec.queueInputBuffer(ii, 0, n, ex.sampleTime, 0); ex.advance() }
                    }
                }
                val oi = codec.dequeueOutputBuffer(info, 5000)
                if (oi == MediaCodec.INFO_OUTPUT_FORMAT_CHANGED) {
                    val of = codec.outputFormat
                    sampleRate = of.getInteger(MediaFormat.KEY_SAMPLE_RATE)
                    channels = of.getInteger(MediaFormat.KEY_CHANNEL_COUNT)
                    winSamples = (sampleRate * window).toInt() * channels
                } else if (oi >= 0) {
                    val ob = codec.getOutputBuffer(oi)!!.order(ByteOrder.LITTLE_ENDIAN).asShortBuffer()
                    while (ob.hasRemaining()) {
                        val s = ob.get() / 32768.0
                        acc += s * s; accN++
                        if (accN >= winSamples) {
                            levels.add(20 * log10(max(1e-9, sqrt(acc / accN))))
                            acc = 0.0; accN = 0
                        }
                    }
                    codec.releaseOutputBuffer(oi, false)
                    if (info.flags and MediaCodec.BUFFER_FLAG_END_OF_STREAM != 0) outDone = true
                }
            }
        } finally {
            runCatching { codec.stop() }; codec.release(); ex.release()
        }
        val silences = org.json.JSONArray()
        var runStart = -1
        for (i in 0..levels.size) {
            val quiet = i < levels.size && levels[i] < noiseDb
            if (quiet && runStart < 0) runStart = i
            if (!quiet && runStart >= 0) {
                val s = runStart * window
                val e = i * window
                if (e - s >= minSilence) silences.put(org.json.JSONObject().put("start", r2(s)).put("end", r2(e)).put("duration", r2(e - s)))
                runStart = -1
            }
        }
        val loud = levels.filter { it > -70 }
        return org.json.JSONObject()
            .put("media_id", m.id).put("duration", m.duration)
            .put("averageLevelDb", if (loud.isEmpty()) JSONObjectNull else r2(loud.average()))
            .put("peakLevelDb", if (levels.isEmpty()) JSONObjectNull else r2(levels.max()))
            .put("silences", silences)
            .put("analyzedSeconds", r2(levels.size * window))
    }

    companion object {
        val JSONObjectNull: Any = org.json.JSONObject.NULL
        fun r2(x: Double) = (x * 100).roundToInt() / 100.0
        fun fmtTime(t: Double): String {
            val m = (t / 60).toInt()
            return "%02d:%04.1f".format(java.util.Locale.US, m, t - m * 60)
        }
        fun jpegBase64(b: Bitmap, quality: Int = 72): String {
            val out = ByteArrayOutputStream()
            b.compress(Bitmap.CompressFormat.JPEG, quality, out)
            return Base64.encodeToString(out.toByteArray(), Base64.NO_WRAP)
        }
    }
}
