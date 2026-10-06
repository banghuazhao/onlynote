import 'package:onlynote/services/note_templates.dart';
import 'package:onlynote/services/note_autosave.dart';
import 'package:onlynote/services/custom_note_template_store.dart';
import 'package:onlynote/services/reminder_agenda_controller.dart';
import 'package:onlynote/services/note_photo_capture.dart';
import 'package:onlynote/services/photo_text_extraction.dart';
import 'package:onlynote/services/voice_memo_drafts.dart';
import 'package:onlynote/services/voice_memo_service.dart';
import 'package:onlynote/services/note_reminder_scheduler.dart';
import 'package:onlynote/Tools/widget_commands.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/presentation/screens/screens.dart';

export 'package:auto_route/auto_route.dart';

part 'routes.gr.dart';

@AutoRouterConfig(replaceInRouteName: 'Screen,Route')
class AppRouter extends RootStackRouter {
  // Adaptive gives each platform its native transition — Cupertino on
  // iOS/macOS (which includes the edge-swipe-to-go-back gesture), Material
  // elsewhere. A custom transition would bypass that gesture entirely.
  @override
  RouteType get defaultRouteType => const RouteType.adaptive();

  @override
  List<AutoRoute> get routes => [
        AutoRoute(page: OnboardingRoute.page),
        AutoRoute(page: HomeRoute.page, initial: true),
        AutoRoute(path: '/reminders', page: RemindersRoute.page),
        AutoRoute(path: '/notes/:noteId', page: NoteDetailRoute.page),
        AutoRoute(path: '/add-update-note', page: AddUpdateNoteRoute.page),
      ];
}
