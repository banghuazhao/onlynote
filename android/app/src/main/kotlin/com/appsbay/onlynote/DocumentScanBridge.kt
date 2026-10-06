package com.appsbay.onlynote

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.util.AtomicFile
import com.google.android.gms.common.ConnectionResult
import com.google.android.gms.common.GoogleApiAvailability
import com.google.mlkit.common.MlKitException
import com.google.mlkit.vision.documentscanner.GmsDocumentScannerOptions
import com.google.mlkit.vision.documentscanner.GmsDocumentScanning
import com.google.mlkit.vision.documentscanner.GmsDocumentScanningResult
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import org.json.JSONArray
import org.json.JSONObject
import java.io.File
import java.io.FileOutputStream
import java.io.IOException
import java.lang.ref.WeakReference
import java.util.UUID
import java.util.concurrent.Executors

/** Google supplies the camera/review UI; only durable, app-owned JPEGs enter Dart. */
class DocumentScanBridge(owner: Activity, savedState: Bundle?) {
    private val activity = WeakReference(owner)
    private val context = owner.applicationContext
    private var channel: MethodChannel? = null
    private var reply: MethodChannel.Result? = null
    private var requestId = savedState?.getString(STATE_ID)?.takeIf(ScanInbox::validId)
    private var awaitingExternal = savedState?.getBoolean(STATE_AWAITING, false) == true
    private var pausedAfterLaunch = awaitingExternal
    private var preparing = false
    private var copying = false
    private var disposed = false

    fun register(messenger: BinaryMessenger) {
        channel = MethodChannel(messenger, CHANNEL).also { bridge ->
            bridge.setMethodCallHandler { call, result ->
                when (call.method) {
                    "scan" -> {
                        val id = call.argument<String>("id")
                        val limit = call.argument<Number>("pageLimit")?.toInt() ?: MAX_PAGES
                        if (id == null || !ScanInbox.validId(id) || limit !in 1..MAX_PAGES) {
                            result.success(response(id ?: "", "failed"))
                        } else {
                            scan(id, limit, result)
                        }
                    }
                    "pending" -> worker.execute {
                        val pending = try {
                            ScanInbox.all(context).map {
                                try { ScanInbox.payload(context, it) }
                                catch (_: Exception) { response(it.id, "failed") }
                            }
                        } catch (_: Exception) {
                            emptyList<Map<String, Any>>()
                        }
                        main.post { result.success(pending) }
                    }
                    "acknowledge" -> {
                        val id = call.argument<String>("id")
                        if (id == null || !ScanInbox.validId(id) ||
                            (id == requestId && (preparing || awaitingExternal || copying))) {
                            result.error("document_scan", "The scan is still in progress.", null)
                        } else {
                            worker.execute {
                                try {
                                    ScanInbox.acknowledge(context, id)
                                    main.post { result.success(null) }
                                } catch (_: Exception) {
                                    main.post {
                                        result.error("document_scan", "The scan is retained for retry.", null)
                                    }
                                }
                            }
                        }
                    }
                    else -> result.notImplemented()
                }
            }
        }
    }

    private fun scan(id: String, limit: Int, result: MethodChannel.Result) {
        if (disposed || reply != null || preparing || awaitingExternal || copying) {
            result.success(response(id, "failed"))
            return
        }
        if (Build.VERSION.SDK_INT < 21 ||
            GoogleApiAvailability.getInstance().isGooglePlayServicesAvailable(context) !=
            ConnectionResult.SUCCESS) {
            result.success(response(id, "unsupported"))
            return
        }
        requestId = id
        preparing = true
        reply = result
        worker.execute {
            try {
                val prior = ScanInbox.read(context, id)
                if (prior != null) {
                    main.post { deliver(prior) }
                    return@execute
                }
                // Persist intent ownership before SDK setup or external activity launch.
                val record = ScanRecord(id, "pending", "preparing", limit, System.currentTimeMillis())
                ScanInbox.write(context, record)
                main.post { prepareScanner(record) }
            } catch (_: Exception) {
                main.post { finish(id, "failed") }
            }
        }
    }

    private fun prepareScanner(record: ScanRecord) {
        val owner = activity.get()
        if (disposed || owner == null || owner.isFinishing || owner.isDestroyed) return
        try {
            val options = GmsDocumentScannerOptions.Builder()
                .setGalleryImportAllowed(true)
                .setPageLimit(record.limit)
                .setResultFormats(GmsDocumentScannerOptions.RESULT_FORMAT_JPEG)
                .setScannerMode(GmsDocumentScannerOptions.SCANNER_MODE_FULL)
                .build()
            GmsDocumentScanning.getClient(options).getStartScanIntent(owner)
                .addOnSuccessListener { sender ->
                    if (disposed || requestId != record.id) return@addOnSuccessListener
                    worker.execute {
                        try {
                            ScanInbox.write(context, record.copy(phase = "launched"))
                            main.post {
                                val current = activity.get()
                                if (disposed || current == null || current.isFinishing || current.isDestroyed) {
                                    return@post
                                }
                                try {
                                    preparing = false
                                    awaitingExternal = true
                                    pausedAfterLaunch = false
                                    @Suppress("DEPRECATION")
                                    current.startIntentSenderForResult(
                                        sender, REQUEST_CODE, null, 0, 0, 0
                                    )
                                } catch (_: Exception) {
                                    awaitingExternal = false
                                    finish(record.id, "failed")
                                }
                            }
                        } catch (_: Exception) {
                            main.post { finish(record.id, "failed") }
                        }
                    }
                }
                .addOnFailureListener { error ->
                    if (disposed || requestId != record.id) return@addOnFailureListener
                    finish(record.id, if (error is MlKitException &&
                        error.errorCode == MlKitException.UNSUPPORTED) "unsupported" else "failed")
                }
        } catch (_: Exception) {
            finish(record.id, "failed")
        }
    }

    /** A recreated Activity can finish the persisted request without its original Dart Future. */
    fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode != REQUEST_CODE) return false
        awaitingExternal = false
        pausedAfterLaunch = false
        preparing = false
        copying = true
        val idSnapshot = requestId
        val pages = try {
            if (resultCode == Activity.RESULT_OK) {
                GmsDocumentScanningResult.fromActivityResultIntent(data)?.pages?.map { it.imageUri }
            } else null
        } catch (_: Exception) {
            null
        }
        worker.execute {
            val id = idSnapshot ?: try {
                ScanInbox.all(context).lastOrNull {
                    it.status == "pending" && it.phase == "launched"
                }?.id
            } catch (_: Exception) { null }
            if (id == null) {
                main.post { copying = false }
                return@execute
            }
            val record = try {
                val prior = ScanInbox.read(context, id)
                    ?: ScanRecord(id, "pending", "launched", MAX_PAGES, System.currentTimeMillis())
                when {
                    resultCode == Activity.RESULT_CANCELED -> prior.copy(status = "cancelled", phase = "complete")
                    resultCode != Activity.RESULT_OK || pages.isNullOrEmpty() -> prior.copy(status = "failed", phase = "complete")
                    pages.size > prior.limit || pages.size > MAX_PAGES -> prior.copy(status = "too_many_pages", phase = "complete")
                    else -> {
                        ScanInbox.write(context, prior.copy(phase = "copying"))
                        val names = pages.mapIndexed { index, uri ->
                            ScanInbox.copyPage(context, id, index, uri)
                        }
                        prior.copy(status = "pages", phase = "complete", pages = names)
                    }
                }.also { ScanInbox.write(context, it) }
            } catch (_: Exception) {
                failedRecord(id)
            } catch (_: OutOfMemoryError) {
                failedRecord(id)
            }
            main.post { deliver(record) }
        }
        return true
    }

    private fun failedRecord(id: String): ScanRecord {
        val failed = ScanRecord(id, "failed", "complete", MAX_PAGES, System.currentTimeMillis())
        try { ScanInbox.write(context, failed) } catch (_: Exception) {}
        return failed
    }

    private fun finish(id: String, status: String) {
        preparing = false
        awaitingExternal = false
        copying = true
        worker.execute {
            val record = try {
                val prior = ScanInbox.read(context, id)
                    ?: ScanRecord(id, status, "complete", MAX_PAGES, System.currentTimeMillis())
                prior.copy(status = status, phase = "complete", pages = emptyList())
                    .also { ScanInbox.write(context, it) }
            } catch (_: Exception) { failedRecord(id) }
            main.post { deliver(record) }
        }
    }

    private fun deliver(record: ScanRecord) {
        if (disposed) return
        val value = try { ScanInbox.payload(context, record) }
            catch (_: Exception) { response(record.id, "failed") }
        if (requestId == record.id) {
            preparing = false
            awaitingExternal = false
            copying = false
            requestId = null
            val pendingReply = reply
            reply = null
            pendingReply?.success(value)
        } else if (requestId == null) {
            copying = false
        }
        channel?.invokeMethod("scanReady", value)
    }

    fun onSaveInstanceState(state: Bundle) {
        requestId?.let { state.putString(STATE_ID, it) }
        state.putBoolean(STATE_AWAITING, awaitingExternal)
    }

    fun onPause() {
        if (awaitingExternal) pausedAfterLaunch = true
    }

    fun onResume() {
        // Android delivers activity results before onResume. If an interrupted
        // setup/copy/launch has no surviving result, expose a terminal record for
        // Dart recovery instead of leaving an eternal pending request.
        val preserveId = if (preparing || copying ||
            (awaitingExternal && !pausedAfterLaunch)) requestId else null
        worker.execute {
            val abandoned = try {
                ScanInbox.all(context).filter { it.status == "pending" && it.id != preserveId }
                    .map { it.copy(status = "failed", phase = "complete", pages = emptyList()) }
                    .onEach { ScanInbox.write(context, it) }
            } catch (_: Exception) { emptyList() }
            main.post { abandoned.forEach(::deliver) }
        }
    }

    fun dispose() {
        if (disposed) return
        disposed = true
        val pendingReply = reply
        reply = null
        requestId?.let { pendingReply?.success(response(it, "pending")) }
        channel?.setMethodCallHandler(null)
        channel = null
        activity.clear()
    }

    companion object {
        private const val CHANNEL = "com.appsbay.onlynote/document_scan"
        private const val REQUEST_CODE = 62461
        private const val MAX_PAGES = 20
        private const val STATE_ID = "onlynote.document_scan.id"
        private const val STATE_AWAITING = "onlynote.document_scan.awaiting"
        private val main = Handler(Looper.getMainLooper())
        private val worker = Executors.newSingleThreadExecutor()

        private fun response(id: String, status: String): Map<String, Any> =
            mapOf("id" to id, "status" to status, "paths" to emptyList<String>())
    }
}

private data class ScanRecord(
    val id: String,
    val status: String,
    val phase: String,
    val limit: Int,
    val created: Long,
    val pages: List<String> = emptyList()
)

/** Every operation runs on the bridge's serial worker, including acknowledgements. */
private object ScanInbox {
    private const val MAX_PAGES = 20
    private const val MAX_FILE_BYTES = 30L * 1024 * 1024
    private val uuid = Regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$")
    private val page = Regex("^page_[0-9]+\\.jpg$")

    fun validId(id: String): Boolean = uuid.matches(id) && try {
        UUID.fromString(id).toString().equals(id, ignoreCase = true)
    } catch (_: IllegalArgumentException) { false }

    private fun root(context: Context): File {
        val files = context.filesDir.canonicalFile
        val root = File(files, "document_scans")
        require(root.canonicalFile == root.absoluteFile && root.parentFile == files)
        if (!root.exists() && !root.mkdirs()) throw IOException("Cannot create scan inbox")
        require(root.isDirectory)
        return root
    }

    private fun folder(context: Context, id: String): File {
        require(validId(id))
        val root = root(context)
        val folder = File(root, id)
        require(folder.canonicalFile == folder.absoluteFile && folder.parentFile == root)
        return folder
    }

    fun write(context: Context, record: ScanRecord) {
        val folder = folder(context, record.id)
        if (!folder.exists() && !folder.mkdir()) throw IOException("Cannot create scan request")
        require(folder.isDirectory)
        val json = JSONObject().put("version", 1).put("id", record.id)
            .put("status", record.status).put("phase", record.phase)
            .put("pageLimit", record.limit).put("createdAt", record.created)
            .put("pages", JSONArray(record.pages))
        val manifest = AtomicFile(File(folder, "manifest.json"))
        val output = manifest.startWrite()
        try {
            output.write(json.toString().toByteArray(Charsets.UTF_8))
            manifest.finishWrite(output)
        } catch (error: Exception) {
            manifest.failWrite(output)
            throw error
        }
    }

    fun read(context: Context, id: String): ScanRecord? {
        val folder = folder(context, id)
        if (!folder.exists()) return null
        val fallback = ScanRecord(id, "failed", "complete", MAX_PAGES, 0)
        return try {
            val manifest = AtomicFile(File(folder, "manifest.json"))
            val raw = manifest.openRead().use { stream ->
                val bytes = stream.readBytesLimited(64 * 1024)
                bytes.toString(Charsets.UTF_8)
            }
            val json = JSONObject(raw)
            require(json.optInt("version") == 1 && json.optString("id") == id)
            val status = json.getString("status")
            require(status in setOf("pending", "pages", "cancelled", "unsupported", "failed", "too_many_pages"))
            val limit = json.getInt("pageLimit")
            require(limit in 1..MAX_PAGES)
            val values = json.getJSONArray("pages")
            require(values.length() <= limit)
            val names = (0 until values.length()).map { values.getString(it) }
            require(names.distinct().size == names.size && names.all(page::matches))
            if (status == "pages") require(names.isNotEmpty())
            else require(names.isEmpty())
            ScanRecord(id, status, json.getString("phase"), limit,
                json.getLong("createdAt"), names)
        } catch (_: Exception) { fallback }
    }

    fun all(context: Context): List<ScanRecord> = root(context).listFiles().orEmpty()
        .filter { it.isDirectory && validId(it.name) && it.canonicalFile == it.absoluteFile }
        .mapNotNull { read(context, it.name) }.sortedBy { it.created }

    fun payload(context: Context, record: ScanRecord): Map<String, Any> {
        val folder = folder(context, record.id)
        val paths = if (record.status == "pages") record.pages.map { name ->
            require(page.matches(name))
            val file = File(folder, name)
            require(file.canonicalFile == file.absoluteFile && file.parentFile == folder &&
                file.isFile && file.length() in 1..MAX_FILE_BYTES)
            file.absolutePath
        } else emptyList()
        return mapOf("id" to record.id, "status" to record.status, "paths" to paths)
    }

    fun copyPage(context: Context, id: String, index: Int, uri: Uri): String {
        require(index in 0 until MAX_PAGES)
        require(uri.scheme == "content" || uri.scheme == "file")
        if (uri.scheme == "file") {
            val source = File(uri.path ?: throw IOException("Missing scan path")).canonicalFile
            require(listOf(context.filesDir, context.cacheDir).any {
                source.path.startsWith(it.canonicalPath + File.separator)
            })
        }
        val folder = folder(context, id)
        val name = "page_$index.jpg"
        val destination = File(folder, name)
        val pending = File(folder, "$name.partial")
        require(destination.canonicalFile == destination.absoluteFile &&
            pending.canonicalFile == pending.absoluteFile)
        try {
            context.contentResolver.openInputStream(uri).use { input ->
                if (input == null) throw IOException("Cannot read scan page")
                FileOutputStream(pending).use { output ->
                    val buffer = ByteArray(64 * 1024)
                    val signature = ByteArray(3)
                    var length = 0L
                    while (true) {
                        val count = input.read(buffer)
                        if (count < 0) break
                        if (count == 0) continue
                        for (offset in 0 until minOf(count, (3 - length).coerceAtLeast(0).toInt())) {
                            signature[length.toInt() + offset] = buffer[offset]
                        }
                        length += count
                        if (length > MAX_FILE_BYTES) throw IOException("Scan page is too large")
                        output.write(buffer, 0, count)
                    }
                    require(length >= 3 && signature[0] == 0xff.toByte() &&
                        signature[1] == 0xd8.toByte() && signature[2] == 0xff.toByte())
                    output.fd.sync()
                }
            }
            if (!pending.renameTo(destination)) throw IOException("Cannot retain scan page")
            return name
        } catch (error: Exception) {
            pending.delete()
            throw error
        }
    }

    fun acknowledge(context: Context, id: String) {
        val folder = folder(context, id)
        if (!folder.exists()) return
        // Inbox requests contain only direct files. Never traverse unexpected
        // directories/symlinks when deleting an acknowledged UUID request.
        for (child in folder.listFiles().orEmpty()) {
            require(child.canonicalFile == child.absoluteFile && child.parentFile == folder &&
                !child.isDirectory)
            if (!child.delete() && child.exists()) throw IOException("Cannot remove retained scan")
        }
        if (!folder.delete() && folder.exists()) throw IOException("Cannot remove scan request")
    }

    private fun java.io.InputStream.readBytesLimited(limit: Int): ByteArray {
        val output = java.io.ByteArrayOutputStream()
        val buffer = ByteArray(4096)
        while (true) {
            val count = read(buffer)
            if (count < 0) break
            if (count == 0) continue
            if (output.size() + count > limit) throw IOException("Scan manifest is too large")
            output.write(buffer, 0, count)
        }
        return output.toByteArray()
    }
}
