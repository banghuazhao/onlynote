import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/Tools/app_layout_settings.dart';
import 'package:onlynote/Tools/app_typography_settings.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/app_sheet.dart';
import 'package:onlynote/presentation/components/confirm_dialog.dart';
import 'package:onlynote/presentation/components/folder_name_dialog.dart';
import 'package:onlynote/presentation/components/section_card.dart';
import 'package:onlynote/presentation/screens/card_appearance/card_appearance_screen.dart';
import 'package:onlynote/presentation/screens/settings/settings_screen.dart';
import 'package:onlynote/presentation/theme/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget host(Widget child, {bool dark = false, double scale = 1}) => MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: dark ? AppTheme.dark : AppTheme.light,
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate
      ],
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(scale), disableAnimations: true),
        child: child!,
      ),
      home: child,
    );

// Optional visual evidence, without committing machine-dependent font goldens.
Future<void> capture(WidgetTester tester, String name) async {
  if (!const bool.fromEnvironment('CAPTURE_UI')) return;
  final boundary = tester
      .renderObject<RenderRepaintBoundary>(find.byKey(const Key('capture')));
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    await File('/tmp/onlynote-$name.png')
        .writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

void main() {
  setUpAll(() async {
    const directory = String.fromEnvironment('UI_FONT_DIR');
    if (directory.isEmpty) return;
    for (final entry in {
      'Roboto': 'Roboto-Regular.ttf',
      'MaterialIcons': 'MaterialIcons-Regular.otf'
    }.entries) {
      final loader = FontLoader(entry.key)
        ..addFont(File('$directory/${entry.value}')
            .readAsBytes()
            .then((bytes) => ByteData.sublistView(bytes)));
      await loader.load();
    }
  });
  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final dark in [false, true]) {
    for (final size in [const Size(375, 812), const Size(812, 375)]) {
      testWidgets('sheets scroll and keep close reachable: $dark $size',
          (tester) async {
        tester.view.reset();
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        late BuildContext page;
        var chosen = false;
        await tester.pumpWidget(RepaintBoundary(
            key: const Key('capture'),
            child: host(
              Builder(builder: (context) {
                page = context;
                return const Scaffold();
              }),
              dark: dark,
              scale: 2,
            )));
        final future = showAppActionSheet(
            context: page,
            title: 'Move to folder',
            actions: [
              for (var i = 0; i < 20; i++)
                AppSheetAction(
                  title: Text('Folder $i'),
                  selected: i == 0,
                  leading: const Icon(Icons.folder_outlined),
                  onPressed: (context) {
                    chosen = true;
                    Navigator.pop(context);
                  },
                ),
            ]);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.byIcon(Icons.check_rounded), findsOneWidget);
        expect(find.byTooltip('Close'), findsOneWidget);
        await capture(
            tester, 'sheet-${dark ? 'dark' : 'light'}-${size.width.toInt()}');
        await tester.scrollUntilVisible(find.text('Folder 19'), 300,
            scrollable: find.byType(Scrollable).last);
        await tester.tap(find.text('Folder 19'));
        await tester.pumpAndSettle();
        await future;
        expect(chosen, isTrue);
        expect(find.byType(AppSheet), findsNothing);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('folder dialog rejects blank names and trims keyboard submission',
      (tester) async {
    late BuildContext page;
    await tester.pumpWidget(host(Builder(builder: (context) {
      page = context;
      return const Scaffold();
    })));
    final result = showDialog<String>(
        context: page,
        builder: (_) => const FolderNameDialog(title: 'New folder'));
    await tester.pumpAndSettle();
    expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull);
    await tester.enterText(find.byType(TextField), '   ');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(find.byType(FolderNameDialog), findsOneWidget);
    await tester.enterText(find.byType(TextField), '  Ideas  ');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(await result, 'Ideas');
  });

  testWidgets('destructive alert cancels safely and confirms explicitly',
      (tester) async {
    tester.view.physicalSize = const Size(375, 667);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    late BuildContext page;
    await tester.pumpWidget(RepaintBoundary(
        key: const Key('capture'),
        child: host(Builder(builder: (context) {
          page = context;
          return const Scaffold();
        }), dark: true, scale: 2)));
    var result = showConfirmDialog(page,
        title: 'Delete this note?',
        message: 'This note will be moved to Trash. You can restore it later.');
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await capture(tester, 'alert-dark');
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(await result, isFalse);
    result = showConfirmDialog(page,
        title: 'Delete this note?',
        message: 'This note will be moved to Trash.');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(await result, isTrue);
  });

  for (final dark in [false, true]) {
    for (final size in [
      const Size(375, 812),
      const Size(812, 375),
      const Size(1024, 1366)
    ]) {
      testWidgets('settings remain usable at large text: $dark $size',
          (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        // Isolate layout and persistence from Google Fonts network fetching.
        final fonts = Map<String, GoogleFontBuilder>.of(kAppFontFamilies);
        for (final family in fonts.keys) {
          kAppFontFamilies[family] = (
                  {textStyle, color, fontSize, fontWeight, fontStyle}) =>
              (textStyle ?? const TextStyle()).copyWith(
                  color: color,
                  fontSize: fontSize,
                  fontWeight: fontWeight,
                  fontStyle: fontStyle);
        }
        addTearDown(() {
          kAppFontFamilies.addAll(fonts);
        });
        await AppLayoutSettings.instance.setCardSize(NoteCardSize.medium);
        await tester.pumpWidget(RepaintBoundary(
            key: const Key('capture'),
            child: host(const SettingsScreen(), dark: dark, scale: 2)));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await capture(tester,
            'settings-${dark ? 'dark' : 'light'}-${size.width.toInt()}');
        await tester.scrollUntilVisible(find.text('Default card style'), 200);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Default card style'));
        await tester.pumpAndSettle();
        expect(find.byType(CardAppearanceScreen), findsOneWidget);
        final controls = find.descendant(
          of: find.byKey(const ValueKey('card-style-controls')),
          matching: find.byType(Scrollable),
        );
        await tester.scrollUntilVisible(find.text('Card Size'), 200,
            scrollable: controls);
        await tester.pumpAndSettle();
        final small = find.descendant(
          of: find.ancestor(
              of: find.text('Card Size'), matching: find.byType(SectionCard)),
          matching: find.widgetWithText(ChoiceChip, 'Small'),
        );
        await tester.scrollUntilVisible(small, 200, scrollable: controls);
        await tester.pumpAndSettle();
        await tester.tap(small);
        await tester.pumpAndSettle();
        // Customization stays in the preview until the user saves it.
        expect(AppLayoutSettings.instance.cardSize, NoteCardSize.medium);
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();
        expect(find.byType(CardAppearanceScreen), findsNothing);
        expect(AppLayoutSettings.instance.cardSize, NoteCardSize.small);
        expect(
            (await SharedPreferences.getInstance())
                .getString('app_note_card_size'),
            'small');
        await tester.scrollUntilVisible(find.text('Privacy Policy'), 250);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  }
}
