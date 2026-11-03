package fr.videostudio.app

import android.content.Context
import android.net.Uri
import org.json.JSONArray
import org.json.JSONObject
import java.io.File
import java.security.SecureRandom
import java.time.Instant

/** Un média de la bibliothèque. Les fichiers restent où ils sont (galerie, dossier de l'app). */
data class Media(
    val id: String,
    var name: String,
    val type: String,          // video | image | audio
    val kind: String,          // upload | montage
    val uri: String,           // content://… ou file://…
    val mime: String,
    val duration: Double?,     // secondes
    val width: Int?,
    val height: Int?,
    val hasAudio: Boolean,
    val sizeBytes: Long,
    var notes: String = "",
    var tags: List<String> = emptyList(),
    val createdAt: String = Instant.now().toString(),
    val spec: JSONObject? = null,
    val ownsFile: Boolean = false, // fichier créé/copié par l'app (supprimable)
) {
    fun toJson(): JSONObject = JSONObject().apply {
        put("id", id); put("name", name); put("type", type); put("kind", kind); put("uri", uri); put("mime", mime)
        put("duration", duration ?: JSONObject.NULL); put("width", width ?: JSONObject.NULL); put("height", height ?: JSONObject.NULL)
        put("hasAudio", hasAudio); put("sizeBytes", sizeBytes); put("notes", notes); put("tags", JSONArray(tags))
        put("createdAt", createdAt); put("ownsFile", ownsFile)
        if (spec != null) put("spec", spec)
    }

    /** Vue publique (pour Claude et l'interface). */
    fun publicJson(): JSONObject = JSONObject().apply {
        put("id", id); put("name", name); put("type", type); put("kind", kind)
        if (duration != null) put("duration", Math.round(duration * 100) / 100.0)
        if (width != null) { put("width", width); put("height", height) }
        put("hasAudio", hasAudio)
        put("sizeMB", Math.round(sizeBytes / 104857.6) / 10.0)
        if (notes.isNotBlank()) put("notes", notes)
        if (tags.isNotEmpty()) put("tags", JSONArray(tags))
        put("createdAt", createdAt)
    }

    companion object {
        fun fromJson(o: JSONObject) = Media(
            id = o.getString("id"), name = o.getString("name"), type = o.getString("type"), kind = o.optString("kind", "upload"),
            uri = o.getString("uri"), mime = o.optString("mime", ""),
            duration = if (o.isNull("duration")) null else o.optDouble("duration"),
            width = if (o.isNull("width")) null else o.optInt("width"),
            height = if (o.isNull("height")) null else o.optInt("height"),
            hasAudio = o.optBoolean("hasAudio"), sizeBytes = o.optLong("sizeBytes"), notes = o.optString("notes", ""),
            tags = o.optJSONArray("tags")?.let { a -> List(a.length()) { a.getString(it) } } ?: emptyList(),
            createdAt = o.optString("createdAt"), spec = o.optJSONObject("spec"), ownsFile = o.optBoolean("ownsFile"),
        )
    }
}

class Library private constructor(private val ctx: Context) {
    private val file = File(ctx.filesDir, "library.json")
    private val items = mutableListOf<Media>()
    val thumbDir = File(ctx.filesDir, "thumbs").apply { mkdirs() }
    val importDir = File(ctx.getExternalFilesDir(null) ?: ctx.filesDir, "imports").apply { mkdirs() }

    init {
        runCatching {
            val a = JSONObject(file.readText()).getJSONArray("items")
            for (i in 0 until a.length()) items.add(Media.fromJson(a.getJSONObject(i)))
        }
    }

    @Synchronized
    private fun save() {
        val tmp = File(file.path + ".tmp")
        tmp.writeText(JSONObject().put("items", JSONArray(items.map { it.toJson() })).toString())
        tmp.renameTo(file)
    }

    @Synchronized
    fun list(type: String? = null, kind: String? = null, search: String? = null): List<Media> =
        items.filter { m ->
            (type.isNullOrEmpty() || m.type == type) && (kind.isNullOrEmpty() || m.kind == kind) &&
                (search.isNullOrEmpty() || (m.name + " " + m.notes + " " + m.tags.joinToString(" ")).contains(search, ignoreCase = true))
        }.sortedByDescending { it.createdAt }

    @Synchronized
    fun get(id: String): Media? = items.find { it.id == id }

    fun mustGet(id: String): Media = get(id) ?: throw IllegalArgumentException("Média introuvable : $id")

    @Synchronized
    fun add(m: Media) { items.add(m); save() }

    @Synchronized
    fun hasUri(uri: String) = items.any { it.uri == uri }

    @Synchronized
    fun update(id: String, name: String?, notes: String?, tags: List<String>?): Media {
        val m = mustGet(id)
        if (!name.isNullOrBlank()) m.name = name
        if (notes != null) m.notes = notes
        if (tags != null) m.tags = tags
        save()
        return m
    }

    @Synchronized
    fun remove(id: String): Media {
        val m = mustGet(id)
        items.remove(m)
        save()
        thumbFile(id).delete()
        if (m.ownsFile) {
            runCatching {
                val u = Uri.parse(m.uri)
                if (u.scheme == "file") File(u.path!!).delete() else ctx.contentResolver.delete(u, null, null)
            }
        } else {
            runCatching { ctx.contentResolver.releasePersistableUriPermission(Uri.parse(m.uri), android.content.Intent.FLAG_GRANT_READ_URI_PERMISSION) }
        }
        return m
    }

    fun thumbFile(id: String) = File(thumbDir, "$id.jpg")

    companion object {
        @Volatile private var instance: Library? = null
        fun get(ctx: Context): Library = instance ?: synchronized(this) {
            instance ?: Library(ctx.applicationContext).also { instance = it }
        }

        private val rnd = SecureRandom()
        fun newId(len: Int = 10): String {
            val chars = "abcdefghijkmnopqrstuvwxyz23456789"
            return String(CharArray(len) { chars[rnd.nextInt(chars.length)] })
        }
    }
}
