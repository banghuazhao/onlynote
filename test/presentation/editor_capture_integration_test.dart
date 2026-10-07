import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:onlynote/Tools/app_typography_settings.dart';
import 'package:onlynote/Tools/widget_commands.dart';
import 'package:onlynote/data/dto/note_dto.dart';
import 'package:onlynote/di/di.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/domain/model/note_image_layout.dart';
import 'package:onlynote/domain/model/note_text_style.dart';
import 'package:onlynote/domain/model/voice_memo.dart';
import 'package:onlynote/domain/repository/note_repository.dart';
import 'package:onlynote/domain/usecase/add_note_usecase.dart';
import 'package:onlynote/domain/usecase/update_note_usecase.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/voice_memo_player.dart';
import 'package:onlynote/presentation/routes/routes.dart';
import 'package:onlynote/presentation/screens/add_update_note/add_update_note_screen.dart';
import 'package:onlynote/presentation/screens/add_update_note/bloc/add_update_bloc.dart';
import 'package:onlynote/presentation/theme/theme.dart';
import 'package:onlynote/services/audio_storage.dart';
import 'package:onlynote/services/note_autosave.dart';
import 'package:onlynote/services/photo_text_extraction.dart';
import 'package:onlynote/services/voice_memo_drafts.dart';
import 'package:onlynote/services/voice_memo_service.dart';

class _Notes implements NoteRepository {
  final values = <String, NoteDto>{};
  @override
  List<NoteDto> getAllNotes() => values.values.toList();
  @override
  Future<NoteDto> getNote(String id) async => values[id]!;
  @override
  Future<void> addUpdateNote(NoteDto note) async => values[note.id!] = note;
  @override
  Future<void> deleteNote(String id) async => values.remove(id);
  @override
  Future<void> deleteMultiNotes(List<String> ids) async {
    for (final id in ids) {
      values.remove(id);
    }
  }
}

class _Store implements NoteAutosaveStore {
  _Store(this.notes);
  final _Notes notes;
  final saved = <Note>[];
  final recoveryDrafts = <String, NoteDto>{};
  final widgetPending = <Object?>[];
  final widgetAcknowledged = <String>[];
  WidgetCommands? widgetCommands;
  @override
  Future<void> writeDraft(Note note) async =>
      recoveryDrafts[note.id!] = NoteDto.fromNote(note);
  @override
  Future<void> removeDraft(String id) async => recoveryDrafts.remove(id);
  @override
  Future<void> saveNote(Note note) async {
    saved.add(note);
    await notes.addUpdateNote(NoteDto.fromNote(note));
  }
}

class _Extraction extends PhotoTextExtraction {
  final calls = <String>[];
  Future<PhotoTextResult> Function()? action;
  @override
  Future<PhotoTextResult> extract(String managedPath) async {
    calls.add(managedPath);
    return action == null
        ? const PhotoTextResult(PhotoTextStatus.text, text: 'Recognized text')
        : await action!();
  }
}

class _Platform implements VoiceMemoPlatform {
  final events = StreamController<Object?>.broadcast();
  final calls = <String>[];
  String? path;
  var phase = 'idle';
  var duration = 0;
  @override
  Stream<Object?> get states => events.stream;
  @override
  Future<Object?> invoke(String method,
      [Map<String, Object?>? arguments]) async {
    calls.add(method);
    if (method == 'startRecording') {
      path = arguments!['path'] as String;
      phase = 'recording';
      duration = 0;
    } else if (method == 'stopRecording') {
      phase = 'idle';
      duration = 5200;
    } else if (method == 'play') {
      path = arguments!['path'] as String;
      phase = 'playing';
    } else if (method != 'state') {
      phase = 'idle';
    }
    if (method == 'transcribe') return 'Unreviewed speech recognition';
    if (method == 'duration') return duration;
    return {'phase': phase, 'path': path, 'durationMs': duration};
  }
}

class _UnusedBox extends Fake implements Box {}

class _Audio extends AudioStorage {
  @override
  Future<String> resolvePath(String path) async => '/app/$path';
  @override
  Future<void> deletePaths(Iterable<String> paths) async {}
}

/// Real Hive/file durability is covered in voice_memo_drafts_test. This facade
/// asserts the editor's retain -> save -> acknowledge ownership handoff.
class _Drafts extends VoiceMemoDrafts {
  _Drafts(_Notes notes)
      : super(
            journal: _UnusedBox(),
            notes: notes,
            audio: _Audio(),
            readDuration: (_) async => 5200);
  final pending = <String, VoiceMemo>{};
  final completed = <VoiceMemo>[];
  final retained = <VoiceMemo>[];
  int prepared = 0;
  @override
  Future<VoiceMemo> prepare(Note note) async {
    prepared++;
    final memo = VoiceMemo(
        id: 'memo',
        path: 'note_audio/memo.m4a',
        durationMs: 0,
        createdAt: DateTime.utc(2026, 10, 6));
    pending[memo.id] = memo;
    return memo;
  }

  @override
  Future<void> retain(VoiceMemo memo) async {
    expect(pending, contains(memo.id));
    expect(memo.durationMs, greaterThan(0));
    retained.add(memo);
    pending[memo.id] = memo;
  }

  @override
  Future<void> complete(VoiceMemo memo) async {
    expect(
        notes
            .getAllNotes()
            .any((note) => note.toDomain().voiceMemos.contains(memo)),
        isTrue);
    completed.add(memo);
    pending.remove(memo.id);
  }

  @override
  Future<void> discard(VoiceMemo memo) async => pending.remove(memo.id);
}

class _Router extends RootStackRouter {
  _Router(this.store, this.extraction, this.service, this.drafts);
  final _Store store;
  final _Extraction extraction;
  final VoiceMemoService service;
  final _Drafts drafts;
  @override
  List<AutoRoute> get routes => [
        AutoRoute(
            initial: true,
            page: PageInfo(HomeRoute.name,
                builder: (_) => const Scaffold(body: Text('Library')))),
        AutoRoute(
            page: PageInfo(AddUpdateNoteRoute.name, builder: (data) {
          final args = data.argsAs<AddUpdateNoteRouteArgs>();
          return AddUpdateNoteScreen(
              start: args.start,
              note: args.note,
              autosaveStore: store,
              widgetCommands: store.widgetCommands,
              photoTextExtraction: extraction,
              voiceMemoService: service,
              voiceMemoDrafts: drafts);
        })),
        AutoRoute(
            page: PageInfo(NoteDetailRoute.name, builder: (data) {
          final args = data.argsAs<NoteDetailRouteArgs>();
          return Builder(
              builder: (context) => Scaffold(
                  key: ValueKey('test-linked-detail-${args.noteId}'),
                  body: Center(
                      child: TextButton(
                          key: const ValueKey('test-return-to-editor'),
                          onPressed: () => context.router.maybePop(),
                          child: const Text('Return to editor')))));
        })),
      ];
}

Finder _body() => find.byWidgetPredicate(
    (widget) => widget is TextField && widget.maxLines == 100);

void main() {
  final originalFonts = Map<String, GoogleFontBuilder>.of(kAppFontFamilies);
  setUp(() {
    for (final family in originalFonts.keys) {
      kAppFontFamilies[family] = (
              {textStyle, color, fontSize, fontWeight, fontStyle}) =>
          (textStyle ?? const TextStyle()).copyWith(
              color: color,
              fontSize: fontSize,
              fontWeight: fontWeight,
              fontStyle: fontStyle);
    }
  });
  tearDown(() => kAppFontFamilies.addAll(originalFonts));

  Future<(_Store, _Extraction, _Drafts, _Platform)> open(WidgetTester tester,
      {Note? note,
      List<Note> library = const [],
      bool enableWidgetCommands = false,
      NoteEditorStart start = NoteEditorStart.standard,
      bool settleEditor = true,
      bool reducedMotion = true}) async {
    final notes = _Notes();
    for (final entry in [...library, if (note != null) note]) {
      notes.values[entry.id!] = NoteDto.fromNote(entry);
    }
    getIt.pushNewScope();
    getIt.registerSingleton<NoteRepository>(notes);
    final store = _Store(notes);
    if (enableWidgetCommands) {
      store.widgetCommands = WidgetCommands(
          repository: notes,
          readPending: () async => List.of(store.widgetPending),
          acknowledge: (ids) async {
            store.widgetAcknowledged.addAll(ids);
            store.widgetPending.removeWhere(
                (value) => value is Map && ids.contains(value['id']));
          },
          readDraft: (id) => store.recoveryDrafts[id],
          writeDraft: (value) async => store.recoveryDrafts[value.id!] = value,
          removeDraft: (id) async => store.recoveryDrafts.remove(id),
          syncWidgets: () async {});
    }
    final extraction = _Extraction();
    final platform = _Platform();
    final service = VoiceMemoService(platform: platform);
    final drafts = _Drafts(notes);
    final bloc = AddUpdateBloc(AddNoteUsecase(notes), UpdateNoteUsecase(notes));
    final router = _Router(store, extraction, service, drafts);
    addTearDown(() async {
      // Transient snackbars retain a fallback timer through route disposal.
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpWidget(const SizedBox.shrink());
      router.dispose();
      await bloc.close();
      await service.dispose();
      await platform.events.close();
      store.widgetCommands?.updates.dispose();
      await getIt.popScope();
    });
    await tester.pumpWidget(BlocProvider.value(
        value: bloc,
        child: MaterialApp.router(
            routerConfig: router.config(),
            theme: AppTheme.light,
            localizationsDelegates: const [
              S.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate
            ],
            supportedLocales: S.delegate.supportedLocales,
            builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(disableAnimations: reducedMotion),
                child: child!))));
    await tester.pumpAndSettle();
    router.push(AddUpdateNoteRoute(note: note, start: start));
    if (settleEditor) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump();
    }
    return (store, extraction, drafts, platform);
  }

  Future<void> tap(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
  }

  testWidgets('OCR reviews corrected text before appending to the latest body',
      (tester) async {
    final (store, extraction, _, _) = await open(tester,
        note: Note(
            id: 'photo-note',
            description: 'Existing body',
            imagePaths: const [
              'note_images/photo.png'
            ],
            imageLayouts: const [
              NoteImageLayout(
                  path: 'note_images/photo.png',
                  textOffset: 13,
                  widthFactor: .6,
                  xFactor: .2,
                  aspectRatio: 2),
            ],
            textStyles: const [
              NoteTextStyleRange(
                  start: 0, end: 8, kind: NoteTextStyleKind.bold),
            ]));
    final recognition = Completer<PhotoTextResult>();
    extraction.action = () async => await recognition.future;
    final extract = find.byKey(const ValueKey('editor-extract-text'));
    await tester.ensureVisible(extract);
    // Apply the scroll before tapping the button, now below the body.
    await tester.pumpAndSettle();
    expect(extract.hitTestable(), findsOneWidget);
    await tester.tap(extract);
    // Recognition is intentionally pending; its progress animation cannot
    // settle until the test completes the native result below.
    await tester.pump(const Duration(milliseconds: 100));
    expect(extraction.calls, ['note_images/photo.png']);
    // An edit that arrives while native recognition is pending stays intact.
    await tester.enterText(_body(), 'Existing body with my newest edit');
    await tester.pump();
    recognition.complete(const PhotoTextResult(PhotoTextStatus.text,
        text: 'Raw recognized text'));
    await tester.pumpAndSettle();
    final review = find.byKey(const ValueKey('photo-text-review'));
    expect(review, findsOneWidget);
    await tester.enterText(review, 'Reviewed and corrected text');
    await tap(tester, find.text(S.current.Photo_Text_Insert));
    expect(tester.widget<TextField>(_body()).controller!.text,
        'Existing body with my newest edit');
    expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('note-body-end')))
            .controller!
            .text,
        '\nReviewed and corrected text');
    expect(store.saved.last.description,
        'Existing body with my newest edit\n\nReviewed and corrected text');
    expect(store.saved.last.imagePaths, ['note_images/photo.png']);
    expect(store.saved.last.imageLayouts, const [
      NoteImageLayout(
          path: 'note_images/photo.png',
          textOffset: 34,
          widthFactor: .6,
          xFactor: .2,
          aspectRatio: 2),
    ]);
    expect(store.saved.last.textStyles, const [
      NoteTextStyleRange(start: 0, end: 8, kind: NoteTextStyleKind.bold),
    ]);
    expect(extraction.calls, ['note_images/photo.png']);
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets('canceling OCR review never changes or saves the note body',
      (tester) async {
    final (store, _, _, _) = await open(tester,
        note: Note(
            id: 'photo-note',
            description: 'Original body',
            imagePaths: const ['note_images/photo.png']));
    await tap(tester, find.byKey(const ValueKey('editor-extract-text')));
    await tester.enterText(find.byKey(const ValueKey('photo-text-review')),
        'Discard this recognition');
    await tap(tester, find.text(S.current.Cancel));
    expect(tester.widget<TextField>(_body()).controller!.text, 'Original body');
    expect(store.saved, isEmpty);
  });

  testWidgets('OCR no-text result keeps the editor usable and makes no save',
      (tester) async {
    final (store, extraction, _, _) = await open(tester,
        note: Note(
            id: 'photo',
            description: 'Keep this body',
            imagePaths: const ['note_images/photo.png']));
    extraction.action =
        () async => const PhotoTextResult(PhotoTextStatus.noText);
    await tap(tester, find.byKey(const ValueKey('editor-extract-text')));
    expect(find.byKey(const ValueKey('photo-text-review')), findsNothing);
    expect(find.text(S.current.Photo_Text_No_Text), findsOneWidget);
    expect(store.saved, isEmpty);
    await tester.enterText(_body(), 'Continue editing');
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(store.saved.last.description, 'Continue editing');
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets(
      'audio-only note is durably saved before recording acknowledgement',
      (tester) async {
    final (store, _, drafts, platform) = await open(tester);
    await tap(tester, find.byKey(const ValueKey('editor-insert')));
    await tap(tester, find.byKey(const ValueKey('editor-record-voice')));
    expect(drafts.prepared, 0);
    expect(platform.calls, isNot(contains('startRecording')));
    await tap(tester, find.byKey(const ValueKey('voice-record')));
    await tap(tester, find.byKey(const ValueKey('voice-stop')));
    expect(drafts.pending.values.single.durationMs, 5200);
    expect(store.saved, isEmpty);
    await tap(tester, find.byKey(const ValueKey('voice-save')));
    final saved = store.saved.last;
    expect(saved.title?.trim() ?? '', isEmpty);
    expect(saved.description?.trim() ?? '', isEmpty);
    expect(saved.voiceMemos.single.durationMs, 5200);
    expect(drafts.completed, [saved.voiceMemos.single]);
    expect(drafts.pending, isEmpty);
    expect(find.byType(VoiceMemoPlayer), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('transcript editing and recording removal preserve other content',
      (tester) async {
    final memo = VoiceMemo(
        id: 'memo',
        path: 'note_audio/memo.m4a',
        durationMs: 5200,
        createdAt: DateTime.utc(2026, 10, 6),
        transcript: 'Original transcript');
    final (store, _, _, _) = await open(tester,
        note: Note(
            id: 'note',
            description: 'Unrelated body',
            todo: [Todo(id: 'task', title: 'Keep this task')],
            voiceMemos: [memo]));
    Finder menu() => find.descendant(
        of: find.byType(VoiceMemoPlayer),
        matching: find.byType(PopupMenuButton<String>));
    await tap(tester, menu());
    await tap(tester, find.text(S.current.Voice_Edit_Transcript));
    final transcript = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byWidgetPredicate(
            (widget) => widget is TextField && widget.maxLines == 8));
    await tester.enterText(transcript, 'Corrected transcript');
    await tap(tester, find.text(S.current.Voice_Save));
    expect(
        store.saved.last.voiceMemos.single.transcript, 'Corrected transcript');
    expect(store.saved.last.description, 'Unrelated body');
    expect(store.saved.last.todo.single.id, 'task');
    await tap(tester, menu());
    await tap(tester, find.text(S.current.Voice_Edit_Transcript));
    await tester.enterText(transcript, '');
    await tap(tester, find.text(S.current.Voice_Save));
    expect(store.saved.last.voiceMemos.single.transcript, isNull);
    await tap(tester, menu());
    await tap(tester, find.text(S.current.Voice_Delete));
    expect(store.saved.last.voiceMemos, isEmpty);
    expect(store.saved.last.description, 'Unrelated body');
    expect(store.saved.last.todo.single.title, 'Keep this task');
    expect(find.byType(VoiceMemoPlayer), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('voice shortcut presents once after the editor transition',
      (tester) async {
    final (store, _, drafts, platform) = await open(tester,
        start: NoteEditorStart.voice,
        settleEditor: false,
        reducedMotion: false);
    expect(find.byKey(const ValueKey('voice-record')), findsNothing);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('voice-record')), findsOneWidget);
    expect(drafts.prepared, 0);
    expect(platform.calls, isNot(contains('startRecording')));
    await tap(tester, find.text(S.current.Voice_Cancel));
    expect(find.byKey(const ValueKey('voice-record')), findsNothing);
    tester.view.physicalSize = const Size(450, 900);
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('voice-record')), findsNothing);
    expect(find.byKey(const ValueKey('editor-insert')), findsOneWidget);
    expect(store.saved, isEmpty);
    expect(drafts.prepared, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'widget completion during linked navigation uses fresh saved library data',
      (tester) async {
    final initial = Note(
        id: 'origin',
        title: 'Original title',
        description: 'Original body',
        tags: const ['Original'],
        linkedNoteIds: const ['linked'],
        todo: [Todo(id: 'task', title: 'Original task')]);
    final (store, _, _, _) = await open(tester,
        note: initial,
        library: [Note(id: 'linked', title: 'Related research')],
        enableWidgetCommands: true);

    await tap(tester, find.byKey(const ValueKey('linked-note-linked')));
    expect(find.byKey(const ValueKey('test-linked-detail-linked')),
        findsOneWidget);

    // A linked detail route can reach the origin through a backlink and save
    // edits there while its original editor remains underneath the route.
    final editedElsewhere = initial.copyWith(
        title: 'Latest saved title',
        description: 'Latest saved body',
        tags: const ['Latest'],
        isArchived: true,
        folderId: 'latest-folder',
        todo: [Todo(id: 'task', title: 'Latest task label')]);
    await store.notes.addUpdateNote(NoteDto.fromNote(editedElsewhere));
    store.widgetPending.add({
      'id': 'complete-task',
      'noteId': 'origin',
      'todoId': 'task',
      'completed': true,
      'createdAt': 100,
    });
    final imported = store.widgetCommands!.importPending();
    await tester.pump();
    await tester.pumpAndSettle();
    await imported;

    var saved = store.notes.values['origin']!.toDomain();
    expect(saved.title, 'Latest saved title');
    expect(saved.description, 'Latest saved body');
    expect(saved.tags, ['Latest']);
    expect(saved.isArchived, isTrue);
    expect(saved.folderId, 'latest-folder');
    expect(saved.todo.single.title, 'Latest task label');
    expect(saved.todo.single.completed, isTrue);
    expect(store.widgetAcknowledged, ['complete-task']);
    expect(store.recoveryDrafts, isEmpty);

    await tap(tester, find.byKey(const ValueKey('test-return-to-editor')));
    expect(tester.widget<TextField>(_body()).controller!.text,
        'Latest saved body');
    await tester.ensureVisible(_body());
    await tester.pumpAndSettle();
    await tester.enterText(_body(), 'Continue editing the latest saved body');
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    saved = store.notes.values['origin']!.toDomain();
    expect(saved.description, 'Continue editing the latest saved body');
    expect(saved.title, 'Latest saved title');
    expect(saved.tags, ['Latest']);
    expect(saved.isArchived, isTrue);
    expect(saved.todo.single.completed, isTrue);
    expect(saved.todo.single.title, 'Latest task label');

    // Re-registering the editor after refresh keeps subsequent widget actions
    // merged into the visible form instead of leaving it stale again.
    store.widgetPending.add({
      'id': 'reopen-task',
      'noteId': 'origin',
      'todoId': 'task',
      'completed': false,
      'createdAt': 101,
    });
    final reopened = store.widgetCommands!.importPending();
    await tester.pump();
    await tester.pumpAndSettle();
    await reopened;
    saved = store.notes.values['origin']!.toDomain();
    expect(saved.todo.single.completed, isFalse);
    expect(saved.description, 'Continue editing the latest saved body');
    expect(saved.tags, ['Latest']);
    expect(saved.isArchived, isTrue);
    expect(store.widgetAcknowledged, ['complete-task', 'reopen-task']);
    expect(tester.takeException(), isNull);
  });
}
