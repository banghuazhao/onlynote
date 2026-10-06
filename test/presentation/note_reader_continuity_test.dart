import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' show ImageByteFormat;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:onlynote/Tools/app_typography_settings.dart';
import 'package:onlynote/Tools/locator.dart';
import 'package:onlynote/common/constants.dart';
import 'package:onlynote/data/dto/note_dto.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/domain/repository/note_repository.dart';
import 'package:onlynote/domain/usecase/get_note_usecase.dart';
import 'package:onlynote/domain/usecase/update_note_usecase.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/formatted_note_text.dart';
import 'package:onlynote/presentation/components/note_document_view.dart';
import 'package:onlynote/presentation/components/note_find_bar.dart';
import 'package:onlynote/presentation/components/note_info_sheet.dart';
import 'package:onlynote/presentation/components/note_reader_position_controller.dart';
import 'package:onlynote/presentation/routes/routes.dart';
import 'package:onlynote/presentation/screens/note_detail/bloc/detail/note_detail_bloc.dart';
import 'package:onlynote/presentation/screens/note_detail/note_detail_screen.dart';
import 'package:onlynote/presentation/theme/theme.dart';
import 'package:onlynote/services/note_autosave.dart';
import 'package:onlynote/services/note_position_store.dart';
import 'package:onlynote/services/note_selection.dart';
import 'package:onlynote/services/note_selection_transfer.dart';
import 'package:onlynote/services/note_statistics.dart';

class _Notes implements NoteRepository {
  _Notes(Note initial) : note = NoteDto.fromNote(initial);
  NoteDto note;
  int writes = 0;
  @override
  Future<NoteDto> getNote(String id) async => note;
  @override
  List<NoteDto> getAllNotes() => [note];
  @override
  Future<void> addUpdateNote(NoteDto next) async {
    writes++;
    note = next;
  }

  @override
  Future<void> deleteNote(String id) async {}
  @override
  Future<void> deleteMultiNotes(List<String> ids) async {}
}

class _AutosaveStore implements NoteAutosaveStore {
  _AutosaveStore(this.notes);
  final _Notes notes;
  final drafts = <String, Note>{};
  @override
  Future<void> writeDraft(Note note) async => drafts[note.id!] = note;
  @override
  Future<void> removeDraft(String id) async => drafts.remove(id);
  @override
  Future<void> saveNote(Note note) =>
      notes.addUpdateNote(NoteDto.fromNote(note));
}

class _Router extends RootStackRouter {
  _Router(this.id, this.positions, this.transfer);
  final String id;
  final NotePositionStore positions;
  final NoteSelectionTransfer transfer;
  @override
  List<AutoRoute> get routes => [
        AutoRoute(
          initial: true,
          page: PageInfo('ReaderContinuityTestRoute',
              builder: (_) => NoteDetailScreen(
                  noteId: id,
                  positionStore: positions,
                  selectionTransfer: transfer)),
        ),
      ];
}

Future<_Notes> _mount(
    WidgetTester tester, Note note, NotePositionStore positions,
    {Size size = const Size(390, 844),
    double textScale = 1,
    Locale locale = const Locale('en')}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final notes = _Notes(note);
  final autosave = _AutosaveStore(notes);
  final transfer = NoteSelectionTransfer(
      repository: notes,
      store: autosave,
      readDraft: (id) => autosave.drafts[id]);
  final detail =
      NoteDetailBloc(GetNoteUsecase(notes), UpdateNoteUsecase(notes));
  final router = _Router(note.id!, positions, transfer);
  final appTheme = AppTheme.light;
  final theme = const bool.fromEnvironment('CAPTURE_UI')
      ? appTheme.copyWith(
          textTheme: appTheme.textTheme.apply(
              fontFamily: 'Roboto', fontFamilyFallback: ['DroidSansFallback']),
          primaryTextTheme: appTheme.primaryTextTheme.apply(
              fontFamily: 'Roboto', fontFamilyFallback: ['DroidSansFallback']))
      : appTheme;
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    router.dispose();
    await detail.close();
  });
  await tester.pumpWidget(BlocProvider.value(
    value: detail,
    child: RepaintBoundary(
      key: const ValueKey('reader-screen-capture'),
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        routerConfig: router.config(),
        theme: theme,
        locale: locale,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
            disableAnimations: true,
          ),
          child: child!,
        ),
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: S.delegate.supportedLocales,
      ),
    ),
  ));
  await tester.pumpAndSettle();
  return notes;
}

Future<void> _capture(WidgetTester tester, String name) async {
  if (!const bool.fromEnvironment('CAPTURE_UI')) return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(const ValueKey('reader-screen-capture')));
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 2);
    try {
      final bytes = await image.toByteData(format: ImageByteFormat.png);
      await File('/tmp/onlynote-reader-$name.png')
          .writeAsBytes(bytes!.buffer.asUint8List());
    } finally {
      image.dispose();
    }
  });
}

Note _longNote() => Note(
    id: 'reader-note',
    title: 'Reading project',
    dateTime: DateTime(2026, 10, 7),
    description: '${'Opening paragraph with important detail.\n' * 35}'
        'Resume at this specific paragraph 👩🏽‍💻.\n'
        '${'Following paragraph with more detail.\n' * 35}'
        'Search destination\n${'Final supporting paragraph.\n' * 20}');

LoadedView _loaded(WidgetTester tester) =>
    tester.widget<LoadedView>(find.byType(LoadedView));

Rect _resumeRect(WidgetTester tester, Note note, int offset) {
  final part = find.byWidgetPredicate((widget) =>
      widget is FormattedNoteText &&
      widget.text.contains('Resume at this specific'));
  return NoteReaderGlyph.fromContext(tester.element(part))!
      .globalRectForOffset(offset)!;
}

Future<void> _openFind(WidgetTester tester) async {
  await tester.tap(find.byTooltip(S.current.More_Options));
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.text(S.current.Find_In_Note));
  await tester.tap(find.text(S.current.Find_In_Note));
  await tester.pumpAndSettle();
}

void main() {
  final fonts = Map<String, GoogleFontBuilder>.of(kAppFontFamilies);
  setUpAll(() async {
    await initializeDateFormatting();
    if (!locator.isRegistered<S>()) locator.registerSingleton(S());
    if (const bool.fromEnvironment('CAPTURE_UI')) {
      for (final family in ['Roboto', 'DroidSansFallback']) {
        final font = FontLoader(family)
          ..addFont(File(
                  'assets/fonts/$family${family == 'Roboto' ? '-Regular' : ''}.ttf')
              .readAsBytes()
              .then(ByteData.sublistView));
        await font.load();
      }
      final icons = FontLoader('MaterialIcons')
        ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
      await icons.load();
    }
  });
  setUp(() {
    for (final family in fonts.keys) {
      kAppFontFamilies[family] = (
              {textStyle, color, fontSize, fontWeight, fontStyle}) =>
          (textStyle ?? const TextStyle()).copyWith(
              color: color,
              fontSize: fontSize,
              fontWeight: fontWeight,
              fontStyle: fontStyle,
              fontFamily:
                  const bool.fromEnvironment('CAPTURE_UI') ? 'Roboto' : null,
              fontFamilyFallback: const bool.fromEnvironment('CAPTURE_UI')
                  ? ['DroidSansFallback']
                  : null);
    }
  });
  tearDown(() => kAppFontFamilies.addAll(fonts));

  testWidgets('reader reopens at a saved body glyph without content writes',
      (tester) async {
    final note = _longNote();
    final body = note.description!;
    final offset = body.indexOf('Resume at');
    final positions = NotePositionStore.memory();
    await positions.saveReading(
        note.id!, NoteReadingPosition.capture(text: body, offset: offset));
    await positions.saveWriting(
        note.id!,
        NoteWritingPosition.capture(
            field: NoteWritingField.title,
            text: note.title!,
            selection: const TextSelection.collapsed(offset: 3)));
    final repository = await _mount(tester, note, positions);
    final viewport = NoteReaderViewport.fromContext(
        tester.element(find.byType(NoteDocumentView)))!;
    expect(_loaded(tester).scrollController!.offset, greaterThan(0));
    expect(
        _resumeRect(tester, note, offset).top, closeTo(viewport.bounds.top, 1));
    expect((await positions.read(note.id!)).writing, isNotNull);
    expect(repository.writes, 0);
    expect(tester.testTextInput.isVisible, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('scroll persists a new glyph and background flushes immediately',
      (tester) async {
    final note = _longNote();
    final positions = NotePositionStore.memory();
    final repository = await _mount(tester, note, positions);
    final loaded = _loaded(tester);
    loaded.scrollController!.jumpTo(1500);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    final saved = (await positions.read(note.id!)).reading!;
    expect(saved.resolve(note.description!), greaterThan(0));
    loaded.scrollController!.jumpTo(2100);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    final background = (await positions.read(note.id!)).reading!;
    expect(background.resolve(note.description!),
        greaterThan(saved.resolve(note.description!)));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    expect(repository.writes, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'Find navigation preserves the normal position and close restores it',
      (tester) async {
    final note = _longNote();
    final offset = note.description!.indexOf('Resume at');
    final positions = NotePositionStore.memory();
    await positions.saveReading(note.id!,
        NoteReadingPosition.capture(text: note.description!, offset: offset));
    final repository = await _mount(tester, note, positions);
    await _openFind(tester);
    final findField = find.descendant(
        of: find.byType(NoteFindBar), matching: find.byType(TextField));
    await tester.enterText(findField, 'Search destination');
    await tester.pumpAndSettle();
    _loaded(tester).scrollController!.jumpTo(300);
    await tester.pump(const Duration(milliseconds: 350));
    expect((await positions.read(note.id!)).reading!.resolve(note.description!),
        offset);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    expect((await positions.read(note.id!)).reading!.resolve(note.description!),
        offset);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.tap(find.byTooltip(S.current.Find_Close));
    await tester.pumpAndSettle();
    expect(find.byType(NoteFindBar), findsNothing);
    final viewport = NoteReaderViewport.fromContext(
        tester.element(find.byType(NoteDocumentView)))!;
    expect(
        _resumeRect(tester, note, offset).top, closeTo(viewport.bounds.top, 1));
    expect(repository.writes, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a delayed stored position cannot replace a user scroll',
      (tester) async {
    final note = _longNote();
    final delayed = _DelayedPositionStorage();
    final positions = NotePositionStore(storage: delayed);
    final repository = await _mount(tester, note, positions);
    await tester.drag(find.byType(ListView).first, const Offset(0, -450));
    await tester.pumpAndSettle();
    final userOffset = _loaded(tester).scrollController!.offset;
    expect(userOffset, greaterThan(0));
    delayed.response.complete(jsonEncode({
      'version': 1,
      'reading': NoteReadingPosition.capture(
              text: note.description!,
              offset: note.description!.indexOf('Search destination'))
          .toJson(),
    }));
    await tester.pumpAndSettle();
    expect(_loaded(tester).scrollController!.offset, closeTo(userOffset, 1));
    expect(repository.writes, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'reader selection adds rows and Undo retains later source changes',
      (tester) async {
    final note = Note(
        id: 'selection-reader',
        title: 'Source title',
        description: 'Original source prose stays here.\n'
            '- First line\n2. 👩🏽‍💻 Second line',
        dateTime: DateTime(2026, 10, 7),
        todo: [Todo(id: 'existing', title: 'Existing item')]);
    final repository = await _mount(tester, note, NotePositionStore.memory());
    final source = find.byWidgetPredicate((widget) =>
        widget is FormattedNoteText && widget.text == note.description);
    await tester.ensureVisible(source);
    await tester.tap(
        find.descendant(of: source, matching: find.byType(SelectableText)));
    final editable = tester.state<EditableTextState>(
        find.descendant(of: source, matching: find.byType(EditableText)));
    editable.widget.controller.selection = TextSelection(
        baseOffset: note.description!.indexOf('- First line'),
        extentOffset: note.description!.length);
    await tester.pump();
    editable.hideToolbar(false);
    expect(editable.showToolbar(), isTrue);
    await tester.pumpAndSettle();
    final toolbar = tester.widget<AdaptiveTextSelectionToolbar>(
        find.byType(AdaptiveTextSelectionToolbar));
    expect(toolbar.buttonItems!.map((item) => item.label),
        contains(S.current.Add_Selection_To_Checklist));
    if (find.text(S.current.Add_Selection_To_Checklist).evaluate().isEmpty) {
      final more = find.descendant(
          of: find.byType(AdaptiveTextSelectionToolbar),
          matching: find.byIcon(Icons.more_vert));
      await tester.tap(more);
      await tester.pumpAndSettle();
    }
    await _capture(tester, 'selected-lines-menu');
    await tester.tap(find.text(S.current.Add_Selection_To_Checklist));
    await tester.pumpAndSettle();
    final added = repository.note.toDomain();
    expect(added.description, note.description);
    expect(added.todo.map((todo) => todo.title),
        ['Existing item', 'First line', '👩🏽‍💻 Second line']);
    expect(find.text(S.current.Selection_Checklist_Added(2)), findsOneWidget);
    await _capture(tester, 'selected-lines-added');
    repository.note = NoteDto.fromNote(added.copyWith(
      title: 'A later source title',
      todo: [
        ...added.todo,
        Todo(id: 'later', title: 'A later independent row')
      ],
    ));
    await tester.tap(find.text(S.current.Undo));
    await tester.pumpAndSettle();
    final undone = repository.note.toDomain();
    expect(undone.title, 'A later source title');
    expect(undone.description, note.description);
    expect(undone.todo.map((todo) => todo.id), ['existing', 'later']);
    expect(repository.writes, 2);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('reader rejects a too-long checklist row without partial writes',
      (tester) async {
    final note = Note(
        id: 'long-selection',
        title: 'Source',
        description: 'Prose',
        dateTime: DateTime(2026, 10, 7));
    final repository = await _mount(tester, note, NotePositionStore.memory());
    _loaded(tester).onAddSelectionToChecklist!(
        NoteTextSelection(text: 'Short row\n${'x' * (todoMaxCharCount + 1)}'));
    await tester.pumpAndSettle();
    expect(repository.note.toDomain().todo, isEmpty);
    expect(repository.writes, 0);
    expect(find.text(S.current.Selection_Checklist_Too_Long), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(find.text(S.current.Selection_Checklist_Too_Long), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('More shows saved note statistics without altering note content',
      (tester) async {
    final note = Note(
        id: 'info-reader',
        title: 'Two words',
        description: 'Body with 👩🏽‍💻.',
        dateTime: DateTime(2026, 10, 7),
        todo: [Todo(id: 'row', title: 'Checklist item')]);
    final repository = await _mount(tester, note, NotePositionStore.memory());
    await tester.tap(find.byTooltip(S.current.More_Options));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text(S.current.Note_Info));
    await tester.tap(find.text(S.current.Note_Info));
    await tester.pumpAndSettle();
    final statistics =
        tester.widget<NoteInfoSheet>(find.byType(NoteInfoSheet)).statistics;
    final expected = NoteStatistics.fromNote(note);
    expect(statistics.wordCount, expected.wordCount);
    expect(statistics.characterCount, expected.characterCount);
    await _capture(tester, 'note-info');
    expect(repository.writes, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'deleted sources expose no mutable selection or resume controller',
      (tester) async {
    final note = Note(
        id: 'deleted-reader',
        title: 'Deleted',
        description: 'Old body',
        deletedAt: DateTime(2026, 10, 7));
    final repository = await _mount(tester, note, NotePositionStore.memory());
    expect(_loaded(tester).onAddSelectionToChecklist, isNull);
    expect(_loaded(tester).onCopySelection, isNull);
    expect(_loaded(tester).readerPositionController, isNull);
    expect(repository.writes, 0);
    expect(tester.takeException(), isNull);
  });
  testWidgets('narrow Chinese reader silently resumes with 2x text',
      (tester) async {
    final text = '${'開場段落，記錄今天的計畫與想法。\n' * 25}'
        '記得保存的位置 👩🏽‍💻\n'
        '${'接下來的段落，留點時間享受沿途的風景。\n' * 30}';
    final note = Note(
        id: 'chinese-reader',
        title: '散步筆記',
        description: text,
        dateTime: DateTime(2026, 10, 7));
    final offset = text.indexOf('記得保存');
    final positions = NotePositionStore.memory();
    await positions.saveReading(
        note.id!, NoteReadingPosition.capture(text: text, offset: offset));
    final repository = await _mount(tester, note, positions,
        size: const Size(280, 844),
        textScale: 2,
        locale: const Locale('zh', 'HK'));
    final part = find.byWidgetPredicate((widget) =>
        widget is FormattedNoteText && widget.text.contains('記得保存'));
    final rect = NoteReaderGlyph.fromContext(tester.element(part))!
        .globalRectForOffset(offset)!;
    final viewport = NoteReaderViewport.fromContext(
        tester.element(find.byType(NoteDocumentView)))!;
    expect(rect.top, closeTo(viewport.bounds.top, 1));
    expect(tester.testTextInput.isVisible, isFalse);
    expect(repository.writes, 0);
    await _capture(tester, 'resume-chinese-2x');
    expect(tester.takeException(), isNull);
  });
}

class _DelayedPositionStorage extends MemoryNotePositionStorage {
  final response = Completer<String?>();
  @override
  Future<String?> read(String key) => response.future;
}
