import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/domain/model/note_image_layout.dart';
import 'package:onlynote/domain/model/voice_memo.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/note_info_previews.dart';
import 'package:onlynote/presentation/components/note_info_sheet.dart';
import 'package:onlynote/services/note_statistics.dart';

Widget _host(Widget child,
        {Locale locale = const Locale('en'), bool use24HourFormat = false}) =>
    MaterialApp(
      locale: locale,
      supportedLocales: S.delegate.supportedLocales,
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(alwaysUse24HourFormat: use24HourFormat),
        child: child!,
      ),
      home: Scaffold(body: child),
    );

VoiceMemo _memo(String id, int durationMs) => VoiceMemo(
      id: id,
      path: 'note_audio/$id.m4a',
      durationMs: durationMs,
      createdAt: DateTime(2026, 10, 7),
    );

void main() {
  testWidgets('resolved folder name has a localized label and semantics',
      (tester) async {
    final semantics = tester.ensureSemantics();
    try {
      await tester.pumpWidget(_host(NoteInfoSheet(
        statistics: NoteStatistics.fromNote(Note()),
        folderName: '  Travel plans  ',
      )));
      await tester.pumpAndSettle();
      expect(
          tester
              .widget<Text>(
                  find.byKey(const ValueKey('note-info-folder-value')))
              .data,
          'Travel plans');
      expect(find.text(S.current.Note_Info_Folder), findsOneWidget);
      expect(
          find.bySemanticsLabel('${S.current.Note_Info_Folder}: Travel plans'),
          findsOneWidget);
      expect(tester.takeException(), isNull);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('unresolved or blank folder metadata omits the optional row',
      (tester) async {
    for (final folderName in [null, '', ' \t\n ']) {
      await tester.pumpWidget(_host(NoteInfoSheet(
        statistics: NoteStatistics.fromNote(Note()),
        folderName: folderName,
      )));
      await tester.pumpAndSettle();
      expect(
          find.byKey(const ValueKey('note-info-folder-value')), findsNothing);
      expect(find.text(S.current.Note_Info_Folder), findsNothing);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('long folder name previews fit regular and Chinese 2x layouts',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    for (final (preview, size) in [
      (noteInfoLongFolderPreview, const Size(390, 620)),
      (noteInfoChineseLongFolderPreview, const Size(280, 700)),
    ]) {
      tester.view.physicalSize = size;
      await tester.pumpWidget(preview());
      await tester.pumpAndSettle();
      expect(
          find.byKey(const ValueKey('note-info-folder-value')), findsOneWidget);
      await tester.ensureVisible(
          find.byKey(const ValueKey('note-info-recording-duration-value')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
  });

  for (final locale in [
    const Locale('en'),
    const Locale('zh'),
    const Locale('zh', 'HK'),
  ]) {
    for (final use24HourFormat in [false, true]) {
      testWidgets(
          'last modified respects $locale and 24-hour=$use24HourFormat with semantics',
          (tester) async {
        final modified = DateTime.utc(2020, 1, 2, 14, 45);
        final semantics = tester.ensureSemantics();
        try {
          await tester.pumpWidget(_host(
            NoteInfoSheet(
              statistics: NoteStatistics.fromNote(Note(title: 'Old plan')),
              modifiedAt: modified,
            ),
            locale: locale,
            use24HourFormat: use24HourFormat,
          ));
          await tester.pumpAndSettle();
          final formatter = DateFormat.yMMMd(locale.toString());
          if (use24HourFormat) {
            formatter.add_Hm();
          } else {
            formatter.add_jm();
          }
          final expected = formatter.format(modified.toLocal());
          final value =
              find.byKey(const ValueKey('note-info-last-modified-value'));
          expect(tester.widget<Text>(value).data, expected);
          expect(find.text(S.current.Note_Info_Last_Modified), findsOneWidget);
          expect(
              find.bySemanticsLabel(
                  '${S.current.Note_Info_Last_Modified}: $expected'),
              findsOneWidget);
          expect(tester.takeException(), isNull);
        } finally {
          semantics.dispose();
        }
      });
    }
  }

  testWidgets('missing legacy modification metadata stays absent',
      (tester) async {
    await tester.pumpWidget(_host(NoteInfoSheet(
      statistics: NoteStatistics.fromNote(Note(title: 'Old plan')),
      deletedAt: DateTime(2026, 10, 11),
    )));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('note-info-last-modified-value')),
        findsNothing);
    expect(find.text(S.current.Note_Info_Last_Modified), findsNothing);
    expect(find.byKey(const ValueKey('note-info-moved-to-trash-value')),
        findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('stored deletion timestamp is labeled in note info and semantics',
      (tester) async {
    final deleted = DateTime.utc(2026, 10, 11, 23, 30);
    final note = Note(
      title: 'Old plan',
      dateTime: DateTime(2020, 1, 2),
      deletedAt: deleted,
      sortOrder: 17,
    );
    final semantics = tester.ensureSemantics();
    try {
      await tester.pumpWidget(_host(Builder(
        builder: (context) => TextButton(
          onPressed: () => showNoteInfoSheet(
            context: context,
            statistics: NoteStatistics.fromNote(note),
            modifiedAt: note.dateTime,
            deletedAt: note.deletedAt,
          ),
          child: const Text('Info'),
        ),
      )));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Info'));
      await tester.pumpAndSettle();
      final expected =
          DateFormat.yMMMd('en').add_jm().format(deleted.toLocal());
      final date = find.byKey(const ValueKey('note-info-moved-to-trash-value'));
      expect(tester.widget<Text>(date).data, expected);
      expect(
          tester
              .widget<Text>(
                  find.byKey(const ValueKey('note-info-last-modified-value')))
              .data,
          DateFormat.yMMMd('en').add_jm().format(note.dateTime!));
      expect(
          find.bySemanticsLabel(
              '${S.current.Note_Info_Moved_To_Trash}: $expected'),
          findsOneWidget);
      expect(note.deletedAt, deleted);
      expect(note.dateTime, DateTime(2020, 1, 2));
      expect(note.sortOrder, 17);
      expect(tester.takeException(), isNull);
      await tester.tap(find.byTooltip('Close'));
      await tester.pumpAndSettle();
      expect(find.byType(NoteInfoSheet), findsNothing);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('missing deletion metadata never displays a Trash date',
      (tester) async {
    await tester.pumpWidget(_host(NoteInfoSheet(
      statistics: NoteStatistics.fromNote(
          Note(title: 'Old plan', dateTime: DateTime(2020, 1, 2))),
    )));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('note-info-moved-to-trash-value')),
        findsNothing);
    expect(find.text(S.current.Note_Info_Moved_To_Trash), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('isolated Trash info previews fit light, dark and Chinese 2×',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    for (final (preview, size, locale) in [
      (trashNoteInfoLightPreview, const Size(390, 620), 'en'),
      (trashNoteInfoDarkPreview, const Size(390, 620), 'en'),
      (trashNoteInfoChinesePreview, const Size(280, 700), 'zh_HK'),
    ]) {
      tester.view.physicalSize = size;
      await tester.pumpWidget(preview());
      await tester.pumpAndSettle();
      final date = find.byKey(const ValueKey('note-info-moved-to-trash-value'));
      await tester.ensureVisible(date);
      await tester.pumpAndSettle();
      expect(
          tester.widget<Text>(date).data,
          DateFormat.yMMMd(locale)
              .add_jm()
              .format(DateTime(2026, 10, 11, 14, 30)));
      expect(find.text(S.current.Note_Info_Moved_To_Trash), findsOneWidget);
      final modified =
          find.byKey(const ValueKey('note-info-last-modified-value'));
      expect(
          tester.widget<Text>(modified).data,
          DateFormat.yMMMd(locale)
              .add_jm()
              .format(DateTime(2026, 10, 7, 14, 15)));
      await tester.ensureVisible(
          find.byKey(const ValueKey('note-info-recording-duration-value')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets(
      'shows counts with an explicitly estimated reading time and closes',
      (tester) async {
    final semantics = tester.ensureSemantics();
    try {
      final stats = NoteStatistics.fromNote(
        Note(title: 'Weekend', description: 'Tea and bread.'),
      );
      await tester.pumpWidget(_host(Builder(
        builder: (context) => TextButton(
          onPressed: () =>
              showNoteInfoSheet(context: context, statistics: stats),
          child: const Text('Info'),
        ),
      )));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Info'));
      await tester.pumpAndSettle();

      expect(find.text('Note info'), findsOneWidget);
      expect(find.text('Words'), findsOneWidget);
      expect(find.text('Characters'), findsOneWidget);
      expect(find.text('Estimated reading time'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);
      expect(find.text('21'), findsOneWidget);
      expect(find.text('Less than 1 min'), findsOneWidget);
      expect(find.bySemanticsLabel('Words: 4'), findsOneWidget);
      expect(find.bySemanticsLabel('Characters: 21'), findsOneWidget);
      expect(find.bySemanticsLabel('Estimated reading time: Less than 1 min'),
          findsOneWidget);
      expect(find.text('Photos'), findsOneWidget);
      expect(find.text('Recordings'), findsOneWidget);
      expect(find.text('Total recording time'), findsOneWidget);
      await tester.ensureVisible(
          find.byKey(const ValueKey('note-info-recording-duration-value')));
      await tester.pumpAndSettle();
      expect(
          find.bySemanticsLabel('Total recording time: 0:00'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(find.byTooltip('Close'));
      await tester.pumpAndSettle();
      expect(find.byType(NoteInfoSheet), findsNothing);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('empty notes and rounded minute estimates display clearly',
      (tester) async {
    await tester.pumpWidget(_host(
      NoteInfoSheet(statistics: NoteStatistics.fromNote(Note())),
    ));
    await tester.pumpAndSettle();
    expect(find.text('0'), findsNWidgets(6));
    expect(find.text('0 min'), findsOneWidget);
    expect(find.text('0:00'), findsOneWidget);
    expect(find.text('0 of 0 complete'), findsOneWidget);

    await tester.pumpWidget(_host(NoteInfoSheet(
      statistics: NoteStatistics.fromNote(Note(description: 'word ' * 201)),
    )));
    await tester.pumpAndSettle();
    expect(find.text('2 min'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('attachment counts and total duration have descriptive semantics',
      (tester) async {
    final semantics = tester.ensureSemantics();
    try {
      await tester.pumpWidget(_host(NoteInfoSheet(
        statistics: NoteStatistics.fromNote(Note(
          imagePaths: [
            'note_images/missing.jpg',
            'note_images/second.jpg',
            'note_images/scan.jpg',
          ],
          imageLayouts: const [
            NoteImageLayout(
              path: 'note_images/scan.jpg',
              textOffset: 0,
              isDocumentPage: true,
            ),
          ],
          voiceMemos: [
            _memo('long', 3660500),
            _memo('short', 60500),
            _memo('zero', 0),
          ],
        )),
      )));
      await tester.pumpAndSettle();

      for (final (id, value, label) in [
        ('photos', '2', 'Photos'),
        ('scanned-pages', '1', S.current.Note_Info_Scanned_Pages),
        ('recordings', '3', 'Recordings'),
        ('recording-duration', '62:01', 'Total recording time'),
      ]) {
        final valueFinder = find.byKey(ValueKey('note-info-$id-value'));
        await tester.ensureVisible(valueFinder);
        await tester.pumpAndSettle();
        expect(tester.widget<Text>(valueFinder).data, value);
        expect(find.bySemanticsLabel('$label: $value'), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets(
      'checklist summary describes real tasks and excludes placeholders',
      (tester) async {
    final semantics = tester.ensureSemantics();
    try {
      await tester.pumpWidget(_host(NoteInfoSheet(
        statistics: NoteStatistics.fromNote(Note(todo: [
          Todo(title: 'Buy tea'),
          Todo(title: 'Buy bread', completed: true),
          Todo(title: 'Pick a time'),
          Todo(),
          Todo(completed: true),
          Todo(title: ' \t\n '),
          Todo(title: ' ', completed: true),
        ])),
      )));
      await tester.pumpAndSettle();

      for (final (id, value, label) in [
        (
          'checklist-progress',
          '1 of 3 complete',
          S.current.Note_Info_Checklist_Progress
        ),
        ('checklist-remaining', '2', S.current.Note_Info_Checklist_Remaining),
      ]) {
        final valueFinder = find.byKey(ValueKey('note-info-$id-value'));
        await tester.ensureVisible(valueFinder);
        await tester.pumpAndSettle();
        expect(tester.widget<Text>(valueFinder).data, value);
        expect(find.bySemanticsLabel('$label: $value'), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets(
      'placeholder-only and all-complete checklists display zero remaining',
      (tester) async {
    for (final (todos, progress) in [
      ([Todo(), Todo(title: ' ', completed: true)], '0 of 0 complete'),
      ([Todo(title: 'Done', completed: true)], '1 of 1 complete'),
    ]) {
      await tester.pumpWidget(_host(NoteInfoSheet(
        statistics: NoteStatistics.fromNote(Note(todo: todos)),
      )));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<Text>(find
                .byKey(const ValueKey('note-info-checklist-progress-value')))
            .data,
        progress,
      );
      expect(
        tester
            .widget<Text>(find
                .byKey(const ValueKey('note-info-checklist-remaining-value')))
            .data,
        '0',
      );
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets(
      'total duration preserves minute totals and floors summed fractions',
      (tester) async {
    for (final (durations, expected) in [
      ([600, 600, -1000], '0:01'),
      ([3600000], '60:00'),
      ([86400000, 3661000], '1501:01'),
    ]) {
      await tester.pumpWidget(_host(NoteInfoSheet(
        statistics: NoteStatistics.fromNote(Note(
          voiceMemos: [
            for (final (index, duration) in durations.indexed)
              _memo('memo-$index', duration),
          ],
        )),
      )));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<Text>(find
                .byKey(const ValueKey('note-info-recording-duration-value')))
            .data,
        expected,
      );
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('isolated light, dark and Hong Kong Chinese 2x previews fit',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    for (final (preview, size) in [
      (noteInfoLightPreview, const Size(390, 620)),
      (noteInfoDarkPreview, const Size(390, 620)),
      (noteInfoChinesePreview, const Size(280, 700)),
      (noteInfo24HourPreview, const Size(390, 620)),
      (noteInfoMissingDatePreview, const Size(390, 620)),
    ]) {
      tester.view.physicalSize = size;
      await tester.pumpWidget(preview());
      await tester.pumpAndSettle();
      expect(find.byType(NoteInfoSheet), findsOneWidget);
      final modified =
          find.byKey(const ValueKey('note-info-last-modified-value'));
      if (preview == noteInfoMissingDatePreview) {
        expect(modified, findsNothing);
      } else {
        expect(modified, findsOneWidget);
        if (preview == noteInfo24HourPreview) {
          expect(tester.widget<Text>(modified).data, 'Oct 7, 2026 14:15');
        }
      }
      expect(
          find.byKey(const ValueKey('note-info-words-value')), findsOneWidget);
      expect(find.byKey(const ValueKey('note-info-characters-value')),
          findsOneWidget);
      for (final (id, value) in [
        ('photos', '2'),
        ('scanned-pages', '2'),
        ('checklist-progress', S.current.Checklist_Progress(1, 3)),
        ('checklist-remaining', '2'),
        ('recordings', '2'),
        ('recording-duration', '61:08'),
      ]) {
        final valueFinder = find.byKey(ValueKey('note-info-$id-value'));
        await tester.ensureVisible(valueFinder);
        await tester.pumpAndSettle();
        expect(tester.widget<Text>(valueFinder).data, value);
        expect(tester.takeException(), isNull);
      }
    }
  });
}
