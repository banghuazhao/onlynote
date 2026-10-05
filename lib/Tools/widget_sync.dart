import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:home_widget/home_widget.dart';
import 'package:onlynote/common/constants.dart';
import 'package:onlynote/Tools/widget_commands.dart';
import 'package:onlynote/data/dto/note_dto.dart';
import 'package:onlynote/di/di.dart';
import 'package:onlynote/domain/repository/note_repository.dart';

/// Mirrors a compact snapshot of the user's notes into the storage the home
/// screen widgets read from — an App Group container on iOS, SharedPreferences
/// on Android — and asks the OS to redraw them.
///
/// Widgets run in their own process and can't open the Hive box, so every note
/// mutation has to be pushed out here. Rather than calling this from each of
/// the dozen write sites (add, update, pin, trash, restore, reorder, folder
/// move, …), it listens to the Hive box itself — one hook that can't be
/// forgotten when a new mutation is added later.
class WidgetSync {
  WidgetSync._();

  static final WidgetSync instance = WidgetSync._();

  /// Must match the App Group enabled on both the Runner and the widget
  /// extension targets in Xcode.
  static const appGroupId = 'group.com.appsbay.onlynote';

  /// Must match the `kind` string of the WidgetKit widget.
  static const iOSWidgetName = 'OnlynoteWidget';

  /// Must match the AppWidgetProvider's fully qualified class name.
  static const androidWidgetName = 'com.appsbay.onlynote.NotesWidgetProvider';

  /// Key the native widgets read the JSON payload from.
  static const payloadKey = 'onlynote_widget_payload';

  /// The large widget renders six rows; the small headroom means a reorder
  /// among already-visible notes doesn't change what we send.
  static const _maxNotes = 8;

  static const _maxTitleChars = 60;
  static const _maxBodyChars = 120;
  static const _maxTodos = 100;

  StreamSubscription<BoxEvent>? _subscription;
  Timer? _debounce;

  /// Call once at startup, after Hive is open and DI is configured.
  Future<void> init() async {
    await HomeWidget.setAppGroupId(appGroupId);
    WidgetCommands.instance.syncWidgets = sync;
    await sync();

    _subscription ??= Hive.box(databaseBox).watch().listen((_) {
      // A reorder or multi-delete writes many keys back to back; coalesce them
      // so the timeline reloads once instead of once per note.
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 300), sync);
    });
  }

  /// Writes the current notes to shared storage and reloads the widgets.
  Future<void> sync() async {
    try {
      final payload = buildPayload(getIt<NoteRepository>().getAllNotes());

      await HomeWidget.saveWidgetData(payloadKey, jsonEncode(payload));
      await HomeWidget.updateWidget(
        iOSName: iOSWidgetName,
        qualifiedAndroidName: androidWidgetName,
      );
    } catch (error, stackTrace) {
      // The widget is an accessory to the app, never a precondition for it —
      // a sync failure must not surface as a failed note save.
      debugPrint('WidgetSync failed: $error\n$stackTrace');
    }
  }

  @visibleForTesting
  Future<void> dispose() async {
    _debounce?.cancel();
    _debounce = null;
    await _subscription?.cancel();
    _subscription = null;
  }

  @visibleForTesting
  static Map<String, dynamic> buildPayload(Iterable<NoteDto> source) {
    final notes = source.where((note) => !note.isDeleted).toList()..sort();
    return <String, dynamic>{
      'total': notes.length,
      'notes': notes.take(_maxNotes).map(_encodeNote).toList(),
      // Native configuration queries need every active note; display lists
      // still use the compact first-eight snapshot above.
      'allNotes': notes.map(_encodeNote).toList(),
    };
  }

  static Map<String, dynamic> _encodeNote(NoteDto note) {
    final todos = note.todoList ?? const <TodoDto>[];

    return <String, dynamic>{
      'id': note.id,
      'title': _clip(note.title, _maxTitleChars),
      'body': _clip(note.description, _maxBodyChars),
      if (note.colorValue != null) 'color': note.colorValue,
      'pinned': note.isPinned ?? false,
      'images': note.imagePaths?.length ?? 0,
      'todoTotal': todos.length,
      'todoDone': todos.where((todo) => todo.completed ?? false).length,
      'todos': todos
          .take(_maxTodos)
          .map((todo) => <String, dynamic>{
                if (todo.id?.isNotEmpty ?? false) 'id': todo.id,
                't': _clip(todo.title, _maxTitleChars),
                'c': todo.completed ?? false,
              })
          .toList(),
      if (note.dateTime != null) 'date': note.dateTime,
    };
  }

  /// Widget rows are single-line, so newlines are collapsed here rather than
  /// leaving the native side to deal with them.
  static String _clip(String? value, int maxChars) {
    final text = (value ?? '').replaceAll(RegExp(r'\s+'), ' ').trim();
    if (text.length <= maxChars) return text;
    return '${text.substring(0, maxChars).trimRight()}…';
  }
}
