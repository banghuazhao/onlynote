import 'package:auto_route/auto_route.dart';
import 'package:onlynote/presentation/screens/screens.dart';

export 'package:auto_route/auto_route.dart';

export 'routes.gr.dart';

@CustomAutoRouter(
  transitionsBuilder: TransitionsBuilders.slideRightWithFade,
  durationInMilliseconds: 200,
  replaceInRouteName: 'Screen,Route',
  routes: <AutoRoute>[
    AutoRoute(page: HomeScreen, initial: true),
    AutoRoute(path: '/notes/:noteId', page: NoteDetailScreen),
    AutoRoute(path: 'add-update-note', page: AddUpdateNoteScreen),
  ],
)
class $AppRouter {}
