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
        AutoRoute(path: '/notes/:noteId', page: NoteDetailRoute.page),
        AutoRoute(path: '/add-update-note', page: AddUpdateNoteRoute.page),
      ];
}
