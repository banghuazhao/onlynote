package com.appsbay.onlynote

import android.content.Context
import android.content.Intent
import android.view.View
import android.widget.RemoteViews
import android.widget.RemoteViewsService
import es.antonborri.home_widget.HomeWidgetPlugin

/** Backs the scrollable note list inside the home screen widget. */
class NotesWidgetService : RemoteViewsService() {
    override fun onGetViewFactory(intent: Intent): RemoteViewsFactory =
        NotesRemoteViewsFactory(applicationContext, intent.getIntExtra(
            android.appwidget.AppWidgetManager.EXTRA_APPWIDGET_ID, android.appwidget.AppWidgetManager.INVALID_APPWIDGET_ID))
}

private class NotesRemoteViewsFactory(
    private val context: Context,
    private val widgetId: Int,
) : RemoteViewsService.RemoteViewsFactory {

    private var notes: List<WidgetNote> = emptyList()
    private var selected: WidgetNote? = null
    private var selectedTodos: List<WidgetTodo> = emptyList()

    override fun onCreate() = Unit

    override fun onDataSetChanged() {
        val payload = WidgetCommandJournal.overlay(context, WidgetPayload.from(HomeWidgetPlugin.getData(context)))
        val selectedId = WidgetSelection.read(context, widgetId)
        selected = payload.allNotes.firstOrNull { it.id == selectedId }
        selectedTodos = selected?.takeIf { it.hasChecklist }?.todos ?: emptyList()
        notes = if (selectedId == null) payload.notes else listOfNotNull(selected?.takeIf { !it.hasChecklist })
    }

    override fun onDestroy() {
        notes = emptyList()
        selected = null
        selectedTodos = emptyList()
    }

    override fun getCount(): Int = if (selected?.hasChecklist == true) selectedTodos.size else notes.size

    override fun getViewAt(position: Int): RemoteViews {
        val checklist = selected?.takeIf { it.hasChecklist }
        if (checklist != null) return todoView(checklist, position)
        // onDataSetChanged and getViewAt run on different threads; the list can
        // shrink between the two, so never index blindly.
        val note = notes.getOrNull(position)
            ?: return RemoteViews(context.packageName, R.layout.notes_widget_row)

        val views = RemoteViews(context.packageName, R.layout.notes_widget_row)

        views.setTextViewText(R.id.widget_row_title, note.displayTitle(context))
        views.setViewVisibility(
            R.id.widget_row_pin,
            if (note.isPinned) View.VISIBLE else View.GONE,
        )

        val subtitle = note.subtitle(context)
        views.setTextViewText(R.id.widget_row_subtitle, subtitle)
        views.setViewVisibility(
            R.id.widget_row_subtitle,
            if (subtitle.isEmpty()) View.GONE else View.VISIBLE,
        )

        note.colorValue?.let { views.setInt(R.id.widget_row_stripe, "setColorFilter", it) }

        if (selected != null) {
            views.setTextViewText(R.id.widget_row_title, note.body.ifEmpty { note.displayTitle(context) })
            views.setInt(R.id.widget_row_title, "setMaxLines", 8)
            views.setViewVisibility(R.id.widget_row_subtitle, View.GONE)
        }
        bindBadge(views, note)

        views.setOnClickFillInIntent(
            R.id.widget_row,
            Intent().apply { data = WidgetUris.note(note.id) },
        )

        return views
    }

    private fun todoView(note: WidgetNote, position: Int): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.notes_widget_todo)
        val todo = selectedTodos.getOrNull(position) ?: return views
        views.setTextViewText(R.id.widget_todo_title, todo.title)
        views.setInt(R.id.widget_todo_title, "setPaintFlags",
            android.graphics.Paint.ANTI_ALIAS_FLAG or if (todo.completed) android.graphics.Paint.STRIKE_THRU_TEXT_FLAG else 0)
        views.setImageViewResource(R.id.widget_todo_check,
            if (todo.completed) R.drawable.ic_widget_check else R.drawable.ic_widget_circle)
        views.setContentDescription(R.id.widget_todo_row,
            "${todo.title}, ${context.getString(if (todo.completed) R.string.widget_completed else R.string.widget_not_completed)}")
        views.setBoolean(R.id.widget_todo_row, "setEnabled", todo.id != null)
        if (todo.id != null) {
            views.setOnClickFillInIntent(R.id.widget_todo_row, Intent().apply {
                putExtra("noteId", note.id)
                putExtra("todoId", todo.id)
                putExtra("completed", !todo.completed)
            })
        }
        return views
    }

    /**
     * Trailing indicator, mirroring which of the two the subtitle is already
     * describing: checklist progress first, then a photo count.
     */
    private fun bindBadge(views: RemoteViews, note: WidgetNote) {
        when {
            note.hasChecklist -> {
                views.setViewVisibility(R.id.widget_row_badge_icon, View.VISIBLE)
                views.setViewVisibility(R.id.widget_row_badge_text, View.VISIBLE)
                views.setImageViewResource(
                    R.id.widget_row_badge_icon,
                    if (note.todoDone == note.todoTotal) {
                        R.drawable.ic_widget_check
                    } else {
                        R.drawable.ic_widget_checklist
                    },
                )
                views.setTextViewText(
                    R.id.widget_row_badge_text,
                    "${note.todoDone}/${note.todoTotal}",
                )
            }

            note.imageCount > 0 -> {
                views.setViewVisibility(R.id.widget_row_badge_icon, View.VISIBLE)
                views.setImageViewResource(R.id.widget_row_badge_icon, R.drawable.ic_widget_photo)
                if (note.imageCount > 1) {
                    views.setViewVisibility(R.id.widget_row_badge_text, View.VISIBLE)
                    views.setTextViewText(R.id.widget_row_badge_text, "${note.imageCount}")
                } else {
                    views.setViewVisibility(R.id.widget_row_badge_text, View.GONE)
                }
            }

            else -> {
                views.setViewVisibility(R.id.widget_row_badge_icon, View.GONE)
                views.setViewVisibility(R.id.widget_row_badge_text, View.GONE)
            }
        }
    }

    override fun getLoadingView(): RemoteViews? = null

    override fun getViewTypeCount(): Int = 2

    override fun getItemId(position: Int): Long =
        (if (selected?.hasChecklist == true) selectedTodos.getOrNull(position)?.id else notes.getOrNull(position)?.id)
            ?.hashCode()?.toLong() ?: position.toLong()

    override fun hasStableIds(): Boolean = true
}
