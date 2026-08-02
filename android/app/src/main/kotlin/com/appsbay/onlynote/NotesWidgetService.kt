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
        NotesRemoteViewsFactory(applicationContext)
}

private class NotesRemoteViewsFactory(
    private val context: Context,
) : RemoteViewsService.RemoteViewsFactory {

    private var notes: List<WidgetNote> = emptyList()

    override fun onCreate() = Unit

    override fun onDataSetChanged() {
        notes = WidgetPayload.from(HomeWidgetPlugin.getData(context)).notes
    }

    override fun onDestroy() {
        notes = emptyList()
    }

    override fun getCount(): Int = notes.size

    override fun getViewAt(position: Int): RemoteViews {
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

        bindBadge(views, note)

        views.setOnClickFillInIntent(
            R.id.widget_row,
            Intent().apply { data = WidgetUris.note(note.id) },
        )

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

    override fun getViewTypeCount(): Int = 1

    override fun getItemId(position: Int): Long =
        notes.getOrNull(position)?.id?.hashCode()?.toLong() ?: position.toLong()

    override fun hasStableIds(): Boolean = true
}
