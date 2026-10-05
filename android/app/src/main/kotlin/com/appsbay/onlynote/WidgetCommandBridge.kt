package com.appsbay.onlynote

import android.content.Context
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import org.json.JSONObject
import java.io.File
import java.util.UUID

/** Native widgets queue commands; only the foreground Dart engine writes Hive. */
object WidgetCommandBridge {
    private var channel: MethodChannel? = null
    fun notifyPending() {
        android.os.Handler(android.os.Looper.getMainLooper()).post {
            channel?.invokeMethod("commandsChanged", null)
        }
    }
    fun register(context: Context, messenger: BinaryMessenger) {
        val methodChannel = MethodChannel(messenger, "com.appsbay.onlynote/widget_commands")
        channel = methodChannel
        methodChannel.setMethodCallHandler { call, result ->
                try {
                    when (call.method) {
                        "readPending" -> result.success(WidgetCommandJournal.read(context).map {
                            mapOf(
                                "id" to it.getString("id"),
                                "noteId" to it.getString("noteId"),
                                "todoId" to it.getString("todoId"),
                                "completed" to it.getBoolean("completed"),
                                "createdAt" to it.getLong("createdAt"),
                            )
                        })
                        "acknowledge" -> {
                            (call.arguments as? List<*>)?.filterIsInstance<String>()?.forEach {
                                WidgetCommandJournal.acknowledge(context, it)
                            }
                            result.success(null)
                        }
                        else -> result.notImplemented()
                    }
                } catch (error: Exception) {
                    result.error("widget_commands", error.message, null)
                }
            }
    }
}

object WidgetCommandJournal {
    private fun directory(context: Context): File =
        File(context.filesDir, "widget_commands").apply { mkdirs() }

    @Synchronized
    fun enqueue(context: Context, noteId: String, todoId: String, completed: Boolean) {
        require(noteId.isNotEmpty() && todoId.isNotEmpty())
        val id = UUID.randomUUID().toString()
        val previousTime = read(context).maxOfOrNull { it.optLong("createdAt") } ?: 0
        val timestamp = maxOf(System.currentTimeMillis() * 1000, previousTime + 1)
        val record = JSONObject()
            .put("id", id)
            .put("noteId", noteId)
            .put("todoId", todoId)
            .put("completed", completed)
            .put("createdAt", timestamp)
        val root = directory(context)
        val temporary = File(root, "$id.tmp")
        temporary.outputStream().use { output ->
            output.write(record.toString().toByteArray(Charsets.UTF_8))
            output.flush()
            (output as java.io.FileOutputStream).fd.sync()
        }
        check(temporary.renameTo(File(root, "$id.json")))
        WidgetCommandBridge.notifyPending()
    }

    @Synchronized
    fun read(context: Context): List<JSONObject> =
        directory(context).listFiles().orEmpty()
            .filter { it.name.endsWith(".json") }
            .mapNotNull { file ->
                try { JSONObject(file.readText()).takeIf { valid(it) } } catch (_: Exception) { null }
            }
            .sortedWith(compareBy<JSONObject> { it.optLong("createdAt") }.thenBy { it.optString("id") })

    @Synchronized
    fun acknowledge(context: Context, id: String) {
        if (id.matches(Regex("[A-Za-z0-9-]{1,128}"))) {
            File(directory(context), "$id.json").delete()
        }
    }

    private fun valid(record: JSONObject): Boolean =
        record.optString("id").isNotEmpty() &&
            record.optString("noteId").isNotEmpty() &&
            record.optString("todoId").isNotEmpty() &&
            record.opt("completed") is Boolean && record.optLong("createdAt", -1) >= 0

    fun overlay(context: Context, payload: WidgetPayload): WidgetPayload {
        val commands = read(context)
        fun apply(note: WidgetNote): WidgetNote {
            var changed = note.todos
            for (command in commands.filter { it.optString("noteId") == note.id }) {
                changed = changed.map { todo ->
                    if (todo.id != null && todo.id == command.optString("todoId")) {
                        todo.copy(completed = command.optBoolean("completed"))
                    } else todo
                }
            }
            val delta = changed.count { it.completed } - note.todos.count { it.completed }
            return note.copy(todos = changed, todoDone = (note.todoDone + delta).coerceIn(0, note.todoTotal))
        }
        return payload.copy(notes = payload.notes.map(::apply), allNotes = payload.allNotes.map(::apply))
    }
}
