package com.appsbay.onlynote

import android.content.Context
import android.content.Intent
import android.graphics.BitmapFactory
import android.net.Uri
import android.os.Build
import android.webkit.MimeTypeMap
import org.json.JSONArray
import org.json.JSONObject
import java.io.File
import java.io.FileOutputStream
import java.util.UUID

/** Every published folder owns its copied content until Dart acknowledges it. */
object ShareInboxStore {
    const val EXTRA_INBOX_CHANGED = "com.appsbay.onlynote.SHARED_INBOX_CHANGED"
    private const val MAX_IMAGE_BYTES = 25L * 1024 * 1024
    private const val MAX_TOTAL_BYTES = 100L * 1024 * 1024

    private fun root(context: Context): File =
        File(context.filesDir, "share_inbox").also { check(it.exists() || it.mkdirs()) }

    @Synchronized
    fun stage(context: Context, intent: Intent, id: String) {
        require(validId(id))
        require(intent.action == Intent.ACTION_SEND || intent.action == Intent.ACTION_SEND_MULTIPLE)
        val destination = File(root(context), id)
        if (File(destination, "entry.json").exists()) return
        val staging = File(root(context), ".pending-$id")
        staging.deleteRecursively()
        check(staging.mkdirs())
        try {
            val title = intent.getStringExtra(Intent.EXTRA_SUBJECT).orEmpty()
            var text = intent.getCharSequenceExtra(Intent.EXTRA_TEXT)?.toString().orEmpty()
            val streams = mutableListOf<Uri>()
            if (intent.action == Intent.ACTION_SEND_MULTIPLE) {
                val extras = if (Build.VERSION.SDK_INT >= 33) {
                    intent.getParcelableArrayListExtra(Intent.EXTRA_STREAM, Uri::class.java)
                } else {
                    @Suppress("DEPRECATION")
                    intent.getParcelableArrayListExtra<Uri>(Intent.EXTRA_STREAM)
                }
                streams.addAll(extras.orEmpty())
            } else {
                val stream = if (Build.VERSION.SDK_INT >= 33) {
                    intent.getParcelableExtra(Intent.EXTRA_STREAM, Uri::class.java)
                } else {
                    @Suppress("DEPRECATION")
                    intent.getParcelableExtra<Uri>(Intent.EXTRA_STREAM)
                }
                if (stream != null) streams.add(stream)
            }
            // Some senders provide only ClipData, including multi-photo shares.
            val clip = intent.clipData
            if (clip != null) {
                for (index in 0 until clip.itemCount) {
                    val item = clip.getItemAt(index)
                    if (text.isBlank() && item.text != null) text = item.text.toString()
                    item.uri?.let {
                        if (it.scheme == "http" || it.scheme == "https") {
                            val link = it.toString()
                            if (!text.contains(link)) text += if (text.isBlank()) link else "\n\n$link"
                        } else if (!streams.contains(it)) {
                            streams.add(it)
                        }
                    }
                }
            }
            require(title.length <= 1000 && text.length <= 100000)
            require(streams.size <= 10)
            val names = JSONArray()
            var total = 0L
            streams.forEachIndexed { index, uri ->
                require(uri.scheme == "content")
                val type = context.contentResolver.getType(uri) ?: intent.type.orEmpty()
                require(type.startsWith("image/"))
                val extension = MimeTypeMap.getSingleton().getExtensionFromMimeType(type)
                    ?.takeIf { it.matches(Regex("[a-zA-Z0-9]{1,8}")) } ?: "jpg"
                val name = "photo-$index.$extension"
                val image = File(staging, name)
                context.contentResolver.openInputStream(uri).use { input ->
                    require(input != null)
                    FileOutputStream(image).use { output ->
                        val buffer = ByteArray(32 * 1024)
                        var count = 0L
                        while (true) {
                            val read = input.read(buffer)
                            if (read < 0) break
                            count += read
                            total += read
                            require(count <= MAX_IMAGE_BYTES && total <= MAX_TOTAL_BYTES)
                            output.write(buffer, 0, read)
                        }
                        require(count > 0)
                        output.fd.sync()
                    }
                }
                val bounds = BitmapFactory.Options().also { it.inJustDecodeBounds = true }
                BitmapFactory.decodeFile(image.path, bounds)
                require(bounds.outWidth > 0 && bounds.outHeight > 0)
                names.put(name)
            }
            require(title.isNotBlank() || text.isNotBlank() || names.length() > 0)
            val entry = JSONObject().put("version", 1).put("id", id)
                .put("title", title).put("text", text).put("images", names)
                .put("createdAt", System.currentTimeMillis() / 1000.0)
            FileOutputStream(File(staging, "entry.json")).use {
                it.write(entry.toString().toByteArray(Charsets.UTF_8))
                it.fd.sync()
            }
            check(staging.renameTo(destination))
        } catch (error: Throwable) {
            staging.deleteRecursively()
            throw error
        }
    }

    @Synchronized
    fun pending(context: Context): List<Map<String, Any>> =
        root(context).listFiles().orEmpty().filter { it.isDirectory && validId(it.name) }
            .map { folder ->
                val entry = JSONObject(File(folder, "entry.json").readText())
                require(entry.getString("id") == folder.name)
                val names = entry.getJSONArray("images")
                require(names.length() <= 10)
                val paths = (0 until names.length()).map { index ->
                    val name = names.getString(index)
                    require(name.isNotEmpty() && !name.contains('/') && !name.contains('\\') && !name.contains(".."))
                    File(folder, name).path
                }
                mapOf<String, Any>(
                    "version" to entry.getInt("version"), "id" to folder.name,
                    "title" to entry.getString("title"), "text" to entry.getString("text"),
                    "images" to paths, "createdAt" to entry.optDouble("createdAt", 0.0)
                )
            }.sortedBy { it["createdAt"] as Double }

    @Synchronized
    fun acknowledge(context: Context, id: String) {
        require(validId(id))
        val folder = File(root(context), id)
        check(!folder.exists() || folder.deleteRecursively())
    }

    private fun validId(id: String): Boolean =
        id.matches(Regex("[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}"))
}
