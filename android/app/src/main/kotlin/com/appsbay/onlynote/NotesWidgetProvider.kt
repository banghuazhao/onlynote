package com.appsbay.onlynote

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.ComponentName
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
        val payload = WidgetCommandJournal.overlay(context, WidgetPayload.from(widgetData))

        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.notes_widget)
            val selectedId = WidgetSelection.read(context, widgetId)
            val selected = payload.allNotes.firstOrNull { it.id == selectedId }
            views.setTextViewText(R.id.widget_header_title,
                selected?.displayTitle(context) ?: if (selectedId != null) context.getString(R.string.widget_note_unavailable)
                else context.getString(R.string.app_name))
            val configure = Intent(context, WidgetConfigurationActivity::class.java).apply {
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, widgetId)
                data = Uri.parse("onlynote-widget://configure/$widgetId")
                flags = Intent.FLAG_ACTIVITY_NEW_TASK
            }
            views.setOnClickPendingIntent(R.id.widget_settings,
                PendingIntent.getActivity(context, widgetId, configure, immutableFlags()))
            views.setTextViewText(R.id.widget_empty,
                if (selectedId != null) context.getString(R.string.widget_choose_another_note)
                else context.getString(R.string.widget_empty_action))

            views.setOnClickPendingIntent(
                R.id.widget_new_note,
                launchIntent(context, REQUEST_NEW_NOTE, WidgetUris.newNote()),
            )
            views.setOnClickPendingIntent(
                R.id.widget_header_title,
                launchIntent(context, REQUEST_OPEN_APP + widgetId, selected?.let { WidgetUris.note(it.id) } ?: WidgetUris.openApp()),
            )

            bindList(context, views, widgetId, selected?.hasChecklist == true, selectedId != null)
            if (selectedId == null) bindOverflow(context, views, payload)
            else if (selected?.hasChecklist == true) {
                views.setViewVisibility(R.id.widget_more, View.VISIBLE)
                views.setTextViewText(R.id.widget_more, "${selected.todoDone}/${selected.todoTotal}")
                views.setOnClickPendingIntent(R.id.widget_more,
                    launchIntent(context, REQUEST_OPEN_APP + widgetId, WidgetUris.note(selected.id)))
            } else views.setViewVisibility(R.id.widget_more, View.GONE)

            appWidgetManager.updateAppWidget(widgetId, views)
            // The adapter caches its data; without this the list keeps showing
            // the previous notes after a save.
            appWidgetManager.notifyAppWidgetViewDataChanged(widgetId, R.id.widget_list)
        }
    }

    @Suppress("DEPRECATION")
    private fun bindList(context: Context, views: RemoteViews, widgetId: Int, checklist: Boolean, selected: Boolean) {
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
        views.setPendingIntentTemplate(R.id.widget_list, if (checklist) todoTemplate(context, widgetId) else noteTemplate(context))

        views.setOnClickPendingIntent(
            R.id.widget_empty,
            if (selected) PendingIntent.getActivity(context, widgetId,
                Intent(context, WidgetConfigurationActivity::class.java).putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, widgetId), immutableFlags())
            else launchIntent(context, REQUEST_EMPTY_STATE, WidgetUris.newNote()),
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

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == ACTION_COMPLETE) {
            val widgetId = intent.getIntExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, AppWidgetManager.INVALID_APPWIDGET_ID)
            val noteId = intent.getStringExtra("noteId") ?: return
            val todoId = intent.getStringExtra("todoId") ?: return
            if (!intent.hasExtra("completed") || WidgetSelection.read(context, widgetId) != noteId) return
            val payload = WidgetCommandJournal.overlay(context, WidgetPayload.from(
                es.antonborri.home_widget.HomeWidgetPlugin.getData(context)))
            val note = payload.allNotes.firstOrNull { it.id == noteId } ?: return
            if (note.todos.none { it.id == todoId }) return
            try {
                WidgetCommandJournal.enqueue(context, noteId, todoId, intent.getBooleanExtra("completed", false))
                refresh(context)
            } catch (_: Exception) {
                // Keep the existing checkbox state when a durable queue write fails.
            }
            return
        }
        super.onReceive(context, intent)
    }

    override fun onDeleted(context: Context, appWidgetIds: IntArray) {
        WidgetSelection.remove(context, appWidgetIds)
        super.onDeleted(context, appWidgetIds)
    }

    private fun todoTemplate(context: Context, widgetId: Int): PendingIntent {
        val intent = Intent(context, NotesWidgetProvider::class.java).apply {
            action = ACTION_COMPLETE
            data = Uri.parse("onlynote-widget://complete/$widgetId")
            putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, widgetId)
        }
        var flags = PendingIntent.FLAG_UPDATE_CURRENT
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) flags = flags or PendingIntent.FLAG_MUTABLE
        return PendingIntent.getBroadcast(context, widgetId, intent, flags)
    }

    private fun immutableFlags(): Int {
        var flags = PendingIntent.FLAG_UPDATE_CURRENT
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            flags = flags or PendingIntent.FLAG_IMMUTABLE
        }
        return flags
    }

    companion object {
        const val ACTION_COMPLETE = "com.appsbay.onlynote.COMPLETE_WIDGET_TODO"
        fun refresh(context: Context, ids: IntArray? = null) {
            val manager = AppWidgetManager.getInstance(context)
            val widgetIds = ids ?: manager.getAppWidgetIds(ComponentName(context, NotesWidgetProvider::class.java))
            if (widgetIds.isEmpty()) return
            NotesWidgetProvider().onUpdate(context, manager, widgetIds,
                es.antonborri.home_widget.HomeWidgetPlugin.getData(context))
        }
        // Distinct request codes keep FLAG_UPDATE_CURRENT from folding these
        // into one another.
        const val REQUEST_NEW_NOTE = 1
        const val REQUEST_OPEN_APP = 2
        const val REQUEST_NOTE_TEMPLATE = 3
        const val REQUEST_EMPTY_STATE = 4
    }
}
