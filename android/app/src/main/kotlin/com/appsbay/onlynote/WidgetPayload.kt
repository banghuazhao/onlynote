package com.appsbay.onlynote

import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import org.json.JSONObject

/**
 * The snapshot the Flutter app writes via `home_widget`. Its Dart counterpart
 * is `lib/Tools/widget_sync.dart` — the two must agree on key names.
 *
 * Parsing is deliberately total: any malformed field degrades to a sensible
 * default rather than throwing, because an exception here leaves the user
 * staring at a blank widget with no way to diagnose it.
 */
data class WidgetPayload(
    val total: Int,
    val notes: List<WidgetNote>,
    val allNotes: List<WidgetNote> = notes,
) {
    companion object {
        const val KEY = "onlynote_widget_payload"

        val EMPTY = WidgetPayload(0, emptyList())

        fun from(prefs: SharedPreferences): WidgetPayload {
            val raw = prefs.getString(KEY, null) ?: return EMPTY
            return try {
                val json = JSONObject(raw)
                val array = json.optJSONArray("notes")
                val notes = buildList {
                    for (index in 0 until (array?.length() ?: 0)) {
                        array?.optJSONObject(index)?.let { add(WidgetNote.from(it)) }
                    }
                }
                val allArray = json.optJSONArray("allNotes")
                val all = if (allArray == null) notes else buildList {
                    for (index in 0 until allArray.length()) {
                        allArray.optJSONObject(index)?.let { add(WidgetNote.from(it)) }
                    }
                }
                WidgetPayload(json.optInt("total", notes.size), notes, all)
            } catch (_: Exception) {
                EMPTY
            }
        }
    }
}

data class WidgetNote(
    val id: String,
    val title: String,
    val body: String,
    val colorValue: Int?,
    val isPinned: Boolean,
    val imageCount: Int,
    val todoTotal: Int,
    val todoDone: Int,
    val todos: List<WidgetTodo>,
) {
    val hasChecklist: Boolean get() = todoTotal > 0

    /** Notes save fine with no title, so fall back before giving up. */
    fun displayTitle(context: Context): String = when {
        title.isNotEmpty() -> title
        body.isNotEmpty() -> body
        else -> context.getString(R.string.widget_untitled)
    }

    /**
     * The single line under the title. A checklist says more about a note than
     * its description does, so it wins when a note has both.
     */
    fun subtitle(context: Context): String {
        if (todoTotal > 0) {
            val next = todos.firstOrNull { !it.completed }
            return next?.title ?: context.getString(R.string.widget_all_done)
        }
        if (body.isNotEmpty()) return body
        if (title.isNotEmpty() && title != displayTitle(context)) return title
        return ""
    }

    companion object {
        fun from(json: JSONObject): WidgetNote {
            val todosArray = json.optJSONArray("todos")
            val todos = buildList {
                for (index in 0 until (todosArray?.length() ?: 0)) {
                    todosArray?.optJSONObject(index)?.let {
                        add(WidgetTodo(
                            it.optString("t", ""), it.optBoolean("c", false),
                            it.optString("id", "").takeIf { id -> id.isNotEmpty() },
                        ))
                    }
                }
            }

            return WidgetNote(
                id = json.optString("id", ""),
                title = json.optString("title", ""),
                body = json.optString("body", ""),
                // Flutter sends ARGB as an unsigned 32-bit value, which
                // overflows Int — read it wide, then let it wrap back into the
                // packed colour Android expects.
                colorValue = if (json.has("color")) json.optLong("color").toInt() else null,
                isPinned = json.optBoolean("pinned", false),
                imageCount = json.optInt("images", 0),
                todoTotal = json.optInt("todoTotal", 0),
                todoDone = json.optInt("todoDone", 0),
                todos = todos,
            )
        }
    }
}

data class WidgetTodo(
    val title: String,
    val completed: Boolean,
    val id: String? = null,
)

/**
 * Deep links into the app. The `homeWidget` query parameter is required by the
 * iOS half of the plugin; it's carried here too so both platforms speak one
 * URL format, which `lib/Tools/widget_launch.dart` parses.
 */
object WidgetUris {
    private const val SCHEME = "onlynote"

    fun note(id: String): Uri =
        Uri.parse("$SCHEME://note?id=${Uri.encode(id)}&homeWidget=true")

    fun newNote(): Uri = Uri.parse("$SCHEME://new?homeWidget=true")
    fun voiceNote(): Uri = Uri.parse("$SCHEME://voice?homeWidget=true")

    fun openApp(): Uri = Uri.parse("$SCHEME://open?homeWidget=true")
}
