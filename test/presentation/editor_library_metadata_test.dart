import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:onlynote/Tools/app_typography_settings.dart';
import 'package:onlynote/data/dto/note_dto.dart';
import 'package:onlynote/di/di.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/domain/model/note_text_style.dart';
import 'package:onlynote/domain/model/voice_memo.dart';
import 'package:onlynote/domain/repository/note_repository.dart';
import 'package:onlynote/domain/usecase/add_note_usecase.dart';
import 'package:onlynote/domain/usecase/update_note_usecase.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/simple_formatting_controller.dart';
import 'package:onlynote/presentation/screens/add_update_note/add_update_note_screen.dart';
import 'package:onlynote/presentation/screens/add_update_note/bloc/add_update_bloc.dart';
import 'package:onlynote/presentation/theme/theme.dart';
import 'package:onlynote/services/note_autosave.dart';
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
    ids.forEach(values.remove);
  }
}

class _Store implements NoteAutosaveStore {
  _Store(this.notes);
  final _Notes notes;
  final drafts = <String, Note>{};
  final saved = <Note>[];
  @override
  Future<void> writeDraft(Note note) async => drafts[note.id!] = note;
  @override
  Future<void> removeDraft(String id) async => drafts.remove(id);
  @override
  Future<void> saveNote(Note note) async {
    saved.add(note);
    await notes.addUpdateNote(NoteDto.fromNote(note));
  }
}

class _IdleVoicePlatform implements VoiceMemoPlatform {
  @override
  Stream<Object?> get states => const Stream.empty();
  @override
  Future<Object?> invoke(String method,
      [Map<String, Object?>? arguments]) async {
    if (method != 'state' && method != 'stopPlayback') {
      throw StateError('Unexpected native media operation: $method');
    }
    return {'phase': 'idle'};
  }
}

Future<(_Notes, _Store)> _openEditor(
  WidgetTester tester, {
  Note? note,
  List<Note> library = const [],
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(390, 844);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  final notes = _Notes();
  for (final entry in [...library, if (note != null) note]) {
    notes.values[entry.id!] = NoteDto.fromNote(entry);
  }
  getIt.pushNewScope();
  getIt.registerSingleton<NoteRepository>(notes);
  final store = _Store(notes);
  final service = VoiceMemoService(platform: _IdleVoicePlatform());
  final bloc = AddUpdateBloc(AddNoteUsecase(notes), UpdateNoteUsecase(notes));
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await bloc.close();
    await service.dispose();
    await getIt.popScope();
  });
  await tester.pumpWidget(MaterialApp(
    theme: AppTheme.light,
    supportedLocales: S.delegate.supportedLocales,
    localizationsDelegates: const [
      S.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: true),
      child: child!,
    ),
    home: BlocProvider.value(
      value: bloc,
      child: AddUpdateNoteScreen(
        note: note,
        autosaveStore: store,
        voiceMemoService: service,
      ),
    ),
  ));
  await tester.pumpAndSettle();
  return (notes, store);
}

Future<void> _tap(WidgetTester tester, Finder target) async {
  await tester.ensureVisible(target);
  // ensureVisible updates scroll positions before their next layout frame.
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}

Future<void> _waitForAutosave(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 1));
  await tester.pumpAndSettle();
}

void main() {
  final originalFonts = Map<String, GoogleFontBuilder>.of(kAppFontFamilies);
  setUpAll(() => initializeDateFormatting());
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

  testWidgets('formatting alone autosaves without changing note metadata',
      (tester) async {
    final initial = Note(
      id: 'current',
      title: 'Trip',
      description: 'Pack snacks',
      dateTime: DateTime.utc(2026, 10, 6),
      folderId: 'travel',
      isPinned: true,
      isArchived: true,
      tags: const ['Personal'],
      linkedNoteIds: const ['packing'],
      voiceMemos: [
        VoiceMemo(
            id: 'memo',
            path: 'note_audio/memo.m4a',
            durationMs: 1000,
            createdAt: DateTime.utc(2026, 10, 6))
      ],
    );
    final (notes, store) = await _openEditor(tester, note: initial);
    final body = find.byWidgetPredicate(
        (widget) => widget is TextField && widget.maxLines == 100);
    await _tap(tester, body);
    final field = tester.widget<TextField>(body);
    final controller = field.controller! as SimpleFormattingController;
    controller.selection = const TextSelection(baseOffset: 0, extentOffset: 4);
    await tester.pump();
    await _tap(tester, find.byKey(const ValueKey('format-bold')));
    expect(field.focusNode!.hasFocus, isTrue);
    expect(controller.selection,
        const TextSelection(baseOffset: 0, extentOffset: 4));
    await _waitForAutosave(tester);

    final saved = notes.values['current']!.toDomain();
    expect(store.saved, isNotEmpty);
    expect(
        saved,
        initial.copyWith(dateTime: saved.dateTime, textStyles: const [
          NoteTextStyleRange(start: 0, end: 4, kind: NoteTextStyleKind.bold),
        ]));
    expect(store.drafts, isEmpty);

    // Opening the saved note must restore the same spans and readable body.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await _openEditor(tester, note: saved);
    final reopened = tester.widget<TextField>(body).controller!
        as SimpleFormattingController;
    expect(reopened.text, 'Pack snacks');
    expect(reopened.styles, saved.textStyles);
    expect(tester.takeException(), isNull);
  });

  testWidgets('heading and bullets save a readable body with literal symbols',
      (tester) async {
    final (notes, store) = await _openEditor(tester,
        note: Note(
          id: 'current',
          title: 'Ideas',
          description: 'Weekend\n# literal **stars**',
        ));
    final body = find.byWidgetPredicate(
        (widget) => widget is TextField && widget.maxLines == 100);
    await _tap(tester, body);
    final controller = tester.widget<TextField>(body).controller!
        as SimpleFormattingController;
    controller.selection = const TextSelection.collapsed(offset: 3);
    await _tap(tester, find.byKey(const ValueKey('format-heading')));
    controller.selection = const TextSelection.collapsed(offset: 15);
    await _tap(tester, find.byKey(const ValueKey('format-bullets')));
    await _waitForAutosave(tester);
    final saved = notes.values['current']!.toDomain();
    expect(saved.description, 'Weekend\n• # literal **stars**');
    expect(saved.textStyles, const [
      NoteTextStyleRange(start: 0, end: 7, kind: NoteTextStyleKind.heading),
    ]);
    expect(store.drafts, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('bold before typing does not save an empty note', (tester) async {
    final (notes, store) = await _openEditor(tester);
    await _tap(tester, find.byKey(const ValueKey('format-bold')));
    await _waitForAutosave(tester);
    expect(notes.values, isEmpty);
    expect(store.saved, isEmpty);
    expect(store.drafts, isEmpty);

    tester.testTextInput.updateEditingValue(const TextEditingValue(
      text: '新想法💡',
      selection: TextSelection.collapsed(offset: 5),
    ));
    await _waitForAutosave(tester);
    final saved = notes.values.values.single.toDomain();
    expect(saved.description, '新想法💡');
    expect(saved.textStyles, const [
      NoteTextStyleRange(start: 0, end: 5, kind: NoteTextStyleKind.bold),
    ]);
    expect(store.drafts, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('editing tags preserves archived note metadata and media',
      (tester) async {
    final memo = VoiceMemo(
      id: 'memo',
      path: 'note_audio/memo.m4a',
      durationMs: 5200,
      createdAt: DateTime.utc(2026, 10, 6),
      transcript: 'Remember the route.',
    );
    final initial = Note(
      id: 'current',
      title: 'Trip plan',
      description: 'Bring the map.',
      folderId: 'travel',
      isPinned: true,
      isArchived: true,
      sortOrder: -42,
      color: const Color(0xFFFFF4C2),
      tags: const ['Personal'],
      linkedNoteIds: const ['packing'],
      voiceMemos: [memo],
      todo: [Todo(id: 'task', title: 'Book room', completed: true)],
    );
    final (notes, store) = await _openEditor(tester,
        note: initial, library: [Note(id: 'packing', title: 'Packing')]);
    await _tap(tester, find.byKey(const ValueKey('editor-edit-tags')));
    await _tap(tester, find.byKey(const ValueKey('note-tag-remove-personal')));
    await tester.enterText(
        find.byKey(const ValueKey('note-tag-input')), ' Work ');
    await _tap(tester, find.byKey(const ValueKey('note-tags-save')));
    await _waitForAutosave(tester);
    final saved = notes.values['current']!.toDomain();
    expect(store.saved, isNotEmpty);
    expect(store.saved.every((note) => note.id == 'current'), isTrue);
    expect(saved.tags, ['Work']);
    expect(saved.isArchived, isTrue);
    expect(saved.folderId, 'travel');
    expect(saved.isPinned, isTrue);
    expect(saved.sortOrder, -42);
    expect(saved.color, initial.color);
    expect(saved.linkedNoteIds, ['packing']);
    expect(saved.voiceMemos, [memo]);
    expect(saved.todo, initial.todo);
    expect(saved.title, initial.title);
    expect(saved.description, initial.description);
    expect(store.drafts, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('link selection saves to the same note without losing typing',
      (tester) async {
    final (notes, store) = await _openEditor(
      tester,
      note: Note(
        id: 'current',
        title: 'Project',
        description: 'Original body',
        linkedNoteIds: const ['old'],
        tags: const ['Work'],
        folderId: 'projects',
        isPinned: true,
      ),
      library: [
        Note(id: 'old', title: 'Previous outline'),
        Note(id: 'new', title: 'Archived research', isArchived: true),
      ],
    );
    final body = find.byWidgetPredicate(
        (widget) => widget is TextField && widget.maxLines == 100);
    await tester.ensureVisible(body);
    await tester.pumpAndSettle();
    await tester.enterText(body, 'Typed draft stays with the new links.');
    await tester.pump();
    await _tap(tester, find.byKey(const ValueKey('edit-note-links')));
    await _tap(tester, find.byKey(const ValueKey('choose-note-link-old')));
    await _tap(tester, find.byKey(const ValueKey('choose-note-link-new')));
    await _tap(tester, find.byKey(const ValueKey('save-note-links')));
    await _waitForAutosave(tester);
    final saved = notes.values['current']!.toDomain();
    expect(saved.linkedNoteIds, ['new']);
    expect(saved.description, 'Typed draft stays with the new links.');
    expect(saved.tags, ['Work']);
    expect(saved.folderId, 'projects');
    expect(saved.isPinned, isTrue);
    expect(notes.values.keys.toSet(), {'current', 'old', 'new'});
    expect(store.saved.every((note) => note.id == 'current'), isTrue);
    expect(store.drafts, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('cancelling link and tag drafts keeps the saved metadata',
      (tester) async {
    final (notes, store) = await _openEditor(
      tester,
      note: Note(
          id: 'current',
          title: 'Project',
          linkedNoteIds: const ['old'],
          tags: const ['Work']),
      library: [Note(id: 'old', title: 'Outline')],
    );
    await _tap(tester, find.byKey(const ValueKey('edit-note-links')));
    await _tap(tester, find.byKey(const ValueKey('choose-note-link-old')));
    await _tap(tester, find.byIcon(Icons.close_rounded));
    await _tap(tester, find.byKey(const ValueKey('editor-edit-tags')));
    await tester.enterText(
        find.byKey(const ValueKey('note-tag-input')), 'Unsaved tag');
    await _tap(tester, find.byKey(const ValueKey('note-tags-cancel')));
    await _waitForAutosave(tester);
    final saved = notes.values['current']!.toDomain();
    expect(saved.tags, ['Work']);
    expect(saved.linkedNoteIds, ['old']);
    expect(store.saved, isEmpty);
    expect(store.drafts, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a new links-only hub is durable without title or body',
      (tester) async {
    final (notes, store) = await _openEditor(tester,
        library: [Note(id: 'target', title: 'Research')]);
    expect(notes.values, hasLength(1));
    await _tap(tester, find.byKey(const ValueKey('edit-note-links')));
    await _tap(tester, find.byKey(const ValueKey('choose-note-link-target')));
    await _tap(tester, find.byKey(const ValueKey('save-note-links')));
    await _waitForAutosave(tester);
    expect(notes.values, hasLength(2));
    final hubDto =
        notes.values.values.singleWhere((note) => note.id != 'target');
    final hub = hubDto.toDomain();
    expect(hub.title?.trim() ?? '', isEmpty);
    expect(hub.description?.trim() ?? '', isEmpty);
    expect(hub.todo, isEmpty);
    expect(hub.imagePaths, isEmpty);
    expect(hub.voiceMemos, isEmpty);
    expect(hub.linkedNoteIds, ['target']);
    expect(hubDto.validNote, isTrue);
    expect(NoteAutosave.hasContent(hub), isTrue);
    expect(store.saved.map((note) => note.id).toSet(), {hub.id});
    expect(store.drafts, isEmpty);
    expect(tester.takeException(), isNull);
  });
}
