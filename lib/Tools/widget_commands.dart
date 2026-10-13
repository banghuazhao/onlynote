import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:onlynote/common/platform_capabilities.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:onlynote/data/dto/note_dto.dart';
import 'package:onlynote/di/di.dart';
import 'package:onlynote/domain/repository/note_repository.dart';
import 'package:onlynote/services/note_autosave.dart';

/// An explicit state change, rather than a toggle: replaying a native journal
/// after an interrupted acknowledgement cannot undo the user's action.
class WidgetTodoCommand {
  const WidgetTodoCommand({
    required this.id,
    required this.noteId,
    required this.todoId,
    required this.completed,
    required this.createdAt,
  });

  final String id;
  final String noteId;
  final String todoId;
  final bool completed;
  final int createdAt;

  static WidgetTodoCommand? decode(Object? value) {
    if (value is! Map) return null;
    final id = value['id'];
    final noteId = value['noteId'];
    final todoId = value['todoId'];
    final completed = value['completed'];
    final createdAt = value['createdAt'];
    bool validId(Object? id) =>
        id is String && id.isNotEmpty && id.length <= 256;
    if (!validId(id) ||
        !validId(noteId) ||
        !validId(todoId) ||
        completed is! bool ||
        createdAt is! int ||
        createdAt < 0) {
      return null;
    }
    return WidgetTodoCommand(
      id: id as String,
      noteId: noteId as String,
      todoId: todoId as String,
      completed: completed,
      createdAt: createdAt,
    );
  }
}

typedef WidgetEditorApply = Future<bool> Function(WidgetTodoCommand command);

/// Imports the native widgets' atomic command files using the foreground
/// engine's existing Hive boxes. The widget never opens the database itself.
class WidgetCommands {
  WidgetCommands({
    required this.repository,
    required this.readPending,
    required this.acknowledge,
    required this.readDraft,
    required this.writeDraft,
    required this.removeDraft,
    required this.syncWidgets,
    this.enabled = true,
  });

  static const channel = MethodChannel('com.appsbay.onlynote/widget_commands');
  static WidgetCommands? _instance;
  static WidgetCommands? get initializedInstance => _instance;
  static WidgetCommands get instance => _instance ??= WidgetCommands(
        enabled: PlatformCapabilities.homeWidgets,
        repository: getIt<NoteRepository>(),
        readPending: () async =>
            await channel.invokeListMethod<Object?>('readPending') ?? [],
        acknowledge: (ids) => channel.invokeMethod<void>('acknowledge', ids),
        readDraft: (id) => Hive.box(draftDatabaseBox).get(id) as NoteDto?,
        writeDraft: (note) async {
          final drafts = Hive.box(draftDatabaseBox);
          await drafts.put(note.id, note);
          await drafts.flush();
        },
        removeDraft: (id) async {
          final drafts = Hive.box(draftDatabaseBox);
          await drafts.delete(id);
          await drafts.flush();
        },
        syncWidgets: () async {},
      );

  final NoteRepository repository;
  final bool enabled;
  final Future<List<Object?>> Function() readPending;
  final Future<void> Function(List<String>) acknowledge;
  final NoteDto? Function(String) readDraft;
  final Future<void> Function(NoteDto) writeDraft;
  final Future<void> Function(String) removeDraft;
  Future<void> Function() syncWidgets;
  final updates = ValueNotifier<WidgetTodoCommand?>(null);
  final Map<String, List<WidgetEditorApply>> _editors = {};
  Future<void>? _inFlight;
  bool _importRequested = false;

  /// Editors merge into their own current text/photo draft and flush through
  /// their autosave queue. This keeps a widget action from overwriting typing.
  VoidCallback registerEditor(String noteId, WidgetEditorApply applyAndFlush) {
    (_editors[noteId] ??= []).add(applyAndFlush);
    return () {
      final handlers = _editors[noteId];
      handlers?.remove(applyAndFlush);
      if (handlers?.isEmpty ?? false) _editors.remove(noteId);
    };
  }

  /// Register after storage is ready. Native delivery is supplemented by an
  /// explicit startup/resume import because the main engine may be suspended.
  Future<void> init() async {
    if (!enabled) return;
    channel.setMethodCallHandler((call) async {
      if (call.method == 'commandsChanged') await importPending();
    });
    await importPending();
  }

  Future<void> importPending() {
    if (!enabled) return Future.value();
    _importRequested = true;
    final existing = _inFlight;
    if (existing != null) return existing;
    final completion = Completer<void>();
    _inFlight = completion.future;
    unawaited(_drainRequests(completion));
    return completion.future;
  }

  Future<void> _drainRequests(Completer<void> completion) async {
    try {
      while (_importRequested) {
        _importRequested = false;
        await _drain();
      }
    } finally {
      // Clear synchronously with the final request check; using whenComplete
      // creates a microtask gap in which a fresh event can otherwise be lost.
      _inFlight = null;
      completion.complete();
    }
  }

  Future<void> _drain() async {
    try {
      final values = await readPending();
      final commands = values
          .map(WidgetTodoCommand.decode)
          .whereType<WidgetTodoCommand>()
          .toList()
        ..sort((a, b) {
          final time = a.createdAt.compareTo(b.createdAt);
          return time == 0 ? a.id.compareTo(b.id) : time;
        });
      final seen = <String>{};
      for (final command in commands) {
        if (!seen.add(command.id)) continue;
        // A failed command must precede newer states for the same item, or a
        // later import could regress the checklist to an older action.
        if (!await _apply(command)) break;
        await acknowledge([command.id]);
      }
      await syncWidgets();
    } on MissingPluginException {
      // Desktop/web have no native widget bridge.
    } catch (error, stack) {
      debugPrint('Widget command import deferred: $error\n$stack');
    }
  }

  Future<bool> _apply(WidgetTodoCommand command) async {
    final notes = repository.getAllNotes();
    final matches = notes.where((note) => note.id == command.noteId);
    if (matches.isEmpty) return true; // Never recreate a removed note.
    final saved = matches.first;
    if (saved.isDeleted) return true;
    final handlers = _editors[command.noteId];
    if (handlers != null && handlers.isNotEmpty) {
      if (!await handlers.last(command)) return false;
      updates.value = command;
      return true;
    }
    final draft = readDraft(command.noteId);
    final current = draft?.id == saved.id ? draft! : saved;
    if (current.isDeleted) return true;
    final todos = current.todoList ?? [];
    final index = todos.indexWhere((todo) => todo.id == command.todoId);
    if (index < 0) return true; // Deleted/legacy items stay untouched.
    final old = todos[index];
    if (old.completed == command.completed) {
      // A previous import may have saved successfully but crashed before ack.
      if (draft != null) {
        await repository.addUpdateNote(current);
        await removeDraft(command.noteId);
      }
      updates.value = command;
      return true;
    }
    final changed = List<TodoDto>.of(todos);
    changed[index] = TodoDto(
      id: old.id,
      title: old.title,
      completed: command.completed,
    );
    final updated = current.copyWith(todoList: changed);
    await writeDraft(updated);
    await repository.addUpdateNote(updated);
    await removeDraft(command.noteId);
    updates.value = command;
    return true;
  }
}
