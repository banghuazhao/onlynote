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
  bool disableAnimations = true,
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
        disableAnimations: disableAnimations,
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
  bool disableAnimations = true,
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
    disableAnimations: disableAnimations,
  );
  await tester.tap(find.text('Open picker'));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() => initializeDateFormatting());

  testWidgets(
      'Done finishes once and rejects captured link changes during exit',
      (tester) async {
    final results = <List<String>?>[];
    final original = ['target'];
    await _openPicker(tester, results,
        notes: [Note(id: 'target', title: 'Target')],
        selectedIds: original,
        disableAnimations: false);
    final change = tester
        .widget<CheckboxListTile>(
            find.byKey(const ValueKey('choose-note-link-target')))
        .onChanged!;
    final save = tester
        .widget<FilledButton>(find.byKey(const ValueKey('save-note-links')))
        .onPressed!;
    save();
    change(false);
    save();
    await tester.pumpAndSettle();
    save();
    change(false);
    expect(results, [
      ['target']
    ]);
    expect(original, ['target']);
    expect(find.text('Open picker'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'covered and cancelled link sheets reject captured Done and clear',
      (tester) async {
    final results = <List<String>?>[];
    await _openPicker(tester, results,
        notes: [Note(id: 'target', title: 'Target')],
        selectedIds: ['target'],
        disableAnimations: false);
    final search = find.byKey(const ValueKey('note-link-search'));
    await tester.enterText(search, 'Target');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    final save = tester
        .widget<FilledButton>(find.byKey(const ValueKey('save-note-links')))
        .onPressed!;
    final clear = tester
        .widget<IconButton>(find.byWidgetPredicate((widget) =>
            widget is IconButton && widget.tooltip == S.current.Clear_Search))
        .onPressed!;
    final sheetContext = tester.element(find.byType(NoteLinkPickerSheet));
    showDialog<void>(
        context: sheetContext,
        builder: (_) => const AlertDialog(content: Text('Covered')));
    await tester.pumpAndSettle();
    save();
    clear();
    expect(tester.widget<TextField>(search).controller!.text, 'Target');
    expect(results, isEmpty);
    Navigator.pop(tester.element(find.text('Covered')));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Close'));
    save();
    clear();
    await tester.pumpAndSettle();
    save();
    clear();
    expect(results, [null]);
    expect(find.text('Open picker'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

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
    expect(find.text(S.current.Link_Selected_Count(0)), findsOneWidget);
    expect(find.byKey(const ValueKey('note-link-hidden-selection-count')),
        findsNothing);
    await tester.enterText(search, 'budget');
    await tester.pump();
    expect(find.text('Meeting'), findsOneWidget);
    expect(find.text('Recorded idea'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('choose-note-link-tagged')));
    await tester.pump();
    expect(find.text(S.current.Link_Selected_Count(1)), findsOneWidget);
    expect(find.byKey(const ValueKey('note-link-hidden-selection-count')),
        findsNothing);
    await tester.enterText(search, 'mountain');
    await tester.pump();
    expect(find.text('Recorded idea'), findsOneWidget);
    expect(find.text('…mountain cabin.'), findsOneWidget);
    expect(find.text('Meeting'), findsNothing);
    expect(find.text(S.current.Link_Hidden_By_Search_Count(1)), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('choose-note-link-voice')));
    await tester.pump();
    expect(find.text(S.current.Link_Selected_Count(2)), findsOneWidget);
    await tester.enterText(search, 'unmatched');
    await tester.pump();
    expect(find.text(S.current.No_Search_Results), findsOneWidget);
    expect(find.text(S.current.Link_Hidden_By_Search_Count(2)), findsOneWidget);
    final clearSearch = find.descendant(
      of: search,
      matching: find.byType(IconButton),
    );
    await tester.tap(clearSearch);
    await tester.pump();
    expect(find.byKey(const ValueKey('note-link-hidden-selection-count')),
        findsNothing);
    expect(find.text(S.current.Link_Selected_Count(2)), findsOneWidget);
    expect(
        tester
            .widget<CheckboxListTile>(
                find.byKey(const ValueKey('choose-note-link-tagged')))
            .value,
        isTrue);
    expect(
        tester
            .widget<CheckboxListTile>(
                find.byKey(const ValueKey('choose-note-link-voice')))
            .value,
        isTrue);
    await tester.tap(find.byKey(const ValueKey('save-note-links')));
    await tester.pumpAndSettle();
    expect(results.single, ['tagged', 'voice']);
    expect(tester.takeException(), isNull);
  });

  testWidgets('content snippets distinguish identical and untitled notes',
      (tester) async {
    final results = <List<String>?>[];
    await _openPicker(tester, results, notes: [
      Note(id: 'coast', title: 'Trip', description: 'Visit the coast'),
      Note(
        id: 'mountain',
        title: 'Trip',
        description: 'Hike the mountain',
        isArchived: true,
      ),
      Note(id: 'untitled', todo: [Todo(title: 'Pack the tent')]),
    ]);
    expect(find.text('Trip'), findsNWidgets(2));
    for (final (id, content) in [
      ('coast', 'Visit the coast'),
      ('mountain', 'Hike the mountain'),
      ('untitled', 'Pack the tent'),
    ]) {
      final snippet = find.byKey(ValueKey('note-link-snippet-$id'));
      await tester.ensureVisible(snippet);
      await tester.pumpAndSettle();
      expect(tester.widget<Text>(snippet).data, content);
      expect(tester.widget<Text>(snippet).maxLines, 2);
      expect(tester.widget<Text>(snippet).overflow, TextOverflow.ellipsis);
    }
    expect(find.text(S.current.Note_Untitled), findsOneWidget);
    expect(find.text(S.current.Archive), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('choose-note-link-untitled')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('save-note-links')));
    await tester.pumpAndSettle();
    expect(results.single, ['untitled']);
    expect(tester.takeException(), isNull);
  });

  testWidgets('search reveals matching content without changing draft links',
      (tester) async {
    final results = <List<String>?>[];
    final prefix = List.filled(80, 'Earlier text ').join();
    await _openPicker(tester, results, selectedIds: [
      'context'
    ], notes: [
      Note(
        id: 'context',
        title: 'Travel',
        description: '${prefix}Coastal walk',
        todo: [Todo(title: 'Buy [tea]')],
        voiceMemos: [
          VoiceMemo(
            id: 'memo',
            path: 'note_audio/missing.m4a',
            durationMs: 0,
            createdAt: DateTime(2026),
            transcript: '${prefix}Mountain cabin',
          ),
        ],
      ),
      Note(id: 'other', title: 'Other note'),
    ]);
    final search = find.byKey(const ValueKey('note-link-search'));
    for (final (query, expected) in [
      ('coastal', 'Coastal walk'),
      ('[TEA]', '[tea]'),
      ('mountain', 'Mountain cabin'),
    ]) {
      await tester.enterText(search, query);
      await tester.pump();
      final snippet = find.byKey(const ValueKey('note-link-snippet-context'));
      expect(tester.widget<Text>(snippet).data, contains(expected));
      expect(
          find.byKey(const ValueKey('choose-note-link-other')), findsNothing);
      expect(
        tester
            .widget<CheckboxListTile>(
                find.byKey(const ValueKey('choose-note-link-context')))
            .value,
        isTrue,
      );
    }
    await tester.tap(find.byKey(const ValueKey('save-note-links')));
    await tester.pumpAndSettle();
    expect(results.single, ['context']);
    expect(tester.takeException(), isNull);
  });

  testWidgets('closing draft link changes returns no saved selection',
      (tester) async {
    final results = <List<String>?>[];
    await _openPicker(tester, results, notes: [Note(id: 'a', title: 'A')]);
    await tester.tap(find.byKey(const ValueKey('choose-note-link-a')));
    await tester.pump();
    expect(find.text(S.current.Link_Selected_Count(1)), findsOneWidget);
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
    expect(find.text(S.current.Link_Selected_Count(2)), findsOneWidget);
    final remove = find.byTooltip(S.current.Link_Remove);
    await tester.tap(remove.first);
    await tester.pump();
    expect(find.text(S.current.Link_Selected_Count(1)), findsOneWidget);
    await tester.tap(remove.first);
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('save-note-links')));
    await tester.pumpAndSettle();
    expect(results.single, isEmpty);
  });

  testWidgets(
      'hidden feedback excludes unavailable selections and normalizes IDs',
      (tester) async {
    final results = <List<String>?>[];
    final selectedIds = ['current', 'a', 'a', 'b', 'missing', 'deleted'];
    await _openPicker(tester, results, selectedIds: selectedIds, notes: [
      Note(id: 'current', title: 'Current note'),
      Note(id: 'a', title: 'Alpha'),
      Note(id: 'b', title: 'Beta', isArchived: true),
      Note(id: 'b', title: 'Beta', isArchived: true),
      Note(id: 'deleted', title: 'Deleted note', deletedAt: DateTime(2026)),
    ]);
    expect(find.text(S.current.Link_Selected_Count(4)), findsOneWidget);
    await tester.enterText(
        find.byKey(const ValueKey('note-link-search')), 'alpha');
    await tester.pump();
    expect(find.text(S.current.Link_Hidden_By_Search_Count(1)), findsOneWidget);
    expect(find.text(S.current.Link_Unavailable), findsNWidgets(2));
    expect(find.text('Alpha'), findsOneWidget);
    expect(find.text('Beta'), findsNothing);
    await tester.tap(find.descendant(
      of: find.byKey(const ValueKey('remove-unavailable-link-missing')),
      matching: find.byType(IconButton),
    ));
    await tester.pump();
    expect(find.text(S.current.Link_Selected_Count(3)), findsOneWidget);
    expect(find.text(S.current.Link_Hidden_By_Search_Count(1)), findsOneWidget);
    await tester.enterText(
        find.byKey(const ValueKey('note-link-search')), '   ');
    await tester.pump();
    expect(find.byKey(const ValueKey('note-link-hidden-selection-count')),
        findsNothing);
    await tester.tap(find.byKey(const ValueKey('save-note-links')));
    await tester.pumpAndSettle();
    expect(results.single, ['a', 'b', 'deleted']);
    expect(selectedIds, ['current', 'a', 'a', 'b', 'missing', 'deleted']);
    expect(tester.takeException(), isNull);
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
    expect(find.text(S.current.Link_Selected_Count(100)), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('choose-note-link-note-0')));
    await tester.pump();
    expect(tester.widget<CheckboxListTile>(extra).onChanged, isNotNull);
    expect(find.text(S.current.Link_Selected_Count(99)), findsOneWidget);
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
        notes: [
          Note(
              id: 'untitled',
              title: '  ',
              description: 'Private linked body',
              isArchived: true)
        ],
        backlinks: [
          Note(
              id: 'source',
              title: 'Source',
              todo: [Todo(title: 'Private incoming task')])
        ],
        onOpen: opened.add,
        onEdit: () => fail('Export must not edit links'),
        exportMode: true,
      ),
    );
    expect(find.text(S.current.Note_Untitled), findsOneWidget);
    expect(find.byKey(const ValueKey('edit-note-links')), findsNothing);
    expect(find.byType(InkWell), findsNothing);
    expect(find.byKey(const ValueKey('linked-note-untitled-snippet')),
        findsNothing);
    expect(find.byKey(const ValueKey('backlink-note-source-snippet')),
        findsNothing);
    expect(find.text('Private linked body'), findsNothing);
    expect(find.text('Private incoming task'), findsNothing);
    expect(find.text(S.current.Archive), findsOneWidget);
    expect(opened, isEmpty);
  });

  testWidgets(
      'relationship excerpts retain order, identities and unavailable privacy',
      (tester) async {
    final body = Note(
        id: 'body',
        title: 'Trip',
        description: '  Visit\n the   coast ',
        isArchived: true);
    final task = Note(
        id: 'task',
        title: 'Trip',
        todo: [Todo(title: 'Pack 茶😀 and chargers')]);
    final voice = Note(id: 'voice', title: 'Trip', voiceMemos: [
      VoiceMemo(
          id: 'memo',
          path: 'note_audio/unavailable.m4a',
          durationMs: 1000,
          createdAt: DateTime(2026),
          transcript: 'Confirm the cabin reservation')
    ]);
    final blank =
        Note(id: 'blank', title: 'Blank', description: ' \t\n', todo: [
      Todo(title: null),
      Todo(title: ' ')
    ], voiceMemos: [
      VoiceMemo(
          id: 'empty',
          path: 'note_audio/unavailable-empty.m4a',
          durationMs: 0,
          createdAt: DateTime(2026),
          transcript: '\t')
    ]);
    final deleted = Note(
        id: 'deleted',
        title: 'Deleted private title',
        description: 'Deleted private content',
        deletedAt: DateTime(2026));
    final firstIncoming = Note(
        id: 'source',
        title: 'Older incoming',
        description: 'Older private content');
    final incoming = Note(
        id: 'source', title: 'Incoming', description: 'Latest incoming body');
    final opened = <Note>[];
    var edits = 0;
    await _pump(
        tester,
        SingleChildScrollView(
            child: NoteLinksSection(
          linkedNoteIds: const [
            'body',
            'body',
            'task',
            'voice',
            'blank',
            'missing',
            'deleted'
          ],
          notes: [
            body,
            body.copyWith(description: 'Later duplicate content'),
            task,
            voice,
            blank,
            deleted
          ],
          backlinks: [firstIncoming, incoming, deleted],
          onOpen: opened.add,
          onEdit: () => edits++,
        )));
    for (final (key, content) in [
      ('linked-note-body', 'Visit the coast'),
      ('linked-note-task', 'Pack 茶😀 and chargers'),
      ('linked-note-voice', 'Confirm the cabin reservation'),
      ('backlink-note-source', 'Latest incoming body'),
    ]) {
      final snippet = find.byKey(ValueKey('$key-snippet'));
      expect(tester.widget<Text>(snippet).data, content);
      expect(tester.widget<Text>(snippet).maxLines, 2);
      expect(tester.widget<Text>(snippet).overflow, TextOverflow.ellipsis);
      final row = find.byKey(ValueKey(key));
      await tester.ensureVisible(row);
      await tester.pumpAndSettle();
      await tester.tap(row);
    }
    expect(opened, [body, task, voice, incoming]);
    for (var index = 0; index < opened.length; index++) {
      expect(opened[index], same([body, task, voice, incoming][index]));
    }
    expect(find.byKey(const ValueKey('linked-note-body')), findsOneWidget);
    expect(find.byKey(const ValueKey('backlink-note-source')), findsOneWidget);
    expect(find.text('Older incoming'), findsNothing);
    expect(find.text('Later duplicate content'), findsNothing);
    expect(find.text('Deleted private title'), findsNothing);
    expect(find.text('Deleted private content'), findsNothing);
    expect(find.byKey(const ValueKey('backlink-note-deleted')), findsNothing);
    for (final id in ['blank', 'missing', 'deleted']) {
      expect(find.byKey(ValueKey('linked-note-$id-snippet')), findsNothing);
    }
    expect(find.text(S.current.Link_Unavailable), findsNWidgets(2));
    expect(find.text(S.current.Archive), findsOneWidget);
    expect(
        tester.getTopLeft(find.byKey(const ValueKey('linked-note-body'))).dy,
        lessThan(tester
            .getTopLeft(find.byKey(const ValueKey('linked-note-task')))
            .dy));
    await tester.ensureVisible(find.byKey(const ValueKey('edit-note-links')));
    await tester.tap(find.byKey(const ValueKey('edit-note-links')));
    expect(edits, 1);
    expect(body.description, '  Visit\n the   coast ');
    expect(voice.voiceMemos.single.path, 'note_audio/unavailable.m4a');
    expect(tester.takeException(), isNull);
  });

  testWidgets('read-only relationships retain bounded whole-grapheme snippets',
      (tester) async {
    const family = '👨‍👩‍👧‍👦';
    final prefix = List.filled(159, '茶').join();
    final note =
        Note(id: 'unicode', title: '閱讀筆記', description: '$prefix${family}more');
    final semantics = tester.ensureSemantics();
    try {
      await _pump(
          tester,
          SingleChildScrollView(
              child: NoteLinksSection(
            linkedNoteIds: const ['unicode'],
            notes: [note],
            backlinks: [note],
          )),
          locale: const Locale('zh', 'HK'),
          size: const Size(280, 700),
          textScale: 2);
      for (final key in ['linked-note-unicode', 'backlink-note-unicode']) {
        final row = find.byKey(ValueKey(key));
        final snippet = find.byKey(ValueKey('$key-snippet'));
        expect(tester.widget<Text>(snippet).data, '$prefix$family…');
        expect(tester.widget<Text>(snippet).data, isNot(contains('\ufffd')));
        await tester.ensureVisible(row);
        await tester.pumpAndSettle();
        expect(
            tester
                .getSemantics(row)
                .getSemanticsData()
                .flagsCollection
                .isButton,
            isFalse);
        final bounds = tester.getRect(snippet);
        expect(bounds.left, greaterThanOrEqualTo(0));
        expect(bounds.right, lessThanOrEqualTo(280));
      }
      expect(find.byType(InkWell), findsNothing);
      expect(find.byKey(const ValueKey('edit-note-links')), findsNothing);
      expect(tester.takeException(), isNull);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('narrow Chinese link picker supports large text and Done',
      (tester) async {
    final results = <List<String>?>[];
    await _openPicker(
      tester,
      results,
      notes: [
        Note(id: 'hidden', title: '另一份筆記'),
        Note(
          id: 'long',
          title: '這是一份很長的旅行計劃筆記標題',
          description: '帶著家人👨‍👩‍👧‍👦一起旅行，出發前先安排住宿、交通和每天的行程。',
          isArchived: true,
        ),
      ],
      selectedIds: const ['hidden', 'unavailable'],
      locale: const Locale('zh', 'HK'),
      size: const Size(320, 640),
      textScale: 2,
    );
    await tester.enterText(
        find.byKey(const ValueKey('note-link-search')), '旅行');
    await tester.pump();
    expect(find.text(S.current.Link_Selected_Count(2)), findsOneWidget);
    expect(find.text(S.current.Link_Hidden_By_Search_Count(1)), findsOneWidget);
    expect(
        find.byKey(const ValueKey('note-link-snippet-long')), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester
        .ensureVisible(find.byKey(const ValueKey('choose-note-link-long')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('choose-note-link-long')).hitTestable(),
        findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('choose-note-link-long')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('save-note-links')));
    await tester.pumpAndSettle();
    expect(results.single, ['hidden', 'unavailable', 'long']);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'selection feedback can scroll with keyboard open on narrow screen',
      (tester) async {
    final results = <List<String>?>[];
    await _openPicker(
      tester,
      results,
      notes: [
        Note(id: 'hidden', title: 'Another note'),
        Note(id: 'visible', title: 'Visible note'),
      ],
      selectedIds: const ['hidden', 'missing'],
      size: const Size(320, 640),
      textScale: 2,
    );
    tester.view.viewInsets = const FakeViewPadding(bottom: 240);
    addTearDown(tester.view.resetViewInsets);
    await tester.enterText(
        find.byKey(const ValueKey('note-link-search')), 'visible');
    await tester.pumpAndSettle();
    expect(find.text(S.current.Link_Selected_Count(2)), findsOneWidget);
    expect(find.text(S.current.Link_Hidden_By_Search_Count(1)), findsOneWidget);
    expect(tester.takeException(), isNull);
    final list = find.byKey(const ValueKey('note-link-results'));
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('choose-note-link-visible')),
      80,
      scrollable: find.descendant(of: list, matching: find.byType(Scrollable)),
      maxScrolls: 10,
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('choose-note-link-visible')).hitTestable(),
        findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('choose-note-link-visible')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('save-note-links')));
    await tester.pumpAndSettle();
    expect(results.single, ['hidden', 'missing', 'visible']);
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
