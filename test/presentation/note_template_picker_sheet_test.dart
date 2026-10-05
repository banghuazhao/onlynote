import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/note_template_picker_sheet.dart';
import 'package:onlynote/presentation/theme/theme.dart';
import 'package:onlynote/services/note_templates.dart';

Future<void> _openPicker(
  WidgetTester tester,
  List<NoteTemplate?> results, {
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
            results.add(await showNoteTemplatePickerSheet(context));
          },
          child: const Text('Open templates'),
        ),
      ),
    ),
  ));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Open templates'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('picker previews each template and returns the chosen type',
      (tester) async {
    final results = <NoteTemplate?>[];
    await _openPicker(tester, results);
    expect(find.text('Shopping list'), findsOneWidget);
    expect(find.text('Packing list'), findsOneWidget);
    expect(find.text('Daily plan'), findsOneWidget);
    expect(find.text('Meeting notes'), findsOneWidget);
    expect(find.text('An outline for the agenda, decisions, and follow-up.'),
        findsOneWidget);
    expect(results, isEmpty);

    final meeting = find.byKey(const ValueKey('template-meeting'));
    await tester.ensureVisible(meeting);
    await tester.tap(meeting);
    await tester.pumpAndSettle();

    expect(results, [NoteTemplate.meeting]);
    expect(find.byType(NoteTemplatePickerSheet), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('closing template discovery leaves the choice empty',
      (tester) async {
    final results = <NoteTemplate?>[];
    await _openPicker(tester, results);
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();
    expect(results, [null]);
    expect(find.byType(NoteTemplatePickerSheet), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('narrow layout with large Chinese text remains selectable',
      (tester) async {
    final results = <NoteTemplate?>[];
    await _openPicker(
      tester,
      results,
      locale: const Locale('zh', 'HK'),
      size: const Size(320, 640),
      textScale: 2,
    );
    expect(find.text('範本'), findsOneWidget);
    expect(find.text('購物清單'), findsOneWidget);
    expect(tester.takeException(), isNull);
    final meeting = find.byKey(const ValueKey('template-meeting'));
    await tester.ensureVisible(meeting);
    await tester.tap(meeting);
    await tester.pumpAndSettle();
    expect(results, [NoteTemplate.meeting]);
    expect(tester.takeException(), isNull);
  });
}
