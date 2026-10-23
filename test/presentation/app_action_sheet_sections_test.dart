import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/app_sheet.dart';
import 'package:onlynote/presentation/components/note_action_menu_previews.dart';

Finder _heading(String label) => find.byWidgetPredicate((widget) =>
    widget is Text &&
    widget.data == label &&
    widget.key is ValueKey<String> &&
    (widget.key! as ValueKey<String>).value.startsWith('app-sheet-section-'));

Future<void> _capture(WidgetTester tester, String name) async {
  if (!const bool.fromEnvironment('CAPTURE_UI')) return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(const ValueKey('action-menu-capture')));
  await tester.runAsync(() async {
    final image = await boundary.toImage();
    try {
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await File('/tmp/onlynote-action-menu-$name.png')
          .writeAsBytes(bytes!.buffer.asUint8List());
    } finally {
      image.dispose();
    }
  });
}

Future<void> _open(WidgetTester tester, List<String> chosen,
    {bool grouped = true}) async {
  await tester.pumpWidget(MaterialApp(
    locale: const Locale('en'),
    supportedLocales: S.delegate.supportedLocales,
    localizationsDelegates: const [
      S.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: Scaffold(body: Builder(builder: (context) {
      final s = S.of(context);
      return TextButton(
        onPressed: () => showAppActionSheet(
          context: context,
          title: s.More_Options,
          actions: [
            for (final (id, label, section) in [
              ('find', s.Find_In_Note, s.Note_Menu_Editing),
              ('outline', s.Note_Outline, s.Note_Menu_Editing),
              ('tags', s.Edit_Tags, s.Note_Menu_Organization),
              ('share', s.Share, s.Note_Menu_Sharing),
              ('info', s.Note_Info, s.Note_Menu_Details),
              ('history', s.History_Title, s.Note_Menu_Details),
              ('delete', s.Delete, null),
            ])
              AppSheetAction(
                title: Text(label),
                section: grouped ? section : null,
                destructive: id == 'delete',
                selected: id == 'tags',
                onPressed: (sheetContext) {
                  chosen.add(id);
                  Navigator.pop(sheetContext);
                },
              ),
          ],
        ),
        child: const Text('Open actions'),
      );
    })),
  ));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Open actions'));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    if (!const bool.fromEnvironment('CAPTURE_UI')) return;
    for (final (family, asset) in [
      ('Roboto', 'assets/fonts/Roboto-Regular.ttf'),
      ('DroidSansFallback', 'assets/fonts/DroidSansFallback.ttf'),
      ('MaterialIcons', 'fonts/MaterialIcons-Regular.otf'),
    ]) {
      final loader = FontLoader(family)..addFont(rootBundle.load(asset));
      await loader.load();
    }
  });

  testWidgets('grouped actions preserve callback targeting and selection',
      (tester) async {
    final chosen = <String>[];
    for (final id in [
      'find',
      'outline',
      'tags',
      'share',
      'info',
      'history',
      'delete'
    ]) {
      await _open(tester, chosen);
      final labels = {
        'find': S.current.Find_In_Note,
        'outline': S.current.Note_Outline,
        'tags': S.current.Edit_Tags,
        'share': S.current.Share,
        'info': S.current.Note_Info,
        'history': S.current.History_Title,
        'delete': S.current.Delete,
      };
      final row = find.widgetWithText(ListTile, labels[id]!);
      expect(
          tester
              .widget<ListTile>(
                  find.widgetWithText(ListTile, S.current.Edit_Tags))
              .selected,
          isTrue);
      final before = chosen.length;
      await tester.ensureVisible(row);
      await tester.pumpAndSettle();
      await tester.tap(row);
      await tester.pumpAndSettle();
      expect(chosen.length, before + 1);
      expect(chosen.last, id);
      expect(find.byType(AppSheet), findsNothing);
      expect(find.text('Open actions'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('ungrouped callers retain the original rows and divider',
      (tester) async {
    await _open(tester, [], grouped: false);
    expect(find.byKey(const ValueKey('app-sheet-section-0')), findsNothing);
    expect(find.text(S.current.Note_Menu_Editing), findsNothing);
    expect(find.byType(ListTile), findsNWidgets(7));
    // The sheet header and the existing destructive-action separator.
    expect(find.byType(Divider), findsNWidgets(2));
    await tester.ensureVisible(find.text(S.current.Cancel));
    await tester.tap(find.text(S.current.Cancel));
    await tester.pumpAndSettle();
    expect(find.text('Open actions'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final (name, preview, size, locale, brightness) in [
    (
      'light',
      noteActionMenuPreview,
      const Size(390, 700),
      const Locale('en'),
      Brightness.light
    ),
    (
      'dark',
      noteActionMenuDarkPreview,
      const Size(240, 700),
      const Locale('en'),
      Brightness.dark
    ),
    (
      'chinese',
      noteActionMenuChinesePreview,
      const Size(280, 700),
      const Locale('zh', 'HK'),
      Brightness.light
    ),
  ]) {
    testWidgets('$name grouped menu wraps and exposes section headings',
        (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final semantics = tester.ensureSemantics();
      try {
        await tester.pumpWidget(RepaintBoundary(
            key: const ValueKey('action-menu-capture'), child: preview()));
        await tester.pumpAndSettle();
        final sheet = find.byType(AppActionSheet);
        expect(Localizations.localeOf(tester.element(sheet)), locale);
        expect(Theme.of(tester.element(sheet)).brightness, brightness);
        final sections = [
          S.current.Note_Menu_Editing,
          S.current.Note_Menu_Organization,
          S.current.Note_Menu_Sharing,
          S.current.Note_Menu_Details
        ];
        final tops = [
          for (final label in sections) tester.getTopLeft(_heading(label)).dy
        ];
        for (var index = 1; index < tops.length; index++) {
          expect(tops[index], greaterThan(tops[index - 1]));
        }
        for (final label in sections) {
          final header = _heading(label);
          expect(header, findsOneWidget);
          await tester.ensureVisible(header);
          await tester.pumpAndSettle();
          final data = tester.getSemantics(header).getSemanticsData();
          expect(data.flagsCollection.isHeader, isTrue);
          expect(data.hasAction(ui.SemanticsAction.tap), isFalse);
          expect(tester.widget<Text>(header).maxLines, isNull);
          expect(tester.takeException(), isNull);
        }
        final rows =
            tester.widgetList<ListTile>(find.byType(ListTile)).toList();
        expect((rows.last.title as Text).data, S.current.Delete);
        final info = find.widgetWithText(ListTile, S.current.Note_Info);
        await tester.ensureVisible(info);
        await tester.pumpAndSettle();
        expect(tester.getSize(info).height, greaterThanOrEqualTo(48));
        await tester.tap(info);
        await tester.pumpAndSettle();
        expect(tester.widget<ListTile>(info).selected, isTrue);
        await _capture(tester, '$name-details');
        await tester.ensureVisible(_heading(sections.first));
        await tester.pumpAndSettle();
        await _capture(tester, name);
        expect(tester.takeException(), isNull);
      } finally {
        semantics.dispose();
      }
    });
  }
}
