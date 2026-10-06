package com.appsbay.onlynote

import android.app.Activity
import android.content.Intent
import android.os.Bundle

/**
 * Static launcher shortcuts use CLEAR_TASK. A separate task affinity confines
 * that flag to this invisible activity and keeps the live Flutter draft alive.
 */
class ShortcutActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val type = when (intent.action) {
            "com.appsbay.onlynote.NEW_NOTE" -> "new_note"
            "com.appsbay.onlynote.NEW_CHECKLIST" -> "new_checklist"
            "com.appsbay.onlynote.PHOTO_NOTE" -> "photo_note"
            "com.appsbay.onlynote.VOICE_NOTE" -> "voice_note"
            else -> null
        }
        if (type != null) {
            startActivity(Intent(this, MainActivity::class.java).apply {
                action = Intent.ACTION_MAIN
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                    Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP
                putExtra(EXTRA_SHORTCUT, type)
            })
        }
        finish()
    }

    companion object {
        const val EXTRA_SHORTCUT = "com.appsbay.onlynote.capture_shortcut"
    }
}
