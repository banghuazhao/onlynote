import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:onlynote/Tools/onboarding_settings.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/presentation/routes/routes.dart';
import 'package:onlynote/services/shared_note_import.dart';

/// Drains the durable platform inbox after startup recovery and whenever the
/// user returns to Onlynote. iOS shares finish in their source app; Android
/// opens Onlynote after first retaining every granted content URI.
class SharedNoteLaunch with WidgetsBindingObserver {
  SharedNoteLaunch({MethodChannel? channel, bool? enabled})
      : _channel = channel ?? const MethodChannel(channelName),
        _enabled = enabled ??
            (!kIsWeb &&
                (defaultTargetPlatform == TargetPlatform.iOS ||
                    defaultTargetPlatform == TargetPlatform.android));

  static final instance = SharedNoteLaunch();
  static const channelName = 'com.appsbay.onlynote/shared_notes';
  final MethodChannel _channel;
  final bool _enabled;
  SharedNoteImport? _importer;
  StackRouter? _router;
  void Function()? _onFailure;
  void Function()? _onImported;
  final Map<String, Note> _loaded = {};
  bool _hasFailure = false;
  Future<void>? _recovery;
  final Set<String> _opened = {};
  bool _initialized = false;
  bool _draining = false;
  bool _requested = false;

  void configure(SharedNoteImport importer,
      {void Function()? onFailure, void Function()? onImported}) {
    _importer = importer;
    _onFailure = onFailure;
    _onImported = onImported;
  }

  Future<void> init() async {
    if (_initialized || !_enabled) return;
    _initialized = true;
    WidgetsBinding.instance.addObserver(this);
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'inboxChanged') refresh();
    });
    refresh();
  }

  void attach(StackRouter router,
      {void Function()? onFailure, void Function()? onImported}) {
    _router = router;
    if (onFailure != null) _onFailure = onFailure;
    if (onImported != null) _onImported = onImported;
    refresh();
  }

  void detach() => _router = null;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) refresh();
  }

  void refresh() {
    if (!_enabled) return;
    _requested = true;
    unawaited(_drain());
  }

  Future<void> _acknowledge(String id) =>
      _channel.invokeMethod<void>('acknowledge', {'id': id});

  /// Call before image pruning. Successful startup imports stay queued for
  /// presentation when the router attaches; failures retain both native files
  /// and any completed managed copies for the next foreground retry.
  Future<void> recoverInbox() {
    if (!_enabled || _importer == null) return Future.value();
    return _recovery ??= _recoverInbox().whenComplete(() => _recovery = null);
  }

  Future<void> _recoverInbox() async {
    try {
      for (final note in await _importer!.recover(
          acknowledge: _acknowledge,
          onFailure: (error) {
            _hasFailure = true;
            debugPrint('Shared note recovery deferred: $error');
          })) {
        _loaded[note.id!] = note;
      }
    } catch (error) {
      _hasFailure = true;
      debugPrint('Shared note recovery deferred: $error');
    }
    try {
      final entries = await _channel.invokeMethod<Object?>('pending');
      if (entries is! List) {
        throw const FormatException('Invalid share inbox');
      }
      for (final entry in entries) {
        try {
          final payload = SharedNotePayload.parse(entry);
          if (payload == null) {
            throw const FormatException('Invalid shared content');
          }
          final note =
              await _importer!.import(payload, acknowledge: _acknowledge);
          if (note != null) _loaded[note.id!] = note;
        } catch (error) {
          _hasFailure = true;
          debugPrint('Shared note import deferred: $error');
        }
      }
    } on MissingPluginException {
      // Previews and unsupported native hosts have no share inbox.
    } catch (error) {
      _hasFailure = true;
      debugPrint('Share inbox unavailable: $error');
    }
  }

  Future<void> _drain() async {
    if (_draining || _router == null || _importer == null) return;
    _draining = true;
    try {
      while (_requested && _router != null) {
        _requested = false;
        await recoverInbox();
        await WidgetsBinding.instance.endOfFrame;
        if (_router == null) return;
        if (_hasFailure) {
          _hasFailure = false;
          _onFailure?.call();
        }
        final imported = _loaded.values.toList();
        _loaded.clear();
        if (imported.isNotEmpty) _onImported?.call();
        // All entries are saved to the library. Open the most recent one so a
        // batch import does not create a stack of editors above an active draft.
        final unseen =
            imported.where((note) => !_opened.contains(note.id)).toList();
        if (unseen.isEmpty) continue;
        for (final note in imported) {
          _opened.add(note.id!);
        }
        final note = unseen.last;
        final router = _router!;
        final destination = AddUpdateNoteRoute(
          key: ValueKey('shared-note-${note.id}'),
          note: note,
        );
        if (!OnboardingSettings.instance.completed) {
          await OnboardingSettings.instance.complete();
          if (!identical(router, _router)) return;
          await router.replaceAll([const HomeRoute(), destination]);
        } else {
          if (router.hasPagelessTopRoute) {
            router.popUntil((route) => route.settings is Page);
          }
          unawaited(router.push<void>(destination));
        }
      }
    } catch (error) {
      debugPrint('Shared note editor deferred: $error');
      _onFailure?.call();
    } finally {
      _draining = false;
    }
  }

  @visibleForTesting
  void dispose() {
    detach();
    if (_initialized) WidgetsBinding.instance.removeObserver(this);
    _channel.setMethodCallHandler(null);
    _initialized = false;
  }
}
