import 'dart:async';
import 'dart:convert';

import 'package:characters/characters.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:home_widget/home_widget.dart';
import 'package:onlynote/common/constants.dart';
import 'package:onlynote/common/platform_capabilities.dart';
import 'package:onlynote/Tools/widget_commands.dart';
import 'package:onlynote/data/dto/note_dto.dart';
import 'package:onlynote/di/di.dart';
import 'package:onlynote/domain/repository/note_repository.dart';

abstract interface class WidgetSnapshotPlatform {
  Future<void> prepareStorage();
  Future<void> saveSnapshot(String payload);
  Future<void> refresh();
}

class MobileWidgetSnapshotPlatform implements WidgetSnapshotPlatform {
  const MobileWidgetSnapshotPlatform();

  @override
  Future<void> prepareStorage() async {
    await HomeWidget.setAppGroupId(WidgetSync.appGroupId);
  }

  @override
  Future<void> saveSnapshot(String payload) async {
    await HomeWidget.saveWidgetData(WidgetSync.payloadKey, payload);
  }

  @override
  Future<void> refresh() async {
    await HomeWidget.updateWidget(
      iOSName: WidgetSync.iOSWidgetName,
      qualifiedAndroidName: WidgetSync.androidWidgetName,
    );
  }
}

/// macOS uses its own WidgetKit bridge; the home_widget plugin is mobile-only.
class MacWidgetSnapshotPlatform implements WidgetSnapshotPlatform {
  const MacWidgetSnapshotPlatform({MethodChannel? channel})
      : _channel = channel ?? const MethodChannel(channelName);

  static const channelName = 'com.appsbay.onlynote/mac_widgets';
  final MethodChannel _channel;

  // Only the launch transport calls initialize, after it subscribes to taps.
  @override
  Future<void> prepareStorage() async {}

  @override
  Future<void> saveSnapshot(String payload) =>
      _channel.invokeMethod<void>('saveSnapshot', {'payload': payload});

  @override
  Future<void> refresh() => _channel.invokeMethod<void>('refresh');
}

/// Mirrors a compact snapshot of the user's notes into the storage the home
/// screen widgets read from — an App Group container on iOS/macOS,
/// SharedPreferences on Android — and asks the OS to redraw them.
///
/// Widgets run in their own process and can't open the Hive box, so every note
/// mutation has to be pushed out here. Rather than calling this from each of
/// the dozen write sites (add, update, pin, trash, restore, reorder, folder
/// move, …), it listens to the Hive box itself — one hook that can't be
/// forgotten when a new mutation is added later.
class WidgetSync {
  WidgetSync({
    WidgetSnapshotPlatform? platform,
    Iterable<NoteDto> Function()? readNotes,
    Stream<Object?> Function()? watchNotes,
    bool? enabled,
  })  : _platform = platform ??
            (defaultTargetPlatform == TargetPlatform.macOS
                ? const MacWidgetSnapshotPlatform()
                : const MobileWidgetSnapshotPlatform()),
        _readNotes = readNotes ??
            (() => getIt<NoteRepository>().getAllNotes()),
        _watchNotes = watchNotes ?? (() => Hive.box(databaseBox).watch()),
        _enabled = enabled ??
            (platform != null || PlatformCapabilities.homeWidgets);

  static final WidgetSync instance = WidgetSync();

  final WidgetSnapshotPlatform _platform;
  final Iterable<NoteDto> Function() _readNotes;
  final Stream<Object?> Function() _watchNotes;
  final bool _enabled;

  /// Mobile App Group. The Mac bridge owns its team-prefixed App Group.
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
  static const _maxMacBodyChars = 800;
  static const _maxTodos = 100;

  StreamSubscription<Object?>? _subscription;
  Timer? _debounce;

  /// Call once at startup, after Hive is open and DI is configured.
  Future<void> init() async {
    if (!_enabled) return;
    WidgetCommands.initializedInstance?.syncWidgets = sync;
    _subscription ??= _watchNotes().listen((_) {
      // A reorder or multi-delete writes many keys back to back; coalesce them
      // so the timeline reloads once instead of once per note.
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 300), sync);
    });
    try {
      await _platform.prepareStorage();
    } catch (error) {
      debugPrint('Widget storage unavailable: $error');
    }
    await sync();
  }

  /// Writes the current notes to shared storage and reloads the widgets.
  Future<void> sync() async {
    if (!_enabled) return;
    try {
      final payload = buildPayload(_readNotes(),
          desktop: defaultTargetPlatform == TargetPlatform.macOS);
      await _platform.saveSnapshot(jsonEncode(payload));
      await _platform.refresh();
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
  static Map<String, dynamic> buildPayload(Iterable<NoteDto> source,
      {bool desktop = false}) {
    final notes = source
        .where((note) => !note.isDeleted && !note.isArchived)
        .toList()
      ..sort();
    return <String, dynamic>{
      'total': notes.length,
      'notes': notes
          .take(_maxNotes)
          .map((note) => _encodeNote(note, desktop: desktop))
          .toList(),
      // Native configuration queries need every active note; display lists
      // still use the compact first-eight snapshot above.
      'allNotes':
          notes.map((note) => _encodeNote(note, desktop: desktop)).toList(),
    };
  }

  static Map<String, dynamic> _encodeNote(NoteDto note, {bool desktop = false}) {
    final todos = note.todoList ?? const <TodoDto>[];

    return <String, dynamic>{
      'id': note.id,
      'title': desktop
          ? _clipMacSummary(note.title, _maxTitleChars)
          : _clip(note.title, _maxTitleChars),
      'body': desktop
          ? _clipMacBody(note.description)
          : _clip(note.description, _maxBodyChars),
      if (note.colorValue != null) 'color': note.colorValue,
      'pinned': note.isPinned ?? false,
      'images': note.imagePaths?.length ?? 0,
      'todoTotal': todos.length,
      'todoDone': todos.where((todo) => todo.completed ?? false).length,
      'todos': todos
          .take(_maxTodos)
          .map((todo) => <String, dynamic>{
                if (todo.id?.isNotEmpty ?? false) 'id': todo.id,
                't': desktop
                    ? _clipMacSummary(todo.title, _maxTitleChars)
                    : _clip(todo.title, _maxTitleChars),
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

  /// Paper widgets retain the note's paragraphs and complete Unicode clusters.
  static String _clipMacBody(String? value) {
    return _clipGraphemes(value ?? '', _maxMacBodyChars);
  }

  static String _clipMacSummary(String? value, int maxChars) {
    final text = (value ?? '').replaceAll(RegExp(r'\s+'), ' ').trim();
    return _clipGraphemes(text, maxChars, trimEnd: true);
  }

  static String _clipGraphemes(String text, int maxChars,
      {bool trimEnd = false}) {
    final excerpt = text.characters.take(maxChars).toString();
    if (excerpt.length == text.length) return text;
    return '${trimEnd ? excerpt.trimRight() : excerpt}…';
  }
}
