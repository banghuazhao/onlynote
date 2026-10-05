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
    String? folderId,
    NoteTemplate? template,
    Note? customTemplateNote,
    NoteAutosaveStore? autosaveStore,
    NoteEditorStart start = NoteEditorStart.standard,
    List<PageRouteInfo>? children,
  }) : super(
          AddUpdateNoteRoute.name,
          args: AddUpdateNoteRouteArgs(
            key: key,
            note: note,
            folderId: folderId,
            template: template,
            customTemplateNote: customTemplateNote,
            autosaveStore: autosaveStore,
            start: start,
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
        folderId: args.folderId,
        template: args.template,
        customTemplateNote: args.customTemplateNote,
        autosaveStore: args.autosaveStore,
        start: args.start,
      );
    },
  );
}

class AddUpdateNoteRouteArgs {
  const AddUpdateNoteRouteArgs({
    this.key,
    this.note,
    this.folderId,
    this.template,
    this.customTemplateNote,
    this.autosaveStore,
    this.start = NoteEditorStart.standard,
  });

  final Key? key;

  final Note? note;

  final String? folderId;

  final NoteTemplate? template;

  final Note? customTemplateNote;

  final NoteAutosaveStore? autosaveStore;

  final NoteEditorStart start;

  @override
  String toString() {
    return 'AddUpdateNoteRouteArgs{key: $key, note: $note, folderId: $folderId, template: $template, customTemplateNote: $customTemplateNote, autosaveStore: $autosaveStore, start: $start}';
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
    CustomNoteTemplateStore? templateStore,
    List<PageRouteInfo>? children,
  }) : super(
          NoteDetailRoute.name,
          args: NoteDetailRouteArgs(
            key: key,
            noteId: noteId,
            templateStore: templateStore,
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
        templateStore: args.templateStore,
      );
    },
  );
}

class NoteDetailRouteArgs {
  const NoteDetailRouteArgs({
    this.key,
    required this.noteId,
    this.templateStore,
  });

  final Key? key;

  final String noteId;

  final CustomNoteTemplateStore? templateStore;

  @override
  String toString() {
    return 'NoteDetailRouteArgs{key: $key, noteId: $noteId, templateStore: $templateStore}';
  }
}

/// generated route for
/// [OnboardingScreen]
class OnboardingRoute extends PageRouteInfo<void> {
  const OnboardingRoute({List<PageRouteInfo>? children})
      : super(
          OnboardingRoute.name,
          initialChildren: children,
        );

  static const String name = 'OnboardingRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const OnboardingScreen();
    },
  );
}
