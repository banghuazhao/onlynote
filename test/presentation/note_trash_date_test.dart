import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:onlynote/Tools/app_typography_settings.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/domain/model/note_card_style.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/screens/home/widgets/note_card.dart';
import 'package:onlynote/presentation/screens/home/widgets/note_reorder_card.dart';
import 'package:onlynote/presentation/theme/theme.dart';

Widget _host(
  Widget card, {
  Locale locale = const Locale('en'),
  double textScale = 1,
  double width = 350,
  bool dark = false,
}) =>
    MaterialApp(
      theme: dark ? AppTheme.dark : AppTheme.light,
      locale: locale,
      supportedLocales: S.delegate.supportedLocales,
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(textScale),
          disableAnimations: true,
        ),
        child: child!,
      ),
      home: Scaffold(
        body: SingleChildScrollView(
          child: Center(child: SizedBox(width: width, child: card)),
        ),
      ),
    );

void main() {
  setUp(() {
    final fonts = Map<String, GoogleFontBuilder>.of(kAppFontFamilies);
    for (final family in fonts.keys) {
      kAppFontFamilies[family] = (
              {textStyle, color, fontSize, fontWeight, fontStyle}) =>
          (textStyle ?? const TextStyle()).copyWith(
            color: color,
            fontSize: fontSize,
            fontWeight: fontWeight,
            fontStyle: fontStyle,
          );
    }
    addTearDown(() => kAppFontFamilies.addAll(fonts));
  });

  for (final reordered in [false, true]) {
    Widget card(Note note) => reordered
        ? SizedBox(height: 300, child: NoteReorderCard(note: note))
        : NoteCard(note: note);
    final dateKey = ValueKey(reordered ? 'reorder-card-date' : 'card-date');

    testWidgets('${reordered ? 'reorder' : 'note'} card labels the Trash date',
        (tester) async {
      final deleted = DateTime(2026, 10, 11, 14, 30);
      final ordinary = DateTime(2020, 1, 2);
      final note = Note(
        id: 'trashed',
        title: 'Old plan',
        dateTime: ordinary,
        deletedAt: deleted,
        isArchived: true,
        sortOrder: 17,
      );
      final semantics = tester.ensureSemantics();
      try {
        await tester.pumpWidget(_host(card(note)));
        await tester.pumpAndSettle();
        final expected = S.current.Card_Moved_To_Trash_On('Oct 11, 2026');
        expect(tester.widget<Text>(find.byKey(dateKey)).data, expected);
        expect(find.text('Jan 2, 2020'), findsNothing);
        expect(
            tester.getSemantics(find.byKey(dateKey)).label, contains(expected));
        expect(note.deletedAt, deleted);
        expect(note.dateTime, ordinary);
        expect(note.sortOrder, 17);
        expect(note.isArchived, isTrue);
        expect(tester.takeException(), isNull);
      } finally {
        semantics.dispose();
      }
    });

    testWidgets(
        '${reordered ? 'reorder' : 'note'} card preserves active, archive and restored dates',
        (tester) async {
      final date = DateTime(2020, 1, 2);
      for (final archived in [false, true]) {
        await tester.pumpWidget(_host(card(Note(
          id: 'ordinary',
          title: 'Old plan',
          dateTime: date,
          isArchived: archived,
        ))));
        await tester.pumpAndSettle();
        expect(tester.widget<Text>(find.byKey(dateKey)).data, 'Jan 2, 2020');
        expect(find.textContaining('Moved to Trash'), findsNothing);
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets(
        '${reordered ? 'reorder' : 'note'} card respects hidden dates and missing metadata',
        (tester) async {
      for (final note in [
        Note(id: 'missing', title: 'Old plan'),
        Note(
          id: 'hidden',
          title: 'Old plan',
          dateTime: DateTime(2020, 1, 2),
          deletedAt: DateTime(2026, 10, 11),
          cardStyle: const NoteCardStyle(showDate: false),
        ),
      ]) {
        await tester.pumpWidget(_host(card(note)));
        await tester.pumpAndSettle();
        expect(find.byKey(dateKey), findsNothing);
        expect(find.textContaining('Moved to Trash'), findsNothing);
        expect(tester.takeException(), isNull);
      }
      // A restored note has no deletion metadata and retains its note date.
      final restored = Note(
        title: 'Old plan',
        dateTime: DateTime(2020, 1, 2),
        deletedAt: DateTime(2026, 10, 11),
      ).copyWith(deletedAt: null);
      await tester.pumpWidget(_host(card(restored)));
      await tester.pumpAndSettle();
      expect(tester.widget<Text>(find.byKey(dateKey)).data, 'Jan 2, 2020');
      expect(find.textContaining('Moved to Trash'), findsNothing);
    });

    for (final locale in [const Locale('zh'), const Locale('zh', 'HK')]) {
      testWidgets(
          '${reordered ? 'reorder' : 'note'} Trash date fits narrow large $locale text',
          (tester) async {
        tester.view.physicalSize = const Size(280, 700);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final deleted = DateTime.utc(2026, 10, 11, 23, 30);
        await tester.pumpWidget(_host(
          card(Note(id: 'trashed', title: '本週安排', deletedAt: deleted)),
          locale: locale,
          textScale: 2,
          width: 250,
          dark: true,
        ));
        await tester.pumpAndSettle();
        final expected = S.current.Card_Moved_To_Trash_On(
            DateFormat.yMMMd(locale.toString()).format(deleted.toLocal()));
        expect(tester.widget<Text>(find.byKey(dateKey)).data, expected);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
