package com.appsbay.onlynote

import android.app.Activity
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.ComponentName
import android.content.Intent
import android.content.res.Configuration
import android.os.Bundle
import android.view.View
import android.widget.ArrayAdapter
import android.widget.LinearLayout
import android.widget.ListView
import android.widget.TextView
import es.antonborri.home_widget.HomeWidgetPlugin

object WidgetSelection {
    private fun preferences(context: Context) =
        context.getSharedPreferences("onlynote_widget_configuration", Context.MODE_PRIVATE)
    fun read(context: Context, id: Int): String? = preferences(context).getString("widget_$id", null)
    fun save(context: Context, id: Int, noteId: String?): Boolean =
        preferences(context).edit().apply {
            if (noteId == null) remove("widget_$id") else putString("widget_$id", noteId)
        }.commit()
    fun remove(context: Context, ids: IntArray) {
        preferences(context).edit().apply { ids.forEach { remove("widget_$it") } }.apply()
    }
}

/** Configuration runs without booting Flutter or touching Hive. */
class WidgetConfigurationActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        val dark = resources.configuration.uiMode and Configuration.UI_MODE_NIGHT_MASK == Configuration.UI_MODE_NIGHT_YES
        setTheme(if (dark) android.R.style.Theme_Material_NoActionBar else android.R.style.Theme_Material_Light_NoActionBar)
        super.onCreate(savedInstanceState)
        val widgetId = intent.getIntExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, AppWidgetManager.INVALID_APPWIDGET_ID)
        setResult(RESULT_CANCELED, Intent().putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, widgetId))
        if (!ownsWidget(widgetId)) { finish(); return }

        val notes = WidgetCommandJournal.overlay(this, WidgetPayload.from(HomeWidgetPlugin.getData(this))).allNotes
        val container = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            val padding = (20 * resources.displayMetrics.density).toInt()
            setPadding(padding, padding, padding, padding)
        }
        container.addView(TextView(this).apply {
            text = getString(R.string.widget_choose_note)
            textSize = 24f
            setTypeface(typeface, android.graphics.Typeface.BOLD)
            setPadding(0, 0, 0, (12 * resources.displayMetrics.density).toInt())
            if (android.os.Build.VERSION.SDK_INT >= 28) setAccessibilityHeading(true)
        })
        container.addView(TextView(this).apply {
            text = getString(R.string.widget_selection_description)
            textSize = 16f
            setPadding(0, 0, 0, (16 * resources.displayMetrics.density).toInt())
        })
        val labels = listOf(getString(R.string.widget_all_notes)) + notes.map { it.displayTitle(this) }
        val list = ListView(this).apply {
            choiceMode = ListView.CHOICE_MODE_SINGLE
            adapter = ArrayAdapter(this@WidgetConfigurationActivity, android.R.layout.simple_list_item_single_choice, labels)
            val selected = WidgetSelection.read(this@WidgetConfigurationActivity, widgetId)
            val index = notes.indexOfFirst { it.id == selected }
            setItemChecked(if (index >= 0) index + 1 else 0, true)
            setOnItemClickListener { _, _: View, position, _ ->
                // The host can remove the widget while configuration is open.
                if (!ownsWidget(widgetId)) { finish(); return@setOnItemClickListener }
                val noteId = if (position == 0) null else notes.getOrNull(position - 1)?.id
                if (!WidgetSelection.save(this@WidgetConfigurationActivity, widgetId, noteId)) return@setOnItemClickListener
                NotesWidgetProvider.refresh(this@WidgetConfigurationActivity, intArrayOf(widgetId))
                setResult(RESULT_OK, Intent().putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, widgetId))
                finish()
            }
        }
        container.addView(list, LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, 0, 1f))
        setContentView(container)
    }

    private fun ownsWidget(widgetId: Int): Boolean = widgetId > 0 &&
        AppWidgetManager.getInstance(this).getAppWidgetInfo(widgetId)?.provider ==
            ComponentName(this, NotesWidgetProvider::class.java)
}
