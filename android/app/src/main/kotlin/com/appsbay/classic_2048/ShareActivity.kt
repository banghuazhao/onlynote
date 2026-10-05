package com.appsbay.onlynote

import android.app.Activity
import android.content.Intent
import android.os.Bundle
import android.view.Gravity
import android.widget.LinearLayout
import android.widget.ProgressBar
import android.widget.TextView
import android.widget.Toast
import java.util.UUID

/** Keep the grant-bearing activity alive until its content URIs are copied. */
class ShareActivity : Activity() {
    private lateinit var deliveryId: String

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        deliveryId = savedInstanceState?.getString("delivery_id") ?: UUID.randomUUID().toString()
        val content = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setPadding(32, 32, 32, 32)
            addView(ProgressBar(this@ShareActivity))
            addView(TextView(this@ShareActivity).apply {
                text = getString(R.string.share_loading)
                gravity = Gravity.CENTER
                textSize = 18f
                setPadding(0, 24, 0, 0)
            })
        }
        setContentView(content)
        val incoming = intent
        // URI permissions belong to this activity; never finish before staging.
        Thread {
            try {
                ShareInboxStore.stage(applicationContext, incoming, deliveryId)
                runOnUiThread {
                    startActivity(Intent(this, MainActivity::class.java).apply {
                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP)
                        putExtra(ShareInboxStore.EXTRA_INBOX_CHANGED, true)
                    })
                    finish()
                }
            } catch (_: Throwable) {
                runOnUiThread {
                    Toast.makeText(this, R.string.share_failed, Toast.LENGTH_LONG).show()
                    finish()
                }
            }
        }.start()
    }

    override fun onSaveInstanceState(outState: Bundle) {
        outState.putString("delivery_id", deliveryId)
        super.onSaveInstanceState(outState)
    }
}
