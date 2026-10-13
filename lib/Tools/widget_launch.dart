import 'dart:async';
import 'dart:ui' show AppExitResponse;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'package:home_widget/home_widget.dart';
import 'package:onlynote/Tools/onboarding_settings.dart';
import 'package:onlynote/Tools/desktop_commands.dart';
import 'package:onlynote/common/platform_capabilities.dart';
import 'package:onlynote/di/di.dart';
import 'package:onlynote/domain/repository/note_repository.dart';
import 'package:onlynote/presentation/routes/routes.dart';
import 'package:onlynote/presentation/screens/add_update_note/add_update_note_screen.dart';

abstract interface class WidgetLaunchPlatform {
  Stream<Uri?> get taps;
  Future<Uri?> initialUri();
  Future<void> dispose();
}

class MobileWidgetLaunchPlatform implements WidgetLaunchPlatform {
  const MobileWidgetLaunchPlatform();

  @override
  Stream<Uri?> get taps => HomeWidget.widgetClicked;

  @override
  Future<Uri?> initialUri() => HomeWidget.initiallyLaunchedFromHomeWidget();

  @override
  Future<void> dispose() async {}
}

class MacWidgetLaunchPlatform implements WidgetLaunchPlatform {
  MacWidgetLaunchPlatform({MethodChannel? channel})
      : _channel = channel ?? const MethodChannel(channelName);

  static const channelName = 'com.appsbay.onlynote/mac_widgets';
  final MethodChannel _channel;
  StreamController<Uri?>? _events;

  static Uri? _decode(Object? value) =>
      value is String ? Uri.tryParse(value) : null;

  @override
  Stream<Uri?> get taps {
    final events = _events ??= StreamController<Uri?>.broadcast();
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'widgetTapped' && !events.isClosed) {
        events.add(_decode(call.arguments));
      }
    });
    return events.stream;
  }

  @override
  Future<Uri?> initialUri() async =>
      _decode(await _channel.invokeMethod<Object?>('initialize'));

  @override
  Future<void> dispose() async {
    _channel.setMethodCallHandler(null);
    final events = _events;
    _events = null;
    await events?.close();
  }
}

/// Routes taps on the home screen widget into the app.
///
/// The widgets open URLs of the form:
///
///   `onlynote://note?id=<noteId>&homeWidget=true` — open an existing note
///   `onlynote://new?homeWidget=true`               — start a blank note
///
/// The `homeWidget` query parameter is not decoration: the iOS side of
/// `home_widget` only claims a URL as its own when that key is present, and
/// silently ignores it otherwise.
class WidgetLaunch {
  WidgetLaunch({
    WidgetLaunchPlatform? platform,
    DesktopCommands? desktopCommands,
    void Function(Uri)? onTap,
    bool? enabled,
  })  : _platform = platform ??
            (defaultTargetPlatform == TargetPlatform.macOS
                ? MacWidgetLaunchPlatform()
                : const MobileWidgetLaunchPlatform()),
        _onTap = onTap,
        _desktopCommands = desktopCommands ?? DesktopCommands.instance,
        _enabled = enabled ??
            (platform != null || PlatformCapabilities.homeWidgets);

  static final WidgetLaunch instance = WidgetLaunch();

  final WidgetLaunchPlatform _platform;
  final void Function(Uri)? _onTap;
  final DesktopCommands _desktopCommands;
  final bool _enabled;

  static const scheme = 'onlynote';
  static const hostNote = 'note';
  static const hostNew = 'new';
  static const hostVoice = 'voice';
  static const hostOpen = 'open';

  StreamSubscription<Uri?>? _subscription;
  bool _initialized = false;
  bool _openingLibrary = false;

  /// Call once after the router exists. Handles both a cold launch from the
  /// widget and taps that arrive while the app is already running.
  Future<void> init() async {
    if (!_enabled || _initialized) return;
    _initialized = true;
    _subscription = _platform.taps.listen(_handle, onError: (Object error) {
      debugPrint('WidgetLaunch tap delivery failed: $error');
    });

    try {
      _handle(await _platform.initialUri());
    } catch (error) {
      debugPrint('WidgetLaunch initial URI failed: $error');
    }
  }

  void _handle(Uri? uri) {
    if (uri == null ||
        uri.scheme != scheme ||
        !const {hostNote, hostNew, hostVoice, hostOpen}.contains(uri.host) ||
        uri.queryParameters['homeWidget'] != 'true') {
      return;
    }
    if (_onTap != null) {
      _onTap(uri);
      return;
    }

    // Onboarding owns the whole screen; pushing a note on top of it would
    // strand the user halfway through setup.
    if (!OnboardingSettings.instance.completed) return;

    // When the app is resumed by a widget tap rather than launched by one,
    // this fires within milliseconds of the activity coming back — before the
    // router's navigator has re-attached, and a push made in that window is
    // accepted and then silently dropped. Waiting for the next frame is what
    // makes the warm path behave like the cold one.
    WidgetsBinding.instance.addPostFrameCallback((_) => _navigate(uri));
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  void _navigate(Uri uri) {
    if (uri.host == hostOpen) {
      if (defaultTargetPlatform == TargetPlatform.macOS) {
        unawaited(_openLibrary());
      }
      return;
    }
    final router = getIt<AppRouter>();

    switch (uri.host) {
      case hostNew:
        router.push(AddUpdateNoteRoute());
      case hostVoice:
        router.push(AddUpdateNoteRoute(start: NoteEditorStart.voice));
      case hostNote:
        final noteId = uri.queryParameters['id'];
        if (noteId == null || noteId.isEmpty) {
          // Nothing to open — the app itself is still a reasonable landing
          // spot, which is what happens if we just fall through.
          return;
        }
        _openNote(router, noteId);
    }
  }

  Future<void> _openLibrary() async {
    if (_openingLibrary) return;
    _openingLibrary = true;
    try {
      // Select the existing library after saving, instead of covering a draft.
      final response = await _desktopCommands.prepareToExit();
      if (response == AppExitResponse.cancel) return;
      await getIt<AppRouter>().navigate(const HomeRoute());
    } catch (error) {
      debugPrint('WidgetLaunch library navigation failed: $error');
    } finally {
      _openingLibrary = false;
    }
  }

  /// The widget's snapshot can outlive the note it points at — the user may
  /// have deleted it since the last timeline refresh. Opening the detail
  /// screen for a missing id would strand them on an error, so check first.
  Future<void> _openNote(AppRouter router, String noteId) async {
    try {
      await getIt<NoteRepository>().getNote(noteId);
    } catch (_) {
      return;
    }
    await router.push(NoteDetailRoute(noteId: noteId));
  }

  @visibleForTesting
  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
    _initialized = false;
    await _platform.dispose();
  }
}
