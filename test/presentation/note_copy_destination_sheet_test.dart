import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:onlynote/domain/model/note.dart';
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
