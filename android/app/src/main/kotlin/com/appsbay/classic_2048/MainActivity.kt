package com.appsbay.onlynote

import android.content.Intent
import android.os.Bundle
import java.util.UUID
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private var shortcutChannel: MethodChannel? = null
    private var shortcutBridgeReady = false
    private var pendingShortcut: Map<String, String>? = null
    private var shareChannel: MethodChannel? = null
    private var documentScanBridge: DocumentScanBridge? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        captureShortcut(intent)
        documentScanBridge = DocumentScanBridge(this, savedInstanceState)
        super.onCreate(savedInstanceState)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        WidgetCommandBridge.register(this, flutterEngine.dartExecutor.binaryMessenger)
        PhotoTextBridge.register(this, flutterEngine.dartExecutor.binaryMessenger)
        documentScanBridge?.register(flutterEngine.dartExecutor.binaryMessenger)
        VoiceMemoBridge.register(this, flutterEngine.dartExecutor.binaryMessenger)
        shareChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.appsbay.onlynote/shared_notes"
        ).also { channel ->
            channel.setMethodCallHandler { call, result ->
                if (call.method != "pending" && call.method != "acknowledge") {
                    result.notImplemented()
                } else {
                    val id = call.argument<String>("id")
                    Thread {
                        try {
                            val value = if (call.method == "pending") {
                                ShareInboxStore.pending(applicationContext)
                            } else {
                                require(id != null)
                                ShareInboxStore.acknowledge(applicationContext, id)
                                null
                            }
                            runOnUiThread { result.success(value) }
                        } catch (_: Throwable) {
                            runOnUiThread {
                                result.error("share_inbox", "Shared content is retained for retry.", null)
                            }
                        }
                    }.start()
                }
            }
        }
        shortcutBridgeReady = false
        shortcutChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.appsbay.onlynote/app_shortcuts"
        ).also { channel ->
            channel.setMethodCallHandler { call, result ->
                if (call.method == "initialize") {
                    shortcutBridgeReady = true
                    val initial = pendingShortcut
                    pendingShortcut = null
                    result.success(initial)
                } else {
                    result.notImplemented()
                }
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        captureShortcut(intent)
        if (intent.getBooleanExtra(ShareInboxStore.EXTRA_INBOX_CHANGED, false)) {
            intent.removeExtra(ShareInboxStore.EXTRA_INBOX_CHANGED)
            shareChannel?.invokeMethod("inboxChanged", null)
        }
    }

    private fun captureShortcut(intent: Intent?) {
        val type = intent?.getStringExtra(ShortcutActivity.EXTRA_SHORTCUT) ?: return
        if (type !in listOf("new_note", "new_checklist", "photo_note", "voice_note")) return
        // An activity recreation must not replay an already consumed action.
        intent.removeExtra(ShortcutActivity.EXTRA_SHORTCUT)
        val request = mapOf("id" to UUID.randomUUID().toString(), "type" to type)
        if (shortcutBridgeReady) {
            shortcutChannel?.invokeMethod("shortcutTapped", request)
        } else {
            pendingShortcut = request
        }
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        documentScanBridge?.dispose()
        VoiceMemoBridge.dispose()
        shareChannel?.setMethodCallHandler(null)
        shareChannel = null
        shortcutChannel?.setMethodCallHandler(null)
        shortcutChannel = null
        shortcutBridgeReady = false
        super.cleanUpFlutterEngine(flutterEngine)
    }

    override fun onResume() {
        super.onResume()
        documentScanBridge?.onResume()
        VoiceMemoBridge.onResume()
    }

    override fun onPause() {
        documentScanBridge?.onPause()
        VoiceMemoBridge.onBackground()
        super.onPause()
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        if (!VoiceMemoBridge.onRequestPermissionsResult(requestCode, grantResults)) {
            super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        }
    }

    @Suppress("DEPRECATION")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (documentScanBridge?.onActivityResult(requestCode, resultCode, data) != true) {
            super.onActivityResult(requestCode, resultCode, data)
        }
    }

    override fun onSaveInstanceState(outState: Bundle) {
        documentScanBridge?.onSaveInstanceState(outState)
        super.onSaveInstanceState(outState)
    }

    override fun onDestroy() {
        documentScanBridge?.dispose()
        VoiceMemoBridge.dispose()
        super.onDestroy()
    }
}
