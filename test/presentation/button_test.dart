import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/app_bar.dart';
import 'package:onlynote/presentation/components/button.dart';
import 'package:onlynote/presentation/components/paper_note.dart';
import 'package:onlynote/presentation/components/previews.dart';
import 'package:onlynote/presentation/theme/button_styles.dart';
import 'package:onlynote/presentation/theme/theme.dart';

Widget host(Widget home, {bool dark = false, double scale = 1}) => MaterialApp(
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
          child: child!),
      home: home,
    );

void main() {
  setUpAll(() async {
    if (!const bool.fromEnvironment('CAPTURE_UI')) return;
    final text = FontLoader('Roboto')
      ..addFont(File('assets/fonts/Roboto-Regular.ttf')
          .readAsBytes()
          .then(ByteData.sublistView));
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await text.load();
    await icons.load();
  });
  for (final dark in [false, true]) {
    for (final size in [const Size(375, 812), const Size(812, 375)]) {
      testWidgets(
          'buttons fit, stay tappable, and respect large text: $dark $size',
          (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(host(
            Scaffold(
              appBar: NoteAppBar(
                  autoImplementLeading: false,
                  leading: IconButton(
                      tooltip: 'Back',
                      onPressed: () {},
                      icon: const Icon(Icons.arrow_back)),
                  actions: [
                    for (final icon in [
                      Icons.alarm,
                      Icons.share,
                      Icons.edit,
                      Icons.delete_outline
                    ])
                      AppButton(
                          onPressed: () {},
                          tooltip: 'Action',
                          child: Icon(icon)),
                  ]),
              body: const DeskSurface(child: ButtonExamples()),
            ),
            dark: dark,
            scale: 2));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        for (final finder in [
          find.byType(IconButton),
          find.byType(TextButton),
          find.byType(FilledButton),
          find.byType(OutlinedButton)
        ]) {
          for (final element in finder.evaluate()) {
            final box = element.renderObject as RenderBox;
            expect(box.size.width, greaterThanOrEqualTo(48));
            expect(box.size.height, greaterThanOrEqualTo(48));
          }
        }
        await tester.ensureVisible(find.text('Unavailable'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
    testWidgets('button gallery visual: $dark', (tester) async {
      tester.view.physicalSize = const Size(390, 750);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final key = GlobalKey();
      await tester.pumpWidget(RepaintBoundary(
          key: key,
          child: host(
              const Scaffold(body: DeskSurface(child: ButtonExamples())),
              dark: dark)));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      if (const bool.fromEnvironment('CAPTURE_UI')) {
        await tester.runAsync(() async {
          final image = await (key.currentContext!.findRenderObject()
                  as RenderRepaintBoundary)
              .toImage(pixelRatio: 2);
          final data = await image.toByteData(format: ui.ImageByteFormat.png);
          await File('/tmp/onlynote-buttons-${dark ? 'dark' : 'light'}.png')
              .writeAsBytes(data!.buffer.asUint8List());
          image.dispose();
        });
      }
    });
  }

  testWidgets('loading retains button bounds and blocks repeated taps',
      (tester) async {
    var count = 0;
    var loading = false;
    late StateSetter update;
    await tester.pumpWidget(host(
        Scaffold(body: Center(child: StatefulBuilder(builder: (_, setState) {
      update = setState;
      return AppButton(
          primary: true,
          isLoading: loading,
          tooltip: 'Save',
          onPressed: () => count++,
          child: const Text('Save note'));
    })))));
    await tester.pumpAndSettle();
    final initial = tester.getSize(find.byType(TextButton));
    await tester.tap(find.byType(TextButton));
    expect(count, 1);
    update(() => loading = true);
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(TextButton)), initial);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    await tester.tap(find.byType(TextButton));
    expect(count, 1);
    update(() => loading = false);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(TextButton));
    expect(count, 2);
  });

  test('icon states provide visible focus, press and disabled feedback', () {
    for (final theme in [AppTheme.light, AppTheme.dark]) {
      final style = AppButtonStyles.icon(theme.colorScheme);
      expect(style.overlayColor!.resolve({WidgetState.pressed})!.a,
          greaterThan(0));
      expect(style.side!.resolve({WidgetState.focused})!.width,
          greaterThan(style.side!.resolve({})!.width));
      expect(style.foregroundColor!.resolve({WidgetState.disabled}),
          isNot(style.foregroundColor!.resolve({})));
      final paper = AppButtonStyles.paper();
      final fg = paper.foregroundColor!.resolve({})!;
      final bg = paper.backgroundColor!.resolve({})!;
      expect((bg.computeLuminance() + .05) / (fg.computeLuminance() + .05),
          greaterThan(4.5));
    }
  });
}
