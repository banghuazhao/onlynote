package com.appsbay.onlynote

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Matrix
import android.media.ExifInterface
import android.os.Build
import android.os.Handler
import android.os.Looper
import com.google.android.gms.tasks.Tasks
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.text.TextRecognition
import com.google.mlkit.vision.text.chinese.ChineseTextRecognizerOptions
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.concurrent.Executors

/** Bundled Latin + Chinese OCR, operating only on an existing note-owned file. */
object PhotoTextBridge {
    private const val CHANNEL = "com.appsbay.onlynote/photo_text"
    private const val MAX_FILE_BYTES = 64L * 1024 * 1024
    private const val MAX_EDGE = 3200
    private const val MAX_PIXELS = 10_000_000L
    private const val MAX_TEXT_LENGTH = 100_000
    private val worker = Executors.newSingleThreadExecutor()
    private val main = Handler(Looper.getMainLooper())

    fun register(context: Context, messenger: BinaryMessenger) {
        val appContext = context.applicationContext
        MethodChannel(messenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method != "recognize") {
                result.notImplemented()
                return@setMethodCallHandler
            }
            val path = call.argument<String>("path")
            if (path == null) {
                result.success(mapOf("status" to "failed"))
                return@setMethodCallHandler
            }
            worker.execute {
                val response = recognize(appContext, path)
                main.post { result.success(response) }
            }
        }
    }

    private fun recognize(context: Context, path: String): Map<String, String> {
        if (Build.VERSION.SDK_INT < 23) return mapOf("status" to "unsupported")
        var bitmap: Bitmap? = null
        try {
            if (!path.startsWith("/") || path.contains('\u0000')) {
                return mapOf("status" to "failed")
            }
            // This is path_provider's application documents directory on Android.
            val documents = context.getDir("flutter", Context.MODE_PRIVATE).canonicalFile
            val root = File(documents, "note_images").canonicalFile
            val file = File(path).canonicalFile
            if (root.parentFile != documents || file.parentFile != root ||
                !file.isFile || file.length() !in 1..MAX_FILE_BYTES) {
                return mapOf("status" to "failed")
            }
            val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
            BitmapFactory.decodeFile(file.path, bounds)
            val width = bounds.outWidth
            val height = bounds.outHeight
            if (width <= 0 || height <= 0 || width > 50_000 || height > 50_000 ||
                width.toLong() * height > 250_000_000L) {
                return mapOf("status" to "failed")
            }
            var sample = 1
            while (width / sample > MAX_EDGE || height / sample > MAX_EDGE ||
                (width.toLong() / sample) * (height.toLong() / sample) > MAX_PIXELS) {
                sample *= 2
            }
            bitmap = BitmapFactory.decodeFile(file.path, BitmapFactory.Options().apply {
                inSampleSize = sample
                inScaled = false
                inPreferredConfig = Bitmap.Config.ARGB_8888
            }) ?: return mapOf("status" to "failed")
            val orientation = try {
                ExifInterface(file.path).getAttributeInt(
                    ExifInterface.TAG_ORIENTATION, ExifInterface.ORIENTATION_NORMAL
                )
            } catch (_: Exception) {
                // PNG screenshots and other images without EXIF are upright.
                ExifInterface.ORIENTATION_NORMAL
            }
            val transformed = upright(bitmap, orientation)
            if (transformed !== bitmap) {
                bitmap.recycle()
                bitmap = transformed
            }
            val recognizer = TextRecognition.getClient(
                ChineseTextRecognizerOptions.Builder().build()
            )
            val text = try {
                // Wait only on our dedicated serial worker, never Android's UI
                // thread. Retain pixels until ML Kit completes, then release them.
                Tasks.await(recognizer.process(InputImage.fromBitmap(bitmap, 0)))
                    .text.trim()
            } finally {
                recognizer.close()
            }
            return when {
                text.length > MAX_TEXT_LENGTH -> mapOf("status" to "failed")
                text.isEmpty() -> mapOf("status" to "no_text")
                else -> mapOf("status" to "text", "text" to text)
            }
        } catch (_: Exception) {
            return mapOf("status" to "failed")
        } catch (_: OutOfMemoryError) {
            return mapOf("status" to "failed")
        } finally {
            bitmap?.recycle()
        }
    }

    /** Apply all EXIF rotation and reflection values exactly once. */
    private fun upright(bitmap: Bitmap, orientation: Int): Bitmap {
        val matrix = Matrix()
        when (orientation) {
            ExifInterface.ORIENTATION_FLIP_HORIZONTAL -> matrix.setScale(-1f, 1f)
            ExifInterface.ORIENTATION_ROTATE_180 -> matrix.setRotate(180f)
            ExifInterface.ORIENTATION_FLIP_VERTICAL -> matrix.setScale(1f, -1f)
            ExifInterface.ORIENTATION_TRANSPOSE -> {
                matrix.setRotate(90f)
                matrix.postScale(-1f, 1f)
            }
            ExifInterface.ORIENTATION_ROTATE_90 -> matrix.setRotate(90f)
            ExifInterface.ORIENTATION_TRANSVERSE -> {
                matrix.setRotate(270f)
                matrix.postScale(-1f, 1f)
            }
            ExifInterface.ORIENTATION_ROTATE_270 -> matrix.setRotate(270f)
            else -> return bitmap
        }
        return Bitmap.createBitmap(bitmap, 0, 0, bitmap.width, bitmap.height, matrix, true)
    }
}
