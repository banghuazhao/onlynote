import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:onlynote/Tools/desktop_commands.dart';
import 'package:onlynote/Tools/onboarding_settings.dart';
import 'package:onlynote/common/constants.dart';
import 'package:onlynote/data/dto/note_dto.dart';
import 'package:onlynote/di/di.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/domain/repository/note_repository.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/routes/routes.dart';
import 'package:onlynote/services/note_autosave.dart';
import 'package:onlynote/services/premium_access.dart';
import 'package:onlynote/services/shortcuts_append.dart';

export 'package:onlynote/services/shortcuts_append.dart'
    show
        ShortcutAppendDestination,
        ShortcutAppendRequest,
        ShortcutAppendFailure;

/// App Intents retain text first, then open the app. Requests are applied only
/// after foreground storage recovery and a successful flush of active editors.
class ShortcutsAppendLaunch with WidgetsBindingObserver {
  ShortcutsAppendLaunch(
      {MethodChannel? channel,
      bool? enabled,
      ShortcutsAppendService? service,
      Stream<Object?>? noteChanges,
      Future<bool> Function()? prepareEditors,
      Iterable<Note> Function()? readNotes})
      : _channel = channel ?? const MethodChannel(channelName),
        _enabled = enabled ??
            (!kIsWeb &&
                (defaultTargetPlatform == TargetPlatform.iOS ||
                    defaultTargetPlatform == TargetPlatform.macOS)),
        _service = service,
        _changes = noteChanges,
        _prepareEditors = prepareEditors,
        _readNotes = readNotes;

  static final instance = ShortcutsAppendLaunch();
  static const channelName = 'com.appsbay.onlynote/shortcuts_append';
  final MethodChannel _channel;
  final bool _enabled;
  ShortcutsAppendService? _service;
  final Stream<Object?>? _changes;
  final Future<bool> Function()? _prepareEditors;
  final Iterable<Note> Function()? _readNotes;
  StackRouter? _router;
  VoidCallback? _onApplied;
  ValueChanged<ShortcutAppendFailure>? _onFailure;
  String Function(DateTime)? _titleForDay;
  String Function()? _inboxTitle;
  StreamSubscription<Object?>? _subscription;
  Timer? _catalogDebounce;
  bool _initialized = false;
  bool _draining = false;
  bool _requested = false;
  bool _disposed = false;
  int _generation = 0;

  final pending = ValueNotifier<List<ShortcutAppendRequest>>(const []);
  List<ShortcutAppendRequest> get pendingRequests => pending.value;

  void attach(StackRouter router,
      {VoidCallback? onApplied,
      ValueChanged<ShortcutAppendFailure>? onFailure,
      String Function(DateTime)? titleForDay,
      String Function()? inboxTitle}) {
    _disposed = false;
    _router = router;
    _onApplied = onApplied;
    _onFailure = onFailure;
    _titleForDay = titleForDay;
    _inboxTitle = inboxTitle;
    refresh();
  }

  void detach() {
    _generation++;
    _router = null;
    _onApplied = null;
    _onFailure = null;
  }

  Future<void> init() async {
    if (!_enabled || _initialized) return;
    _initialized = true;
    _disposed = false;
    if (_service == null) {
      final repository = getIt<NoteRepository>();
      final drafts = Hive.box(draftDatabaseBox);
      _service = ShortcutsAppendService(
          repository: repository,
          journal: HiveShortcutAppendJournal(drafts),
          store: HiveNoteAutosaveStore(repository, drafts),
          readDraft: (id) => (drafts.get(id) as NoteDto?)?.toDomain());
    }
    WidgetsBinding.instance.addObserver(this);
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'commandsChanged') refresh();
    });
    final stream = _changes ??
        (Hive.isBoxOpen(databaseBox) ? Hive.box(databaseBox).watch() : null);
    _subscription = stream?.listen((_) {
      _catalogDebounce?.cancel();
      _catalogDebounce = Timer(
          const Duration(milliseconds: 250), () => unawaited(syncCatalog()));
    });
    await syncCatalog();
    refresh();
  }

  Iterable<Note> _notes() =>
      _readNotes?.call() ??
      _service?.repository.getAllNotes().map((note) => note.toDomain()) ??
      const [];

  Future<void> syncCatalog() async {
    if (!_enabled || !_initialized || _disposed) return;
    try {
      final notes = _notes()
          .where((note) =>
              note.id?.isNotEmpty == true &&
              !note.isDeleted &&
              !note.isArchived)
          .toList()
        ..sort((a, b) => (b.dateTime ?? DateTime(1970))
            .compareTo(a.dateTime ?? DateTime(1970)));
      await _channel.invokeMethod<void>('saveCatalog', [
        for (final note in notes.take(10000))
          {
            'id': note.id!,
            'title': _withinLimit(
                note.title?.trim().isNotEmpty == true
                    ? note.title!.trim()
                    : S.current.Note_Untitled,
                500),
            if (note.dateTime != null)
              'modifiedAt': note.dateTime!.millisecondsSinceEpoch,
          }
      ]);
    } on MissingPluginException {
      // macOS 12/iOS 15 and preview hosts do not expose App Intents.
    } catch (error) {
      debugPrint('Shortcut note catalog deferred: $error');
    }
  }

  static String _withinLimit(String value, int max) {
    final output = StringBuffer();
    for (final character in value.characters) {
      if (output.length + character.length > max) break;
      output.write(character);
    }
    return output.toString();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) refresh();
  }

  void refresh() {
    if (!_enabled || _disposed) return;
    _requested = true;
    unawaited(_drain());
  }

  void retry() => refresh();

  bool get _active =>
      !_disposed &&
      _router != null &&
      WidgetsBinding.instance.lifecycleState != AppLifecycleState.paused &&
      WidgetsBinding.instance.lifecycleState != AppLifecycleState.inactive &&
      WidgetsBinding.instance.lifecycleState != AppLifecycleState.detached;

  Future<void> _acknowledge(String id) =>
      _channel.invokeMethod<void>('acknowledge', {'id': id});

  Future<void> discard(String id) async {
    final service = _service;
    if (service == null || _disposed) return;
    await service.discard(id, acknowledge: _acknowledge);
    if (!_disposed) {
      pending.value =
          pending.value.where((request) => request.id != id).toList();
    }
  }

  Future<void> _drain() async {
    if (_draining || !_initialized || !_active || _service == null) return;
    _draining = true;
    final generation = _generation;
    bool current() => _active && generation == _generation;
    try {
      while (_requested && current()) {
        _requested = false;
        final raw =
            await _channel.invokeListMethod<Object?>('pending') ?? const [];
        final requests = <String, ShortcutAppendRequest>{
          for (final request in _service!.retainedRequests) request.id: request,
        };
        for (final value in raw) {
          final request = ShortcutAppendRequest.parse(value);
          if (request == null) {
            throw const FormatException('Invalid shortcut request');
          }
          requests[request.id] = request;
        }
        final ordered = requests.values.toList()
          ..sort((a, b) {
            final byTime = a.createdAt.compareTo(b.createdAt);
            return byTime == 0 ? a.id.compareTo(b.id) : byTime;
          });
        if (!current()) return;
        pending.value = List.unmodifiable(ordered);
        if (ordered.isEmpty) continue;
        final ready = await (_prepareEditors?.call() ??
            DesktopCommands.instance.prepareForExternalWrite());
        if (!current()) return;
        if (!ready) {
          _onFailure?.call(ShortcutAppendFailure.saveBlocked);
          return;
        }
        if (!OnboardingSettings.instance.completed) {
          // Running a capture action explicitly chooses to use Onlynote. Keep
          // onboarding persistence before importing, matching share capture.
          await OnboardingSettings.instance.complete();
          if (!current()) return;
          await _router!.replaceAll([const HomeRoute()]);
          if (!current()) return;
        }
        var applied = false;
        ShortcutAppendFailure? failure;
        final blocked = <String>{};
        for (final request in ordered) {
          if (!current()) return;
          final inboxTitle =
              _inboxTitle?.call() ?? S.current.Shortcuts_Inbox_Title;
          final destination =
              _service!.destinationKey(request, inboxTitle: inboxTitle);
          if (blocked.contains(destination)) continue;
          void blockDestination() {
            blocked.add(destination);
            blocked
                .add(_service!.destinationKey(request, inboxTitle: inboxTitle));
          }

          try {
            final note = await _service!.apply(request,
                acknowledge: _acknowledge,
                titleForDay: _titleForDay ?? DateFormat.yMMMMd().format,
                inboxTitle: inboxTitle);
            applied = applied || note != null;
            if (current()) {
              pending.value = pending.value
                  .where((value) => value.id != request.id)
                  .toList();
            }
          } on PremiumRequired {
            blockDestination();
            failure ??= ShortcutAppendFailure.premiumRequired;
          } on ShortcutAppendException catch (error) {
            blockDestination();
            failure ??= error.failure;
          } catch (error) {
            blockDestination();
            debugPrint('Shortcut append retained for retry: $error');
            failure ??= ShortcutAppendFailure.failed;
          }
        }
        if (!current()) return;
        if (applied) {
          _onApplied?.call();
          await syncCatalog();
        }
        if (!current()) return;
        if (failure != null) _onFailure?.call(failure);
      }
    } on MissingPluginException {
      // Unsupported native hosts retain no platform request queue.
    } catch (error) {
      debugPrint('Shortcut inbox retained for retry: $error');
      if (current()) _onFailure?.call(ShortcutAppendFailure.failed);
    } finally {
      _draining = false;
      // A replacement app lifetime may have requested work while the old drain
      // was awaiting its editor flush. Its refresh must survive that stale exit.
      if (_requested && _initialized && _active) unawaited(_drain());
    }
  }

  @visibleForTesting
  Future<void> dispose() async {
    detach();
    _disposed = true;
    _catalogDebounce?.cancel();
    await _subscription?.cancel();
    _subscription = null;
    if (_initialized) WidgetsBinding.instance.removeObserver(this);
    _channel.setMethodCallHandler(null);
    _initialized = false;
  }
}
