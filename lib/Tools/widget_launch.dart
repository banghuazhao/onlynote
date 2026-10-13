import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:home_widget/home_widget.dart';
import 'package:onlynote/Tools/onboarding_settings.dart';
import 'package:onlynote/common/platform_capabilities.dart';
import 'package:onlynote/di/di.dart';
import 'package:onlynote/domain/repository/note_repository.dart';
import 'package:onlynote/presentation/routes/routes.dart';
import 'package:onlynote/presentation/screens/add_update_note/add_update_note_screen.dart';

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
  WidgetLaunch._();

  static final WidgetLaunch instance = WidgetLaunch._();

  static const scheme = 'onlynote';
  static const hostNote = 'note';
  static const hostNew = 'new';
  static const hostVoice = 'voice';

  StreamSubscription<Uri?>? _subscription;

  /// Call once after the router exists. Handles both a cold launch from the
  /// widget and taps that arrive while the app is already running.
  Future<void> init() async {
    if (!PlatformCapabilities.homeWidgets) return;
    _subscription ??= HomeWidget.widgetClicked.listen(_handle);

    try {
      _handle(await HomeWidget.initiallyLaunchedFromHomeWidget());
    } catch (error) {
      debugPrint('WidgetLaunch initial URI failed: $error');
    }
  }

  void _handle(Uri? uri) {
    if (uri == null || uri.scheme != scheme) return;

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
  }
}
