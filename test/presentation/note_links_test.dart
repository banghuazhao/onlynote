import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/domain/model/voice_memo.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/note_link_picker_sheet.dart';
import 'package:onlynote/presentation/components/note_links_section.dart';
import 'package:onlynote/presentation/theme/theme.dart';

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  Locale locale = const Locale('en'),
  Size size = const Size(390, 844),
  double textScale = 1,
}) async {
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
        disableAnimations: true,
      ),
      child: child!,
    ),
    home: Scaffold(body: child),
  ));
  await tester.pumpAndSettle();
}

Future<void> _openPicker(
  WidgetTester tester,
  List<List<String>?> results, {
  required List<Note> notes,
  List<String> selectedIds = const [],
  Locale locale = const Locale('en'),
  Size size = const Size(390, 844),
  double textScale = 1,
}) async {
  await _pump(
    tester,
    Builder(
      builder: (context) => TextButton(
        onPressed: () async => results.add(await showNoteLinkPickerSheet(
          context,
          currentNoteId: 'current',
          selectedIds: selectedIds,
          notes: notes,
        )),
        child: const Text('Open picker'),
      ),
    ),
    locale: locale,
    size: size,
    textScale: textScale,
  );
  await tester.tap(find.text('Open picker'));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() => initializeDateFormatting());

  testWidgets('picker excludes self and trash but selects archived notes',
      (tester) async {
    final original = ['current', 'missing'];
    final results = <List<String>?>[];
    await _openPicker(tester, results, selectedIds: original, notes: [
      Note(id: 'current', title: 'Current note'),
      Note(id: 'active', title: 'Project ideas'),
      Note(id: 'archived', title: 'Past project', isArchived: true),
      Note(id: 'trash', title: 'Deleted project', deletedAt: DateTime(2026)),
    ]);
    expect(find.text('Current note'), findsNothing);
    expect(find.text('Deleted project'), findsNothing);
    expect(find.text('Project ideas'), findsOneWidget);
    expect(find.text('Past project'), findsOneWidget);
    expect(find.text(S.current.Archive), findsOneWidget);
    expect(find.text(S.current.Link_Unavailable), findsOneWidget);

    await tester.tap(find.byTooltip(S.current.Link_Remove));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('choose-note-link-archived')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('save-note-links')));
    await tester.pumpAndSettle();

    expect(results.single, ['archived']);
    expect(original, ['current', 'missing']);
    expect(tester.takeException(), isNull);
  });

  testWidgets('picker searches tags and transcripts without losing selection',
      (tester) async {
    final results = <List<String>?>[];
    await _openPicker(tester, results, notes: [
      Note(id: 'tagged', title: 'Meeting', tags: ['Budget']),
      Note(id: 'voice', title: 'Recorded idea', voiceMemos: [
        VoiceMemo(
          id: 'memo',
          path: 'note_audio/memo.m4a',
          durationMs: 12000,
          createdAt: DateTime(2026),
          transcript: 'Book the mountain cabin.',
        ),
      ]),
      Note(id: 'other', title: 'Shopping', description: 'Buy bread'),
    ]);
    final search = find.byKey(const ValueKey('note-link-search'));
    await tester.enterText(search, 'budget');
    await tester.pump();
    expect(find.text('Meeting'), findsOneWidget);
    expect(find.text('Recorded idea'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('choose-note-link-tagged')));
    await tester.pump();
    await tester.enterText(search, 'mountain');
    await tester.pump();
    expect(find.text('Recorded idea'), findsOneWidget);
    expect(find.text('Meeting'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('choose-note-link-voice')));
    await tester.pump();
    await tester.enterText(search, 'unmatched');
    await tester.pump();
    expect(find.text(S.current.No_Search_Results), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('save-note-links')));
    await tester.pumpAndSettle();
    expect(results.single, ['tagged', 'voice']);
    expect(tester.takeException(), isNull);
  });

  testWidgets('closing draft link changes returns no saved selection',
      (tester) async {
    final results = <List<String>?>[];
    await _openPicker(tester, results, notes: [Note(id: 'a', title: 'A')]);
    await tester.tap(find.byKey(const ValueKey('choose-note-link-a')));
    await tester.pump();
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();
    expect(results, [null]);
  });

  testWidgets('missing selections remain removable in an empty library',
      (tester) async {
    final results = <List<String>?>[];
    await _openPicker(tester, results,
        selectedIds: ['deleted', 'unknown'],
        notes: [Note(id: 'deleted', deletedAt: DateTime(2026))]);
    expect(find.text(S.current.Link_Unavailable), findsNWidgets(2));
    expect(find.text(S.current.Link_Empty), findsOneWidget);
    final remove = find.byTooltip(S.current.Link_Remove);
    await tester.tap(remove.first);
    await tester.pump();
    await tester.tap(remove.first);
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('save-note-links')));
    await tester.pumpAndSettle();
    expect(results.single, isEmpty);
  });

  testWidgets('link limit still allows removal before adding another note',
      (tester) async {
    final results = <List<String>?>[];
    final selected = [for (var index = 0; index < 100; index++) 'note-$index'];
    await _openPicker(tester, results, selectedIds: selected, notes: [
      Note(id: 'extra', title: 'Extra note'),
      for (var index = 0; index < 100; index++)
        Note(id: 'note-$index', title: 'Note $index'),
    ]);
    final extra = find.byKey(const ValueKey('choose-note-link-extra'));
    expect(tester.widget<CheckboxListTile>(extra).onChanged, isNull);
    expect(find.text(S.current.Link_Limit), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('choose-note-link-note-0')));
    await tester.pump();
    expect(tester.widget<CheckboxListTile>(extra).onChanged, isNotNull);
    await tester.tap(extra);
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('save-note-links')));
    await tester.pumpAndSettle();
    expect(results.single, hasLength(100));
    expect(results.single, contains('extra'));
    expect(results.single, isNot(contains('note-0')));
    expect(selected.first, 'note-0');
  });

  testWidgets('links and backlinks open available notes and allow editing',
      (tester) async {
    final opened = <String>[];
    var edits = 0;
    final target = Note(id: 'target', title: 'Travel plan', isArchived: true);
    final source = Note(id: 'source', title: 'Packing list');
    await _pump(
      tester,
      NoteLinksSection(
        linkedNoteIds: const ['target', 'missing'],
        notes: [target],
        backlinks: [source, source],
        onOpen: (note) => opened.add(note.id!),
        onEdit: () => edits++,
      ),
    );
    expect(find.text(S.current.Linked_Notes), findsOneWidget);
    expect(find.text(S.current.Linked_From), findsOneWidget);
    expect(find.text('Packing list'), findsOneWidget);
    expect(find.text(S.current.Link_Unavailable), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('linked-note-target')));
    await tester.tap(find.byKey(const ValueKey('backlink-note-source')));
    await tester.tap(find.byKey(const ValueKey('linked-note-missing')),
        warnIfMissed: false);
    await tester.tap(find.byKey(const ValueKey('edit-note-links')));
    expect(opened, ['target', 'source']);
    expect(edits, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('export shows relationships without navigation or edit controls',
      (tester) async {
    final opened = <Note>[];
    await _pump(
      tester,
      NoteLinksSection(
        linkedNoteIds: const ['untitled'],
        notes: [Note(id: 'untitled', title: '  ')],
        onOpen: opened.add,
        onEdit: () => fail('Export must not edit links'),
        exportMode: true,
      ),
    );
    expect(find.text(S.current.Note_Untitled), findsOneWidget);
    expect(find.byKey(const ValueKey('edit-note-links')), findsNothing);
    expect(find.byType(InkWell), findsNothing);
    expect(opened, isEmpty);
  });

  testWidgets('narrow Chinese link picker supports large text and Done',
      (tester) async {
    final results = <List<String>?>[];
    await _openPicker(
      tester,
      results,
      notes: [
        Note(id: 'long', title: '這是一份很長的旅行計劃筆記標題', isArchived: true),
      ],
      locale: const Locale('zh', 'HK'),
      size: const Size(320, 640),
      textScale: 2,
    );
    expect(tester.takeException(), isNull);
    await tester.tap(find.byKey(const ValueKey('choose-note-link-long')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('save-note-links')));
    await tester.pumpAndSettle();
    expect(results.single, ['long']);
    expect(tester.takeException(), isNull);
  });

  testWidgets('relationship headings and long titles wrap at large text sizes',
      (tester) async {
    await _pump(
      tester,
      SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: NoteLinksSection(
            linkedNoteIds: const ['a', 'missing'],
            notes: [Note(id: 'a', title: '這是一份很長的旅行計劃筆記標題')],
            backlinks: [Note(id: 'b', title: '相關的旅行筆記')],
            onOpen: (_) {},
            onEdit: () {},
          ),
        ),
      ),
      locale: const Locale('zh', 'HK'),
      size: const Size(320, 640),
      textScale: 2,
    );
    expect(find.byKey(const ValueKey('edit-note-links')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
