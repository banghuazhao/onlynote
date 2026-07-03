// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

part of 'routes.dart';

/// generated route for
/// [AddUpdateNoteScreen]
class AddUpdateNoteRoute extends PageRouteInfo<AddUpdateNoteRouteArgs> {
  AddUpdateNoteRoute({
    Key? key,
    Note? note,
    List<PageRouteInfo>? children,
  }) : super(
          AddUpdateNoteRoute.name,
          args: AddUpdateNoteRouteArgs(
            key: key,
            note: note,
          ),
          initialChildren: children,
        );

  static const String name = 'AddUpdateNoteRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<AddUpdateNoteRouteArgs>(
          orElse: () => const AddUpdateNoteRouteArgs());
      return AddUpdateNoteScreen(
        key: args.key,
        note: args.note,
      );
    },
  );
}

class AddUpdateNoteRouteArgs {
  const AddUpdateNoteRouteArgs({
    this.key,
    this.note,
  });

  final Key? key;

  final Note? note;

  @override
  String toString() {
    return 'AddUpdateNoteRouteArgs{key: $key, note: $note}';
  }
}

/// generated route for
/// [HomeScreen]
class HomeRoute extends PageRouteInfo<void> {
  const HomeRoute({List<PageRouteInfo>? children})
      : super(
          HomeRoute.name,
          initialChildren: children,
        );

  static const String name = 'HomeRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const HomeScreen();
    },
  );
}

/// generated route for
/// [NoteDetailScreen]
class NoteDetailRoute extends PageRouteInfo<NoteDetailRouteArgs> {
  NoteDetailRoute({
    Key? key,
    required String noteId,
    List<PageRouteInfo>? children,
  }) : super(
          NoteDetailRoute.name,
          args: NoteDetailRouteArgs(
            key: key,
            noteId: noteId,
          ),
          rawPathParams: {'noteId': noteId},
          initialChildren: children,
        );

  static const String name = 'NoteDetailRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final args = data.argsAs<NoteDetailRouteArgs>(
          orElse: () =>
              NoteDetailRouteArgs(noteId: pathParams.getString('noteId')));
      return NoteDetailScreen(
        key: args.key,
        noteId: args.noteId,
      );
    },
  );
}

class NoteDetailRouteArgs {
  const NoteDetailRouteArgs({
    this.key,
    required this.noteId,
  });

  final Key? key;

  final String noteId;

  @override
  String toString() {
    return 'NoteDetailRouteArgs{key: $key, noteId: $noteId}';
  }
}
