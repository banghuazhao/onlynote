import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/Tools/app_typography_settings.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/paper_note.dart';
import 'package:onlynote/presentation/screens/home/widgets/note_card.dart';
import 'package:onlynote/presentation/theme/theme.dart';
import 'package:screenshot/screenshot.dart';

class _PausedCapture extends ScreenshotController {
  final result = Completer<Uint8List?>();
  bool called = false;

  @override
  Future<Uint8List?> capture({
    double? pixelRatio,
    Duration delay = const Duration(milliseconds: 20),
  }) {
    called = true;
    return result.future;
  }
}

Widget _host(
  Widget card, {
  Locale locale = const Locale('en'),
  bool dark = false,
  double scale = 1,
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
        data: MediaQuery.of(
          context,
        ).copyWith(
            textScaler: TextScaler.linear(scale), disableAnimations: true),
        child: child!,
      ),
      home: Scaffold(
        body: SingleChildScrollView(
          child: Center(child: SizedBox(width: 170, child: card)),
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

  testWidgets('missing and blank folder names do not add card metadata', (
    tester,
  ) async {
    final note = Note(id: 'note', title: 'Saved note');
    Size? originalSize;
    for (final name in <String?>[null, '', ' \n\t']) {
      await tester.pumpWidget(_host(NoteCard(note: note, folderName: name)));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('card-folder')), findsNothing);
      final size = tester.getSize(find.byType(PaperNote));
      originalSize ??= size;
      expect(size, originalSize);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('long folder labels fit narrow cards and announce full names', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      for (final locale in [const Locale('en'), const Locale('zh', 'HK')]) {
        final name = locale.languageCode == 'en'
            ? 'Projects and research 👩🏽‍💻 for the coming year'
            : '工作與研究筆記👩🏽‍💻以及明年的旅行計劃';
        for (final dark in [false, true]) {
          await tester.pumpWidget(
            _host(
              NoteCard(
                note: Note(id: 'note', title: 'Note'),
                folderName: name,
              ),
              locale: locale,
              dark: dark,
              scale: 2.4,
            ),
          );
          await tester.pumpAndSettle();
          final label = find.byKey(const ValueKey('card-folder'));
          final strings = S.of(tester.element(label));
          expect(
            find.bySemanticsLabel(
              RegExp(RegExp.escape('${strings.Note_Info_Folder}: $name')),
            ),
            findsOneWidget,
          );
          final text = tester.widget<Text>(
            find.descendant(of: label, matching: find.byType(Text)),
          );
          expect(text.data, name);
          expect(text.maxLines, 2);
          expect(tester.getSize(label).width, lessThanOrEqualTo(170));
          expect(tester.takeException(), isNull);
        }
      }
    } finally {
      semantics.dispose();
    }
  });

  for (final fail in [false, true]) {
    testWidgets(
        'image capture omits folder and restores it after '
        '${fail ? 'failure' : 'success'}', (tester) async {
      final note = Note(id: 'note', title: 'Share this note');
      await tester.pumpWidget(_host(NoteCard(note: note)));
      await tester.pumpAndSettle();
      final exportSize = tester.getSize(find.byType(PaperNote));
      final controller = _PausedCapture();
      final key = GlobalKey<NoteCardState>();
      await tester.pumpWidget(
        _host(
          NoteCard(
            key: key,
            note: note,
            folderName: 'Private projects',
            screenshotController: controller,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Private projects'), findsOneWidget);
      final capture = key.currentState!.captureImage();
      final outcome = fail ? expectLater(capture, throwsStateError) : capture;
      await tester.pump();
      expect(controller.called, isTrue);
      expect(find.byKey(const ValueKey('card-folder')), findsNothing);
      expect(find.text('Private projects'), findsNothing);
      expect(tester.getSize(find.byType(PaperNote)), exportSize);
      if (fail) {
        controller.result.completeError(StateError('Capture failed'));
      } else {
        controller.result.complete(Uint8List.fromList([1, 2, 3]));
      }
      await outcome;
      await tester.pumpAndSettle();
      expect(find.text('Private projects'), findsOneWidget);
      expect(note.folderId, isNull);
      expect(tester.takeException(), isNull);
    });
  }
}
