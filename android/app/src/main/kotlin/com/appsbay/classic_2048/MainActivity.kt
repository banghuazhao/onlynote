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

    override fun onCreate(savedInstanceState: Bundle?) {
        captureShortcut(intent)
        super.onCreate(savedInstanceState)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
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
    }

    private fun captureShortcut(intent: Intent?) {
        val type = intent?.getStringExtra(ShortcutActivity.EXTRA_SHORTCUT) ?: return
        if (type !in listOf("new_note", "new_checklist", "photo_note")) return
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
        shortcutChannel?.setMethodCallHandler(null)
        shortcutChannel = null
        shortcutBridgeReady = false
        super.cleanUpFlutterEngine(flutterEngine)
    }
}
