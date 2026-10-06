import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:onlynote/Tools/app_typography_settings.dart';
import 'package:onlynote/data/dto/note_dto.dart';
import 'package:onlynote/domain/model/note.dart';
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
  @override
  Future<void> writeDraft(Note note) async {}
  @override
  Future<void> removeDraft(String id) async {}
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
              note: args.note,
              autosaveStore: store,
              photoTextExtraction: extraction,
              voiceMemoService: service,
              voiceMemoDrafts: drafts);
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
      {Note? note}) async {
    final notes = _Notes();
    if (note != null) notes.values[note.id!] = NoteDto.fromNote(note);
    final store = _Store(notes);
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
                data: MediaQuery.of(context).copyWith(disableAnimations: true),
                child: child!))));
    await tester.pumpAndSettle();
    router.push(AddUpdateNoteRoute(note: note));
    await tester.pumpAndSettle();
    return (store, extraction, drafts, platform);
  }

  Future<void> tap(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.tap(finder);
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
  }

  testWidgets('OCR reviews corrected text before appending to the latest body',
      (tester) async {
    final (store, extraction, _, _) = await open(tester,
        note: Note(
            id: 'photo-note',
            description: 'Existing body',
            imagePaths: const ['note_images/photo.png']));
    final recognition = Completer<PhotoTextResult>();
    extraction.action = () async => await recognition.future;
    final extract = find.byKey(const ValueKey('editor-extract-text'));
    await tester.ensureVisible(extract);
    await tester.tap(extract);
    // Recognition is intentionally pending; its progress animation cannot
    // settle until the test completes the native result below.
    await tester.pump(const Duration(milliseconds: 100));
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
        'Existing body with my newest edit\n\nReviewed and corrected text');
    expect(store.saved.last.description,
        'Existing body with my newest edit\n\nReviewed and corrected text');
    expect(store.saved.last.imagePaths, ['note_images/photo.png']);
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
}
