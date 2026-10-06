package com.appsbay.onlynote

import android.Manifest
import android.app.Activity
import android.content.Intent
import android.content.Context
import android.content.pm.PackageManager
import android.media.*
import android.os.*
import android.speech.*
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.lang.ref.WeakReference
import java.util.Locale
import java.util.UUID
import java.util.concurrent.Executors

/** One main-thread media session; background decoding never touches Hive. */
object VoiceMemoBridge {
    private const val PERMISSION = 64129
    private val handler = Handler(Looper.getMainLooper())
    private val worker = Executors.newSingleThreadExecutor()
    private var activity = WeakReference<Activity>(null)
    private var channel: MethodChannel? = null
    private var foreground = true
    private var recorder: MediaRecorder? = null
    private var recordingPath: String? = null
    private var started = 0L
    private var durationMs = 0
    private var interrupted = false
    private var player: MediaPlayer? = null
    private var playbackPath: String? = null
    private var pendingPermission: Pair<String, MethodChannel.Result>? = null
    private var recognition: SpeechRecognizer? = null
    private var speechResult: MethodChannel.Result? = null
    private var speechToken: String? = null
    private var audioPipe: Array<ParcelFileDescriptor>? = null
    private var prepareResult: MethodChannel.Result? = null
    private var focusRequest: AudioFocusRequest? = null
    private val focusListener = AudioManager.OnAudioFocusChangeListener { focus ->
        if (focus == AudioManager.AUDIOFOCUS_LOSS || focus == AudioManager.AUDIOFOCUS_LOSS_TRANSIENT) {
            interrupted = interrupted || recorder != null
            stopRecording(); stopPlayback(); finishSpeech(null, "cancelled"); emit()
        }
    }
    private val tick = object : Runnable {
        override fun run() {
            emit()
            if (recorder != null || player?.isPlaying == true) handler.postDelayed(this, 250)
        }
    }
    private val timeout = Runnable { finishSpeech(null, "transcription_timeout") }

    fun register(owner: Activity, messenger: BinaryMessenger) {
        activity = WeakReference(owner)
        channel = MethodChannel(messenger, "com.appsbay.onlynote/voice_memos")
        channel?.setMethodCallHandler { call, result ->
            try {
                val path = call.argument<String>("path")
                when (call.method) {
                    "state" -> result.success(state())
                    "startRecording" -> {
                        if (recorder != null || pendingPermission != null || speechResult != null) { result.error("busy", null, null); return@setMethodCallHandler }
                        val file = ownedFile(path, true)
                        if (file.exists()) { result.error("file_exists", null, null); return@setMethodCallHandler }
                        if (owner.checkSelfPermission(Manifest.permission.RECORD_AUDIO) != PackageManager.PERMISSION_GRANTED) {
                            pendingPermission = Pair(file.path, result)
                            owner.requestPermissions(arrayOf(Manifest.permission.RECORD_AUDIO), PERMISSION)
                        } else startRecording(file.path, result)
                    }
                    "stopRecording" -> { stopRecording(); result.success(state()) }
                    "cancelRecording" -> { stopRecording(); recordingPath = null; durationMs = 0; emit(); result.success(state()) }
                    "play" -> play(ownedFile(path).path, result)
                    "pause" -> { player?.pause(); abandonFocus(); emit(); result.success(state()) }
                    "stopPlayback" -> { stopPlayback(); emit(); result.success(state()) }
                    "duration" -> result.success(probe(ownedFile(path)))
                    "transcribe" -> transcribe(ownedFile(path), call.argument<String>("locale") ?: Locale.getDefault().toLanguageTag(), result)
                    "cancelTranscription" -> { finishSpeech(null, "cancelled"); result.success(state()) }
                    "background" -> { onBackground(); result.success(state()) }
                    else -> result.notImplemented()
                }
            } catch (error: Exception) {
                if (speechResult === result) finishSpeech(null, "transcription_failed")
                else {
                    if (prepareResult === result) { prepareResult = null; stopPlayback() }
                    result.error("media_failed", error.message, null)
                }
            }
        }
    }

    fun onResume() { foreground = true }
    fun onBackground() {
        foreground = false
        interrupted = interrupted || recorder != null
        stopRecording(); stopPlayback(); finishSpeech(null, "cancelled"); emit()
    }
    fun dispose() {
        onBackground()
        pendingPermission?.second?.error("cancelled", null, null); pendingPermission = null
        channel?.setMethodCallHandler(null); channel = null
        activity.clear()
    }
    fun onRequestPermissionsResult(requestCode: Int, grantResults: IntArray): Boolean {
        if (requestCode != PERMISSION) return false
        val pending = pendingPermission ?: return true
        pendingPermission = null
        if (grantResults.firstOrNull() != PackageManager.PERMISSION_GRANTED) pending.second.error("permission_denied", null, null)
        else handler.post {
            if (foreground) startRecording(pending.first, pending.second)
            else pending.second.error("interrupted", null, null)
        }
        return true
    }
    private fun ownedFile(path: String?, recording: Boolean = false): File {
        val owner = activity.get() ?: error("Activity unavailable")
        require(path != null && path.startsWith('/') && !path.contains('\u0000') && !path.split('/').contains(".."))
        val file = File(path).canonicalFile
        val roots = listOf(owner.filesDir.canonicalPath, File(owner.applicationInfo.dataDir, "app_flutter").canonicalPath)
        require(roots.any { file.path.startsWith("$it/note_audio/") || (!recording && file.path.startsWith("$it/template_audio/")) })
        require(file.extension.lowercase() == "m4a")
        if (recording) check(file.parentFile?.mkdirs() == true || file.parentFile?.isDirectory == true)
        return file
    }
    @Suppress("DEPRECATION")
    private fun startRecording(path: String, result: MethodChannel.Result) {
        try {
            if (!foreground) { result.error("interrupted", null, null); return }
            stopPlayback()
            val owner = activity.get() ?: error("Activity unavailable")
            check(requestFocus()) { "Audio is in use" }
            val audio = if (Build.VERSION.SDK_INT >= 31) MediaRecorder(owner) else MediaRecorder()
            recorder = audio
            audio.setAudioSource(MediaRecorder.AudioSource.MIC)
            audio.setOutputFormat(MediaRecorder.OutputFormat.MPEG_4)
            audio.setAudioEncoder(MediaRecorder.AudioEncoder.AAC)
            audio.setAudioSamplingRate(44100)
            audio.setAudioEncodingBitRate(96000)
            audio.setAudioChannels(1)
            audio.setOutputFile(path)
            audio.setMaxDuration(300000)
            audio.setOnInfoListener { _, what, _ -> if (what == MediaRecorder.MEDIA_RECORDER_INFO_MAX_DURATION_REACHED) stopRecording() }
            audio.setOnErrorListener { _, _, _ -> interrupted = true; stopRecording() }
            audio.prepare(); audio.start()
            recorder = audio; recordingPath = path; started = SystemClock.elapsedRealtime()
            durationMs = 0; interrupted = false
            handler.removeCallbacks(tick); handler.post(tick)
            result.success(state())
        } catch (error: Exception) {
            recorder?.release(); recorder = null; abandonFocus()
            File(path).delete()
            result.error("record_failed", error.message, null)
        }
    }
    private fun stopRecording() {
        val audio = recorder ?: return
        recorder = null
        durationMs = (SystemClock.elapsedRealtime() - started).toInt().coerceIn(0, 300000)
        try { audio.stop() } catch (_: RuntimeException) { durationMs = 0; recordingPath?.let { File(it).delete() } }
        audio.release(); abandonFocus()
        handler.removeCallbacks(tick); emit()
    }
    private fun play(path: String, result: MethodChannel.Result) {
        if (!foreground) { result.error("interrupted", null, null); return }
        if (recorder != null || pendingPermission != null || speechResult != null) { result.error("busy", null, null); return }
        if (playbackPath == path && player != null && prepareResult == null) {
            if (!requestFocus()) { result.error("play_failed", "Audio is in use", null); return }
            player?.start(); handler.post(tick); emit(); result.success(state()); return
        }
        stopPlayback()
        if (!requestFocus()) { result.error("play_failed", "Audio is in use", null); return }
        val audio = MediaPlayer()
        player = audio; playbackPath = path; prepareResult = result
        audio.setAudioAttributes(AudioAttributes.Builder().setContentType(AudioAttributes.CONTENT_TYPE_SPEECH).setUsage(AudioAttributes.USAGE_MEDIA).build())
        audio.setDataSource(path)
        audio.setOnPreparedListener {
            if (player !== audio || !foreground) return@setOnPreparedListener
            audio.start(); val pending = prepareResult; prepareResult = null
            handler.post(tick); emit(); pending?.success(state())
        }
        audio.setOnCompletionListener { stopPlayback(); emit() }
        audio.setOnErrorListener { _, _, _ ->
            prepareResult?.error("play_failed", null, null); prepareResult = null
            stopPlayback(); emit(); true
        }
        audio.prepareAsync()
    }
    private fun stopPlayback() {
        prepareResult?.error("cancelled", null, null); prepareResult = null
        player?.release(); player = null; playbackPath = null
        handler.removeCallbacks(tick); abandonFocus()
    }
    @Suppress("DEPRECATION")
    private fun requestFocus(): Boolean {
        val owner = activity.get() ?: return false
        val manager = owner.getSystemService(Context.AUDIO_SERVICE) as AudioManager
        return if (Build.VERSION.SDK_INT >= 26) {
            val request = AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN_TRANSIENT)
                .setAudioAttributes(AudioAttributes.Builder().setUsage(AudioAttributes.USAGE_MEDIA).setContentType(AudioAttributes.CONTENT_TYPE_SPEECH).build())
                .setOnAudioFocusChangeListener(focusListener, handler).build()
            focusRequest = request
            manager.requestAudioFocus(request) == AudioManager.AUDIOFOCUS_REQUEST_GRANTED
        } else manager.requestAudioFocus(focusListener, AudioManager.STREAM_MUSIC, AudioManager.AUDIOFOCUS_GAIN_TRANSIENT) == AudioManager.AUDIOFOCUS_REQUEST_GRANTED
    }
    @Suppress("DEPRECATION")
    private fun abandonFocus() {
        val owner = activity.get() ?: return
        val manager = owner.getSystemService(Context.AUDIO_SERVICE) as AudioManager
        if (Build.VERSION.SDK_INT >= 26) focusRequest?.let { manager.abandonAudioFocusRequest(it) }
        else manager.abandonAudioFocus(focusListener)
        focusRequest = null
    }
    private fun probe(file: File): Int {
        val metadata = MediaMetadataRetriever()
        return try {
            metadata.setDataSource(file.path)
            val duration = metadata.extractMetadata(MediaMetadataRetriever.METADATA_KEY_DURATION)?.toIntOrNull() ?: 0
            require(duration in 1..300500)
            duration
        } finally { metadata.release() }
    }
    private fun state(): Map<String, Any> = mapOf(
        "phase" to when { recorder != null -> "recording"; speechResult != null -> "transcribing"; player?.isPlaying == true -> "playing"; player != null -> "paused"; else -> "idle" },
        "path" to (playbackPath ?: recordingPath ?: ""),
        "durationMs" to (if (recorder != null) (SystemClock.elapsedRealtime() - started).toInt() else player?.let { try { it.duration } catch (_: Exception) { durationMs } } ?: durationMs),
        "positionMs" to (player?.let { try { it.currentPosition } catch (_: Exception) { 0 } } ?: 0),
        "interrupted" to interrupted,
        "transcriptionSupported" to (Build.VERSION.SDK_INT >= 33 && activity.get()?.let { SpeechRecognizer.isOnDeviceRecognitionAvailable(it) } == true),
    )
    private fun emit() { channel?.invokeMethod("stateChanged", state()) }

    private fun transcribe(file: File, locale: String, result: MethodChannel.Result) {
        if (!foreground) { result.error("interrupted", null, null); return }
        val owner = activity.get() ?: error("Activity unavailable")
        if (recorder != null || pendingPermission != null || speechResult != null) { result.error("busy", null, null); return }
        if (Build.VERSION.SDK_INT < 33 || !SpeechRecognizer.isOnDeviceRecognitionAvailable(owner)) {
            result.error("transcription_unavailable", null, null); return
        }
        stopPlayback()
        val token = UUID.randomUUID().toString()
        speechToken = token; speechResult = result
        val pipes = ParcelFileDescriptor.createPipe(); audioPipe = pipes
        val speech = SpeechRecognizer.createOnDeviceSpeechRecognizer(owner); recognition = speech
        val language = Locale.forLanguageTag(locale).toLanguageTag()
        // Decode AAC to PCM on the worker. The supplied descriptor is an audio
        // stream, not a URI to a compressed file, and the recognizer closes at EOF.
        val intent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
            putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
            putExtra(RecognizerIntent.EXTRA_LANGUAGE, language)
            putExtra(RecognizerIntent.EXTRA_AUDIO_SOURCE, pipes[0])
            putExtra(RecognizerIntent.EXTRA_AUDIO_SOURCE_CHANNEL_COUNT, 1)
            putExtra(RecognizerIntent.EXTRA_AUDIO_SOURCE_ENCODING, AudioFormat.ENCODING_PCM_16BIT)
            putExtra(RecognizerIntent.EXTRA_AUDIO_SOURCE_SAMPLING_RATE, 44100)
            putExtra(RecognizerIntent.EXTRA_SEGMENTED_SESSION, RecognizerIntent.EXTRA_AUDIO_SOURCE)
            putExtra(RecognizerIntent.EXTRA_PARTIAL_RESULTS, false)
        }
        val segments = mutableListOf<String>()
        speech.setRecognitionListener(object : RecognitionListener {
            override fun onReadyForSpeech(params: Bundle?) = Unit
            override fun onBeginningOfSpeech() = Unit
            override fun onRmsChanged(rmsdB: Float) = Unit
            override fun onBufferReceived(buffer: ByteArray?) = Unit
            override fun onEndOfSpeech() = Unit
            override fun onError(error: Int) { if (speechToken == token) finishSpeech(null, "transcription_failed") }
            override fun onResults(results: Bundle?) {
                if (speechToken == token) finishSpeech(results?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)?.firstOrNull(), null)
            }
            override fun onPartialResults(partialResults: Bundle?) = Unit
            override fun onEvent(eventType: Int, params: Bundle?) = Unit
            override fun onSegmentResults(segmentResults: Bundle) {
                segmentResults.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)?.firstOrNull()?.let { segments.add(it) }
            }
            override fun onEndOfSegmentedSession() { if (speechToken == token) finishSpeech(segments.joinToString(" "), null) }
        })
        handler.postDelayed(timeout, 60000)
        speech.checkRecognitionSupport(intent, owner.mainExecutor, object : RecognitionSupportCallback {
            override fun onSupportResult(support: RecognitionSupport) {
                if (speechToken != token) return
                val installed = support.installedOnDeviceLanguages
                if (installed.none { it.equals(language, true) || it.substringBefore('-').equals(language.substringBefore('-'), true) }) {
                    finishSpeech(null, "transcription_unavailable"); return
                }
                speech.startListening(intent)
                worker.execute {
                    try { decode(file, pipes[1]) }
                    catch (_: Exception) { handler.post { if (speechToken == token) finishSpeech(null, "transcription_failed") } }
                }
            }
            override fun onError(error: Int) { if (speechToken == token) finishSpeech(null, "transcription_unavailable") }
        })
        emit()
    }
    private fun finishSpeech(text: String?, code: String?) {
        val pending = speechResult ?: return
        speechResult = null; speechToken = null
        handler.removeCallbacks(timeout)
        recognition?.cancel(); recognition?.destroy(); recognition = null
        audioPipe?.forEach { try { it.close() } catch (_: Exception) {} }; audioPipe = null
        emit()
        if (code != null) pending.error(code, null, null)
        else if (text.isNullOrBlank()) pending.error("no_speech", null, null)
        else pending.success(text.trim())
    }
    private fun decode(file: File, descriptor: ParcelFileDescriptor) {
        val extractor = MediaExtractor()
        var codec: MediaCodec? = null
        try {
            extractor.setDataSource(file.path)
            val track = (0 until extractor.trackCount).first { extractor.getTrackFormat(it).getString(MediaFormat.KEY_MIME)?.startsWith("audio/") == true }
            extractor.selectTrack(track)
            val format = extractor.getTrackFormat(track)
            require(format.getInteger(MediaFormat.KEY_CHANNEL_COUNT) == 1 && format.getInteger(MediaFormat.KEY_SAMPLE_RATE) == 44100)
            val decoder = MediaCodec.createDecoderByType(format.getString(MediaFormat.KEY_MIME)!!)
            codec = decoder
            decoder.configure(format, null, null, 0); decoder.start()
            ParcelFileDescriptor.AutoCloseOutputStream(descriptor).use { output ->
                var inputEnded = false
                var outputEnded = false
                val info = MediaCodec.BufferInfo()
                while (!outputEnded) {
                    if (Thread.currentThread().isInterrupted) throw InterruptedException()
                    if (!inputEnded) {
                        val index = decoder.dequeueInputBuffer(10000)
                        if (index >= 0) {
                            val buffer = decoder.getInputBuffer(index)!!
                            val count = extractor.readSampleData(buffer, 0)
                            if (count < 0) { decoder.queueInputBuffer(index, 0, 0, 0, MediaCodec.BUFFER_FLAG_END_OF_STREAM); inputEnded = true }
                            else { decoder.queueInputBuffer(index, 0, count, extractor.sampleTime, 0); extractor.advance() }
                        }
                    }
                    val index = decoder.dequeueOutputBuffer(info, 10000)
                    if (index >= 0) {
                        if (info.size > 0) {
                            val buffer = decoder.getOutputBuffer(index)!!
                            buffer.position(info.offset); buffer.limit(info.offset + info.size)
                            val bytes = ByteArray(info.size); buffer.get(bytes); output.write(bytes)
                        }
                        outputEnded = info.flags and MediaCodec.BUFFER_FLAG_END_OF_STREAM != 0
                        decoder.releaseOutputBuffer(index, false)
                    } else if (index == MediaCodec.INFO_OUTPUT_FORMAT_CHANGED) {
                        val actual = decoder.outputFormat
                        require(!actual.containsKey(MediaFormat.KEY_PCM_ENCODING) || actual.getInteger(MediaFormat.KEY_PCM_ENCODING) == AudioFormat.ENCODING_PCM_16BIT)
                    }
                }
            }
        } finally { try { codec?.stop() } catch (_: Exception) {} ; codec?.release(); extractor.release() }
    }
}
