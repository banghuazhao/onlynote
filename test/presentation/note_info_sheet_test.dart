import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/domain/model/note_image_layout.dart';
import 'package:onlynote/domain/model/voice_memo.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/note_info_previews.dart';
import 'package:onlynote/presentation/components/note_info_sheet.dart';
import 'package:onlynote/services/note_statistics.dart';

Widget _host(Widget child) => MaterialApp(
      locale: const Locale('en'),
      supportedLocales: S.delegate.supportedLocales,
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Scaffold(body: child),
    );

VoiceMemo _memo(String id, int durationMs) => VoiceMemo(
      id: id,
      path: 'note_audio/$id.m4a',
      durationMs: durationMs,
      createdAt: DateTime(2026, 10, 7),
    );

void main() {
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
    expect(find.text('0'), findsNWidgets(4));
    expect(find.text('0 min'), findsOneWidget);
    expect(find.text('0:00'), findsOneWidget);

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
    ]) {
      tester.view.physicalSize = size;
      await tester.pumpWidget(preview());
      await tester.pumpAndSettle();
      expect(find.byType(NoteInfoSheet), findsOneWidget);
      expect(
          find.byKey(const ValueKey('note-info-words-value')), findsOneWidget);
      expect(find.byKey(const ValueKey('note-info-characters-value')),
          findsOneWidget);
      for (final (id, value) in [
        ('photos', '2'),
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
