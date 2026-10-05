import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:onlynote/Tools/onboarding_settings.dart';
import 'package:onlynote/presentation/routes/routes.dart';
import 'package:onlynote/presentation/screens/add_update_note/add_update_note_screen.dart';

enum AppCaptureShortcut {
  note('new_note', NoteEditorStart.quickNote),
  checklist('new_checklist', NoteEditorStart.checklist),
  photo('photo_note', NoteEditorStart.photo);

  const AppCaptureShortcut(this.nativeType, this.editorStart);
  final String nativeType;
  final NoteEditorStart editorStart;

  static AppCaptureShortcut? parse(Object? value) {
    for (final shortcut in values) {
      if (shortcut.nativeType == value) return shortcut;
    }
    return null;
  }
}

/// Delivers native icon actions only after storage recovery and routing setup.
class AppShortcutLaunch {
  AppShortcutLaunch({MethodChannel? channel, bool? enabled})
      : _channel = channel ?? const MethodChannel(channelName),
        _enabled = enabled ??
            (!kIsWeb &&
                (defaultTargetPlatform == TargetPlatform.iOS ||
                    defaultTargetPlatform == TargetPlatform.android));

  static final instance = AppShortcutLaunch();
  static const channelName = 'com.appsbay.onlynote/app_shortcuts';

  final MethodChannel _channel;
  final bool _enabled;
  final Set<String> _seen = {};
  StackRouter? _router;
  ({String id, AppCaptureShortcut action})? _pending;
  bool _initialized = false;
  bool _draining = false;

  Future<void> init() async {
    if (_initialized || !_enabled) return;
    _initialized = true;
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'shortcutTapped') handle(call.arguments);
    });
    try {
      handle(await _channel.invokeMethod<Object?>('initialize'));
    } on MissingPluginException {
      // Desktop, previews, and older native hosts have no icon action bridge.
    } catch (error) {
      debugPrint('App shortcut initialization failed: $error');
    }
  }

  void attach(StackRouter router) {
    _router = router;
    unawaited(_drain());
  }

  void detach() => _router = null;

  @visibleForTesting
  void handle(Object? payload) {
    if (payload is! Map) return;
    final id = payload['id'];
    final action = AppCaptureShortcut.parse(payload['type']);
    if (id is! String || id.isEmpty || action == null || _seen.contains(id)) {
      return;
    }
    _seen.add(id);
    if (_seen.length > 64) _seen.remove(_seen.first);
    // A later explicit action replaces an earlier one during startup.
    _pending = (id: id, action: action);
    unawaited(_drain());
  }

  Future<void> _drain() async {
    if (_draining || _router == null) return;
    _draining = true;
    try {
      while (_pending != null && _router != null) {
        // Resuming a background app can briefly leave its Navigator detached.
        await WidgetsBinding.instance.endOfFrame;
        final router = _router;
        if (router == null) return;
        final request = _pending!;
        _pending = null;
        final destination = AddUpdateNoteRoute(
          key: ValueKey('app-shortcut-${request.id}'),
          start: request.action.editorStart,
        );
        if (!OnboardingSettings.instance.completed) {
          // Selecting a capture shortcut is an explicit first-use action.
          await OnboardingSettings.instance.complete();
          if (!identical(router, _router)) return;
          await router.replaceAll([const HomeRoute(), destination]);
        } else {
          if (router.hasPagelessTopRoute) {
            router.popUntil((route) => route.settings is Page);
          }
          // Push above any editor so its draft and save/retry state stay alive.
          // push resolves only on Back and must not block later native taps.
          unawaited(router.push<void>(destination));
        }
      }
    } catch (error) {
      debugPrint('App shortcut could not open its editor: $error');
    } finally {
      _draining = false;
    }
  }

  @visibleForTesting
  void dispose() {
    detach();
    _channel.setMethodCallHandler(null);
    _initialized = false;
  }
}
