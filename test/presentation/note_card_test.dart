import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/screens/home/widgets/note_card.dart';
import 'package:onlynote/presentation/theme/theme.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('NoteCard shows title, body, and date like a written note',
      (tester) async {
    final note = Note(
      id: 'note-1',
      title: 'Saturday market',
      description: 'Bread, citrus, and the good olives.',
      color: const Color(0xFFFFF4C2),
      dateTime: DateTime(2026, 8, 19),
    );

    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: S.delegate.supportedLocales,
        home: Scaffold(
          body: NoteCard(
            note: note,
            onTap: () => tapped = true,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Saturday market'), findsOneWidget);
    expect(find.text('Bread, citrus, and the good olives.'), findsOneWidget);
    expect(find.text(note.date), findsOneWidget);

    await tester.tap(find.text('Saturday market'));
    await tester.pump();
    expect(tapped, isTrue);
  });
}
