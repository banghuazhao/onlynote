import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:onlynote/Tools/app_typography_settings.dart';
import 'package:onlynote/Tools/locator.dart';
import 'package:onlynote/data/dto/note_dto.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/domain/model/note_section_link.dart';
import 'package:onlynote/domain/model/note_text_style.dart';
import 'package:onlynote/domain/repository/note_repository.dart';
import 'package:onlynote/domain/usecase/get_note_usecase.dart';
import 'package:onlynote/domain/usecase/update_note_usecase.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/formatted_note_text.dart';
import 'package:onlynote/presentation/components/note_document_view.dart';
import 'package:onlynote/presentation/components/note_reader_position_controller.dart';
import 'package:onlynote/presentation/components/note_section_link_picker_sheet.dart';
import 'package:onlynote/presentation/components/note_section_links_section.dart';
import 'package:onlynote/presentation/components/note_section_links_previews.dart';
import 'package:onlynote/presentation/routes/routes.dart';
import 'package:onlynote/presentation/screens/note_detail/bloc/detail/note_detail_bloc.dart';
import 'package:onlynote/presentation/screens/note_detail/note_detail_screen.dart';
import 'package:onlynote/presentation/theme/theme.dart';
import 'package:onlynote/services/note_autosave.dart';
import 'package:onlynote/services/note_position_store.dart';
import 'package:onlynote/services/note_selection_transfer.dart';

Note _headingNote(String id, String title, String heading,
        {bool archived = false, DateTime? deletedAt}) =>
    Note(
        id: id,
        title: title,
        description: '$heading\nBody',
        isArchived: archived,
        deletedAt: deletedAt,
        textStyles: [
          NoteTextStyleRange(
              start: 0,
              end: heading.length,
              kind: NoteTextStyleKind.heading,
              anchorId: '$id-heading')
        ]);

Future<void> _pump(WidgetTester tester, Widget child,
    {Size size = const Size(390, 844),
    double textScale = 1,
    Locale locale = const Locale('en'),
    bool disableAnimations = true}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(MaterialApp(
    locale: locale,
    supportedLocales: S.delegate.supportedLocales,
    localizationsDelegates: const [
      S.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    theme: AppTheme.light,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(textScale),
          disableAnimations: disableAnimations),
      child: child!,
    ),
    home: Scaffold(body: child),
  ));
  await tester.pumpAndSettle();
}

Future<void> _openPicker(
    WidgetTester tester, List<NoteSectionLinkSelection?> results,
    {List<Note>? notes,
    Size size = const Size(390, 844),
    double textScale = 1,
    Locale locale = const Locale('en')}) async {
  await _pump(
      tester,
      Builder(
          builder: (context) => TextButton(
              onPressed: () async =>
                  results.add(await showNoteSectionLinkPickerSheet(context,
                      notes: notes ??
                          [
                            _headingNote('self', 'Current note', 'Plan'),
                            _headingNote('other', 'Project', 'Budget'),
                          ],
                      currentNoteId: 'self')),
              child: const Text('Open picker'))),
      size: size,
      textScale: textScale,
      locale: locale,
      disableAnimations: false);
  await tester.tap(find.text('Open picker'));
  await tester.pumpAndSettle();
}

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
  @override
  Future<void> writeDraft(Note note) async {}
  @override
  Future<void> removeDraft(String id) async {}
  @override
  Future<void> saveNote(Note note) =>
      notes.addUpdateNote(NoteDto.fromNote(note));
}

class _Router extends RootStackRouter {
  _Router(this.note, this.positions, this.transfer, this.headingId);
  final Note note;
  final NotePositionStore positions;
  final NoteSelectionTransfer transfer;
  final String headingId;
  @override
  List<AutoRoute> get routes => [
        AutoRoute(
          initial: true,
          page: PageInfo('SectionJumpTestRoute',
              builder: (_) => NoteDetailScreen(
                  noteId: note.id!,
                  positionStore: positions,
                  initialHeadingId: headingId,
                  selectionTransfer: transfer)),
        )
      ];
}

Future<_Notes> _mountReader(WidgetTester tester, Note note,
    NotePositionStore positions, String headingId) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final notes = _Notes(note);
  final transfer = NoteSelectionTransfer(
      repository: notes, store: _AutosaveStore(notes), readDraft: (_) => null);
  final detail =
      NoteDetailBloc(GetNoteUsecase(notes), UpdateNoteUsecase(notes));
  final router = _Router(note, positions, transfer, headingId);
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    router.dispose();
    await detail.close();
  });
  await tester.pumpWidget(BlocProvider.value(
    value: detail,
    child: MaterialApp.router(
      routerConfig: router.config(),
      theme: AppTheme.light,
      builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: child!),
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: S.delegate.supportedLocales,
    ),
  ));
  await tester.pumpAndSettle();
  return notes;
}

void main() {
  final fonts = Map<String, GoogleFontBuilder>.of(kAppFontFamilies);
  setUpAll(() async {
    await initializeDateFormatting();
    if (!locator.isRegistered<S>()) locator.registerSingleton(S());
  });
  setUp(() {
    for (final family in fonts.keys) {
      kAppFontFamilies[family] = (
              {textStyle, color, fontSize, fontWeight, fontStyle}) =>
          (textStyle ?? const TextStyle()).copyWith(
              color: color,
              fontSize: fontSize,
              fontWeight: fontWeight,
              fontStyle: fontStyle);
    }
  });
  tearDown(() => kAppFontFamilies.addAll(fonts));

  testWidgets('picker includes same-note and archived headings, excludes trash',
      (tester) async {
    final results = <NoteSectionLinkSelection?>[];
    await _openPicker(tester, results, notes: [
      _headingNote('self', 'Current note', 'Plan'),
      _headingNote('archive', 'Archived project', 'Budget', archived: true),
      _headingNote('trash', 'Deleted project', 'Removed',
          deletedAt: DateTime(2026)),
      Note(id: 'plain', title: 'Plain note', description: 'No heading'),
    ]);
    expect(find.text('Plan'), findsOneWidget);
    expect(find.text('Budget'), findsOneWidget);
    expect(find.text('Removed'), findsNothing);
    expect(find.text('No heading'), findsNothing);
    await tester.enterText(
        find.byKey(const ValueKey('section-link-search')), 'archived');
    await tester.pumpAndSettle();
    expect(find.text('Plan'), findsNothing);
    expect(find.text('Budget'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('section-choice-archive-0')));
    await tester.pumpAndSettle();
    expect(results.single?.noteId, 'archive');
    expect(results.single?.heading.anchorId, 'archive-heading');
    expect(tester.takeException(), isNull);
  });

  testWidgets('choosing a heading finishes once and stale callbacks are inert',
      (tester) async {
    final results = <NoteSectionLinkSelection?>[];
    await _openPicker(tester, results);
    final choose = tester
        .widget<ListTile>(find.byKey(const ValueKey('section-choice-self-0')))
        .onTap!;
    choose();
    choose();
    await tester.pumpAndSettle();
    choose();
    expect(results.length, 1);
    expect(results.single?.noteId, 'self');
    expect(find.text('Open picker'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('covered and cancelled sheets reject choose and clear callbacks',
      (tester) async {
    final results = <NoteSectionLinkSelection?>[];
    await _openPicker(tester, results);
    final search = find.byKey(const ValueKey('section-link-search'));
    await tester.enterText(search, 'Plan');
    await tester.pumpAndSettle();
    final choose = tester
        .widget<ListTile>(find.byKey(const ValueKey('section-choice-self-0')))
        .onTap!;
    final clear = tester
        .widget<IconButton>(find.byWidgetPredicate((widget) =>
            widget is IconButton && widget.tooltip == S.current.Clear_Search))
        .onPressed!;
    final sheet = tester.element(find.byType(NoteSectionLinkPickerSheet));
    showDialog<void>(
        context: sheet,
        builder: (_) => const AlertDialog(content: Text('Covered')));
    await tester.pumpAndSettle();
    choose();
    clear();
    expect(tester.widget<TextField>(search).controller!.text, 'Plan');
    expect(results, isEmpty);
    Navigator.pop(tester.element(find.text('Covered')));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Close'));
    choose();
    clear();
    await tester.pumpAndSettle();
    choose();
    clear();
    expect(results, [null]);
    expect(find.text('Open picker'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('section rows use renamed headings and retain unavailable labels',
      (tester) async {
    const link = NoteSectionLink(
        noteId: 'target', headingId: 'target-heading', headingText: 'Old name');
    const missing = NoteSectionLink(
        noteId: 'gone',
        headingId: 'gone-heading',
        headingText: 'Original label');
    final opened = <NoteSectionLink>[];
    final removed = <NoteSectionLink>[];
    await _pump(
        tester,
        NoteSectionLinksSection(
            links: const [link, missing],
            notes: [_headingNote('target', 'Project', 'Renamed section')],
            onOpen: opened.add,
            onRemove: removed.add));
    expect(find.text('Renamed section'), findsOneWidget);
    expect(find.text('Old name'), findsNothing);
    expect(find.text('Original label'), findsOneWidget);
    expect(find.text(S.current.Section_Link_Unavailable), findsOneWidget);
    final available =
        find.byKey(const ValueKey('section-link-target-target-heading'));
    final unavailable =
        find.byKey(const ValueKey('section-link-gone-gone-heading'));
    expect(tester.widget<ListTile>(unavailable).onTap, isNull);
    await tester.tap(available);
    expect(opened, [link]);
    await tester.tap(find.descendant(
        of: unavailable,
        matching: find.byTooltip(S.current.Section_Link_Remove)));
    expect(removed, [missing]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('picker remains usable at large text in a short window',
      (tester) async {
    final results = <NoteSectionLinkSelection?>[];
    await _openPicker(tester, results,
        size: const Size(320, 320),
        textScale: 2,
        locale: const Locale('zh', 'HK'));
    expect(tester.takeException(), isNull);
    final search = find.byKey(const ValueKey('section-link-search'));
    await tester.enterText(search, 'Budget');
    await tester.pumpAndSettle();
    final choice = find.byKey(const ValueKey('section-choice-other-0'));
    await tester.ensureVisible(choice);
    await tester.tap(choice);
    await tester.pumpAndSettle();
    expect(results.single?.noteId, 'other');
    expect(tester.takeException(), isNull);
  });

  testWidgets('section link previews render light, dark and large text states',
      (tester) async {
    final previews = <(Size, Widget Function())>[
      (const Size(390, 650), noteSectionLinksPreview),
      (const Size(390, 650), noteSectionLinksDarkPreview),
      (const Size(280, 650), noteSectionLinksLargeTextPreview),
      (const Size(390, 650), noteSectionLinkPickerPreview),
      (const Size(390, 650), noteSectionLinkPickerDarkPreview),
      (const Size(320, 360), noteSectionLinkPickerLargeTextPreview),
    ];
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final (size, preview) in previews) {
      tester.view.physicalSize = size;
      await tester.pumpWidget(preview());
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull,
          reason: 'Section link preview at $size');
    }
  });

  testWidgets('heading route jumps override a saved reading position',
      (tester) async {
    final prefix = 'Opening details.\n' * 45;
    const heading = 'Linked destination';
    final body = '$prefix$heading\n${'Following details.\n' * 70}';
    final note = Note(
        id: 'reader-note',
        title: 'Reading project',
        description: body,
        textStyles: [
          NoteTextStyleRange(
              start: prefix.length,
              end: prefix.length + heading.length,
              kind: NoteTextStyleKind.heading,
              anchorId: 'destination')
        ]);
    final positions = NotePositionStore.memory();
    await positions.saveReading(note.id!,
        NoteReadingPosition.capture(text: body, offset: body.length - 20));
    final repository =
        await _mountReader(tester, note, positions, 'destination');
    final view = tester.widget<LoadedView>(find.byType(LoadedView));
    expect(view.scrollController!.offset, greaterThan(0));
    final headingText = find.byWidgetPredicate(
        (widget) => widget is FormattedNoteText && widget.text == heading);
    final glyph = NoteReaderGlyph.fromContext(tester.element(headingText))!;
    final viewport = NoteReaderViewport.fromContext(
        tester.element(find.byType(NoteDocumentView)))!;
    expect(viewport.bounds.overlaps(glyph.globalBounds), isTrue);
    await tester.pump(const Duration(milliseconds: 400));
    expect(viewport.bounds.overlaps(glyph.globalBounds), isTrue);
    expect(repository.writes, 0);
    expect(tester.testTextInput.isVisible, isFalse);
    expect(tester.takeException(), isNull);
  });
}
