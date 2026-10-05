import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:onlynote/Tools/onboarding_settings.dart';
import 'package:onlynote/Tools/reminder.dart';
import 'package:onlynote/Tools/reminder_notification_payload.dart';
import 'package:onlynote/domain/repository/note_repository.dart';
import 'package:onlynote/presentation/routes/routes.dart';

/// Keeps notification taps until storage recovery and the app router are ready.
class ReminderLaunch {
  static final instance = ReminderLaunch();

  StackRouter? _router;
  NoteRepository? _notes;
  List<Reminder> Function()? _reminders;
  NotificationResponse? _pending;
  bool _draining = false;

  void attach({
    required StackRouter router,
    required NoteRepository notes,
    required List<Reminder> Function() reminders,
  }) {
    _router = router;
    _notes = notes;
    _reminders = reminders;
    unawaited(_drain());
  }

  void detach() {
    _router = null;
    _notes = null;
    _reminders = null;
  }

  void handleNotificationResponse(NotificationResponse response) {
    if (response.notificationResponseType !=
        NotificationResponseType.selectedNotification) {
      return;
    }
    // A newer tap takes precedence while the app is still starting up.
    _pending = response;
    unawaited(_drain());
  }

  String? _noteId(NotificationResponse response) {
    final noteId = ReminderNotificationPayload.noteIdFrom(response.payload);
    if (noteId != null) return noteId;

    // Notifications scheduled before note payloads were added still have
    // their notification ID and locally stored reminder metadata.
    final id = response.id;
    if (id == null) return null;
    for (final reminder in _reminders!()) {
      if (reminder.reminderId == id) return reminder.noteId;
    }
    return null;
  }

  Future<void> _drain() async {
    if (_draining || _router == null) return;
    _draining = true;
    try {
      while (_pending != null && _router != null) {
        final response = _pending!;
        _pending = null;

        // A resumed app's Navigator may not be attached when the native tap
        // arrives. endOfFrame also requests a frame when the app is idle.
        await WidgetsBinding.instance.endOfFrame;
        final router = _router;
        final notes = _notes;
        if (router == null || notes == null) return;

        final noteId = _noteId(response);
        if (noteId == null || noteId.isEmpty) continue;
        try {
          final note = await notes.getNote(noteId);
          if (note.isDeleted || !identical(router, _router)) continue;
          if (router.hasPagelessTopRoute) {
            // Reveal the destination when a sheet, dialog or Settings screen
            // was left open before the user selected the notification.
            router.popUntil((route) => route.settings is Page);
          }
          final current = router.current;
          final args = current.args;
          if (current.name == AddUpdateNoteRoute.name &&
              args is AddUpdateNoteRouteArgs &&
              args.note?.id == noteId) {
            // This note is already open for editing. Keep its in-progress
            // text visible rather than racing the editor's final autosave.
            continue;
          }
          if (current.name == NoteDetailRoute.name &&
              args is NoteDetailRouteArgs &&
              args.noteId == noteId) {
            continue;
          }

          final destination = NoteDetailRoute(
            key: ValueKey(noteId),
            noteId: noteId,
          );
          if (!OnboardingSettings.instance.completed) {
            // A reminder to an existing note is already a useful first entry.
            await OnboardingSettings.instance.complete();
            if (!identical(router, _router)) return;
            await router.replaceAll([const HomeRoute(), destination]);
          } else if (current.name == AddUpdateNoteRoute.name) {
            // Preserve the editor and its save/retry state. Back from the
            // reminder returns to the draft, and finishing that edit refreshes
            // its original detail screen. push completes only when popped,
            // so it must not block delivery of later notification taps.
            unawaited(router.push<void>(destination));
          } else {
            // Reuse the detail route's place in the stack. The note-specific
            // widget key reloads a different note without stacking screens
            // that would otherwise share the same NoteDetailBloc.
            await router.navigate(destination);
          }
        } catch (error) {
          // A delivered notification can outlive its note or a backup restore.
          debugPrint('Reminder note could not be opened: $error');
        }
      }
    } finally {
      _draining = false;
    }
  }
}
