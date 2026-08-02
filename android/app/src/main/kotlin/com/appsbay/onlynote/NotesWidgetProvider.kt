package com.appsbay.onlynote

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.net.Uri
import android.os.Build
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

class NotesWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val payload = WidgetPayload.from(widgetData)

        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.notes_widget)

            views.setOnClickPendingIntent(
                R.id.widget_new_note,
                launchIntent(context, REQUEST_NEW_NOTE, WidgetUris.newNote()),
            )
            views.setOnClickPendingIntent(
                R.id.widget_header_title,
                launchIntent(context, REQUEST_OPEN_APP, WidgetUris.openApp()),
            )

            bindList(context, views, widgetId)
            bindOverflow(context, views, payload)

            appWidgetManager.updateAppWidget(widgetId, views)
            // The adapter caches its data; without this the list keeps showing
            // the previous notes after a save.
            appWidgetManager.notifyAppWidgetViewDataChanged(widgetId, R.id.widget_list)
        }
    }

    @Suppress("DEPRECATION")
    private fun bindList(context: Context, views: RemoteViews, widgetId: Int) {
        val serviceIntent = Intent(context, NotesWidgetService::class.java).apply {
            putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, widgetId)
            // RemoteViews adapters are cached by intent identity, and extras are
            // not part of that identity — without a per-widget data URI every
            // instance on the home screen would share one factory.
            data = Uri.parse(toUri(Intent.URI_INTENT_SCHEME))
        }

        // setRemoteAdapter(int, Intent) is deprecated in API 31 in favour of
        // RemoteCollectionItems, but that path needs API 31 and this app ships
        // to API 24.
        views.setRemoteAdapter(R.id.widget_list, serviceIntent)
        views.setEmptyView(R.id.widget_list, R.id.widget_empty)
        views.setPendingIntentTemplate(R.id.widget_list, noteTemplate(context))

        views.setOnClickPendingIntent(
            R.id.widget_empty,
            launchIntent(context, REQUEST_EMPTY_STATE, WidgetUris.newNote()),
        )
    }

    private fun bindOverflow(context: Context, views: RemoteViews, payload: WidgetPayload) {
        val remaining = payload.total - payload.notes.size
        if (remaining > 0) {
            views.setViewVisibility(R.id.widget_more, View.VISIBLE)
            views.setTextViewText(
                R.id.widget_more,
                context.getString(R.string.widget_more, remaining),
            )
            views.setOnClickPendingIntent(
                R.id.widget_more,
                launchIntent(context, REQUEST_OPEN_APP, WidgetUris.openApp()),
            )
        } else {
            views.setViewVisibility(R.id.widget_more, View.GONE)
        }
    }

    private fun launchIntent(context: Context, requestCode: Int, uri: Uri): PendingIntent {
        val intent = Intent(context, MainActivity::class.java).apply {
            action = HomeWidgetLaunchIntent.HOME_WIDGET_LAUNCH_ACTION
            data = uri
        }
        return PendingIntent.getActivity(context, requestCode, intent, immutableFlags())
    }

    /**
     * The row template must stay *mutable*: each row completes it with its own
     * note id through `setOnClickFillInIntent`, which an immutable
     * PendingIntent silently refuses to merge.
     */
    private fun noteTemplate(context: Context): PendingIntent {
        val intent = Intent(context, MainActivity::class.java).apply {
            action = HomeWidgetLaunchIntent.HOME_WIDGET_LAUNCH_ACTION
        }
        var flags = PendingIntent.FLAG_UPDATE_CURRENT
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            flags = flags or PendingIntent.FLAG_MUTABLE
        }
        return PendingIntent.getActivity(context, REQUEST_NOTE_TEMPLATE, intent, flags)
    }

    private fun immutableFlags(): Int {
        var flags = PendingIntent.FLAG_UPDATE_CURRENT
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            flags = flags or PendingIntent.FLAG_IMMUTABLE
        }
        return flags
    }

    private companion object {
        // Distinct request codes keep FLAG_UPDATE_CURRENT from folding these
        // into one another.
        const val REQUEST_NEW_NOTE = 1
        const val REQUEST_OPEN_APP = 2
        const val REQUEST_NOTE_TEMPLATE = 3
        const val REQUEST_EMPTY_STATE = 4
    }
}
