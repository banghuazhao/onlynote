import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/presentation/screens/screens.dart';

export 'package:auto_route/auto_route.dart';

part 'routes.gr.dart';

@AutoRouterConfig(replaceInRouteName: 'Screen,Route')
class AppRouter extends RootStackRouter {
  @override
  RouteType get defaultRouteType => const RouteType.custom(
        transitionsBuilder: TransitionsBuilders.slideRightWithFade,
        durationInMilliseconds: 200,
      );

  @override
  List<AutoRoute> get routes => [
        AutoRoute(page: HomeRoute.page, initial: true),
        AutoRoute(path: '/notes/:noteId', page: NoteDetailRoute.page),
        AutoRoute(path: '/add-update-note', page: AddUpdateNoteRoute.page),
      ];
}
