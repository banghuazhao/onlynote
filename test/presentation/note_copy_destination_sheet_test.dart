import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/domain/model/voice_memo.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/note_copy_destination_sheet.dart';
import 'package:onlynote/presentation/theme/theme.dart';

Future<void> _openPicker(
  WidgetTester tester,
  List<NoteCopyDestination?> results, {
  List<Note> notes = const [],
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
    home: Scaffold(
      body: Builder(
        builder: (context) => TextButton(
          onPressed: () async {
            results.add(await showNoteCopyDestinationPicker(context,
                notes: notes, sourceNoteId: 'source'));
          },
          child: const Text('Choose destination'),
        ),
      ),
    ),
  ));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Choose destination'));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() => initializeDateFormatting());

  testWidgets('shows eligible previews and returns an existing note choice',
      (tester) async {
    final results = <NoteCopyDestination?>[];
    await _openPicker(tester, results, notes: [
      Note(id: 'source', title: 'Source'),
      Note(id: 'deleted', title: 'Deleted', deletedAt: DateTime(2026, 10, 1)),
      Note(id: 'archived', title: 'Archived', isArchived: true),
      Note(title: 'Unsaved'),
      Note(
          id: 'target',
          title: 'Project plan',
          description: 'Plan a new garden'),
    ]);
    expect(find.text('Project plan'), findsOneWidget);
    expect(find.text('Plan a new garden'), findsOneWidget);
    for (final title in ['Source', 'Deleted', 'Archived', 'Unsaved']) {
      expect(find.text(title), findsNothing);
    }
    expect(results, isEmpty);
    await tester.tap(find.byKey(const ValueKey('note-copy-existing-target')));
    await tester.pumpAndSettle();
    expect(results.single!.noteId, 'target');
    expect(results.single!.isNewNote, isFalse);
    expect(find.byType(NoteCopyDestinationSheet), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('searches destination content while keeping new note available',
      (tester) async {
    final results = <NoteCopyDestination?>[];
    await _openPicker(tester, results, notes: [
      Note(id: 'first', title: 'Project plan', description: 'Garden sketch'),
      Note(id: 'second', title: 'Shopping', description: 'Coffee and tea'),
    ]);
    await tester.enterText(
        find.byKey(const ValueKey('note-copy-search')), 'coffee');
    await tester.pump();
    expect(find.text('Shopping'), findsOneWidget);
    expect(find.text('Project plan'), findsNothing);
    expect(find.byKey(const ValueKey('note-copy-new')), findsOneWidget);
    await tester.enterText(
        find.byKey(const ValueKey('note-copy-search')), 'no matching text');
    await tester.pump();
    expect(find.text(S.current.Copy_Selection_No_Matches), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('note-copy-new')));
    await tester.pumpAndSettle();
    expect(results.single!.isNewNote, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('empty library can create a new note and cancellation is null',
      (tester) async {
    final results = <NoteCopyDestination?>[];
    await _openPicker(tester, results);
    expect(find.text(S.current.Copy_Selection_No_Notes), findsOneWidget);
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();
    expect(results, [null]);
  });

  testWidgets('search previews explain the matching field and preserve choice',
      (tester) async {
    final results = <NoteCopyDestination?>[];
    final prefix = List.filled(50, 'Earlier background. ').join();
    final note = Note(
      id: 'target',
      title: 'Title marker',
      description: '${prefix}Bodyneedle after the background',
      todo: [Todo(id: 'task', title: 'Pack taskneedle', completed: true)],
      tags: ['Tagneedle'],
      voiceMemos: [
        VoiceMemo(
          id: 'private-memo',
          path: 'note_audio/unavailable.m4a',
          durationMs: 1000,
          createdAt: DateTime(2026, 10, 20),
          transcript: '${prefix}Transcriptneedle [tea] 閱讀茶😀',
        ),
      ],
    );
    await _openPicker(tester, results, notes: [
      note,
      Note(id: 'other', title: 'Other destination', description: 'Unrelated'),
    ]);
    final search = find.byKey(const ValueKey('note-copy-search'));
    final snippet = find.byKey(const ValueKey('note-copy-snippet-target'));
    for (final (query, content) in [
      (' bodyneedle ', 'Bodyneedle after the background'),
      ('TASKNEEDLE', 'taskneedle'),
      ('transcriptneedle', 'Transcriptneedle [tea] 閱讀茶😀'),
      ('tagneedle', 'Tagneedle'),
      ('[TEA]', '[tea] 閱讀茶😀'),
    ]) {
      await tester.enterText(search, query);
      await tester.pumpAndSettle();
      expect(tester.widget<Text>(snippet).data,
          startsWith(query == 'tagneedle' ? content : '…$content'));
      expect(
          find.byKey(const ValueKey('note-copy-existing-other')), findsNothing);
      expect(find.byKey(const ValueKey('note-copy-new')), findsOneWidget);
      expect(results, isEmpty);
    }
    await tester.enterText(search, 'Title marker');
    await tester.pumpAndSettle();
    expect(tester.widget<Text>(snippet).data, note.description);
    await tester.enterText(search, '');
    await tester.pumpAndSettle();
    expect(tester.widget<Text>(snippet).data, note.description);
    await tester.enterText(search, '閱讀茶😀');
    await tester.pumpAndSettle();
    expect(tester.widget<Text>(snippet).data, startsWith('…閱讀茶😀'));
    final target = find.byKey(const ValueKey('note-copy-existing-target'));
    await tester.ensureVisible(target);
    await tester.tap(target);
    await tester.pumpAndSettle();
    expect(results.single!.noteId, 'target');
    expect(note.todo.single.completed, isTrue);
    expect(note.voiceMemos.single.path, 'note_audio/unavailable.m4a');
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'filtered transcript destination can be cancelled without a choice',
      (tester) async {
    final results = <NoteCopyDestination?>[];
    await _openPicker(tester, results, notes: [
      Note(id: 'target', voiceMemos: [
        VoiceMemo(
          id: 'memo',
          path: 'note_audio/unavailable.m4a',
          durationMs: 1000,
          createdAt: DateTime(2026, 10, 20),
          transcript: 'Confirm reservation',
        ),
      ]),
    ]);
    await tester.enterText(
        find.byKey(const ValueKey('note-copy-search')), 'reservation');
    await tester.pumpAndSettle();
    expect(find.text('…reservation'), findsOneWidget);
    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    expect(results, [null]);
    expect(find.text('Choose destination'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('narrow large-text Chinese picker remains usable',
      (tester) async {
    final results = <NoteCopyDestination?>[];
    await _openPicker(
      tester,
      results,
      notes: [Note(id: 'target', title: '旅行計劃', description: '週末旅行行程')],
      locale: const Locale('zh', 'HK'),
      size: const Size(320, 640),
      textScale: 2,
    );
    expect(tester.takeException(), isNull);
    final choice = find.byKey(const ValueKey('note-copy-existing-target'));
    await tester.ensureVisible(choice);
    await tester.tap(choice);
    await tester.pumpAndSettle();
    expect(results.single!.noteId, 'target');
    expect(tester.takeException(), isNull);
  });
}
