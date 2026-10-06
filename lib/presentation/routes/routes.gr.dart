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
    NotePhotoCapture? photoCapture,
    NotePhotoEditService? photoEditService,
    PhotoTextExtraction? photoTextExtraction,
    VoiceMemoService? voiceMemoService,
    VoiceMemoDrafts? voiceMemoDrafts,
    NoteReminderScheduler? reminderScheduler,
    WidgetCommands? widgetCommands,
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
            photoCapture: photoCapture,
            photoEditService: photoEditService,
            photoTextExtraction: photoTextExtraction,
            voiceMemoService: voiceMemoService,
            voiceMemoDrafts: voiceMemoDrafts,
            reminderScheduler: reminderScheduler,
            widgetCommands: widgetCommands,
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
        photoCapture: args.photoCapture,
        photoEditService: args.photoEditService,
        photoTextExtraction: args.photoTextExtraction,
        voiceMemoService: args.voiceMemoService,
        voiceMemoDrafts: args.voiceMemoDrafts,
        reminderScheduler: args.reminderScheduler,
        widgetCommands: args.widgetCommands,
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
    this.photoCapture,
    this.photoEditService,
    this.photoTextExtraction,
    this.voiceMemoService,
    this.voiceMemoDrafts,
    this.reminderScheduler,
    this.widgetCommands,
    this.start = NoteEditorStart.standard,
  });

  final Key? key;

  final Note? note;

  final String? folderId;

  final NoteTemplate? template;

  final Note? customTemplateNote;

  final NoteAutosaveStore? autosaveStore;

  final NotePhotoCapture? photoCapture;

  final NotePhotoEditService? photoEditService;

  final PhotoTextExtraction? photoTextExtraction;

  final VoiceMemoService? voiceMemoService;

  final VoiceMemoDrafts? voiceMemoDrafts;

  final NoteReminderScheduler? reminderScheduler;

  final WidgetCommands? widgetCommands;

  final NoteEditorStart start;

  @override
  String toString() {
    return 'AddUpdateNoteRouteArgs{key: $key, note: $note, folderId: $folderId, template: $template, customTemplateNote: $customTemplateNote, autosaveStore: $autosaveStore, photoCapture: $photoCapture, photoEditService: $photoEditService, photoTextExtraction: $photoTextExtraction, voiceMemoService: $voiceMemoService, voiceMemoDrafts: $voiceMemoDrafts, reminderScheduler: $reminderScheduler, widgetCommands: $widgetCommands, start: $start}';
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

/// generated route for
/// [RemindersScreen]
class RemindersRoute extends PageRouteInfo<RemindersRouteArgs> {
  RemindersRoute({
    Key? key,
    ReminderAgendaController? controller,
    List<PageRouteInfo>? children,
  }) : super(
          RemindersRoute.name,
          args: RemindersRouteArgs(
            key: key,
            controller: controller,
          ),
          initialChildren: children,
        );

  static const String name = 'RemindersRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<RemindersRouteArgs>(
          orElse: () => const RemindersRouteArgs());
      return RemindersScreen(
        key: args.key,
        controller: args.controller,
      );
    },
  );
}

class RemindersRouteArgs {
  const RemindersRouteArgs({
    this.key,
    this.controller,
  });

  final Key? key;

  final ReminderAgendaController? controller;

  @override
  String toString() {
    return 'RemindersRouteArgs{key: $key, controller: $controller}';
  }
}
