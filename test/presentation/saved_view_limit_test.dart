import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/saved_view_limit_previews.dart';
import 'package:onlynote/presentation/components/saved_view_save_action.dart';

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

Finder get _save => find.byKey(const ValueKey('library-save-view'));
Finder get _limit => find.byKey(const ValueKey('library-saved-view-limit'));

Future<void> _capture(WidgetTester tester, String name) async {
  if (!const bool.fromEnvironment('CAPTURE_UI')) return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(const ValueKey('saved-view-limit-capture')));
  await tester.runAsync(() async {
    final image = await boundary.toImage();
    try {
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final directory = Directory('/tmp/onlynote-release-feedback');
      await directory.create(recursive: true);
      await File('${directory.path}/$name.png')
          .writeAsBytes(bytes!.buffer.asUint8List());
    } finally {
      image.dispose();
    }
  });
}

void main() {
  setUpAll(() async {
    if (!const bool.fromEnvironment('CAPTURE_UI')) return;
    for (final (family, asset) in [
      ('Roboto', 'assets/fonts/Roboto-Regular.ttf'),
      ('DroidSansFallback', 'assets/fonts/DroidSansFallback.ttf'),
      ('MaterialIcons', 'fonts/MaterialIcons-Regular.otf'),
    ]) {
      final loader = FontLoader(family);
      loader.addFont(rootBundle.load(asset));
      await loader.load();
    }
  });

  for (final count in [29, 30, 31]) {
    testWidgets(
        'save action exposes capacity and guards its callback at $count',
        (tester) async {
      var saves = 0;
      final semantics = tester.ensureSemantics();
      try {
        await tester.pumpWidget(_host(SavedViewSaveAction(
          viewCount: count,
          maxViews: 30,
          onSave: () => saves++,
        )));
        await tester.pumpAndSettle();
        final atCapacity = count >= 30;
        final tile = tester.widget<ListTile>(_save);
        expect(tile.enabled, !atCapacity);
        expect(tile.onTap, atCapacity ? isNull : isNotNull);
        expect(_limit, atCapacity ? findsOneWidget : findsNothing);
        final data = tester.getSemantics(_save).getSemanticsData();
        expect(data.flagsCollection.isEnabled,
            atCapacity ? ui.Tristate.isFalse : ui.Tristate.isTrue);
        if (atCapacity) {
          expect(tester.widget<Text>(_limit).data,
              S.current.Saved_View_Limit_Reached(30));
          expect(
              find.byWidgetPredicate((widget) =>
                  widget is Semantics && widget.properties.liveRegion == true),
              findsOneWidget);
        }
        await tester.tap(_save);
        await tester.pump();
        expect(saves, atCapacity ? 0 : 1);
        expect(tester.takeException(), isNull);
      } finally {
        semantics.dispose();
      }
    });
  }

  testWidgets('isolated previews allow removal to restore saving at capacity',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    for (final (name, preview, size) in [
      ('saved-view-limit-light', savedViewAtLimitPreview, const Size(390, 620)),
      (
        'saved-view-limit-dark',
        savedViewLimitDarkPreview,
        const Size(390, 620)
      ),
      (
        'saved-view-limit-chinese',
        savedViewLimitChinesePreview,
        const Size(280, 700)
      ),
      (
        'saved-view-limit-landscape',
        savedViewAtLimitPreview,
        const Size(640, 280)
      ),
    ]) {
      tester.view.physicalSize = size;
      await tester.pumpWidget(RepaintBoundary(
        key: const ValueKey('saved-view-limit-capture'),
        child: KeyedSubtree(key: ValueKey(name), child: preview()),
      ));
      await tester.pumpAndSettle();
      await tester.ensureVisible(_limit);
      await tester.pumpAndSettle();
      expect(tester.widget<ListTile>(_save).onTap, isNull);
      expect(tester.widget<Text>(_limit).data,
          S.current.Saved_View_Limit_Reached(30));
      expect(tester.takeException(), isNull);
      await _capture(tester, name);

      final delete = find.byKey(const ValueKey('preview-delete-saved-view'));
      await tester.ensureVisible(delete);
      await tester.pumpAndSettle();
      expect(tester.getSize(delete).height, greaterThanOrEqualTo(48));
      expect(find.byTooltip(S.current.Delete_View), findsOneWidget);
      await tester.tap(delete);
      await tester.pumpAndSettle();
      expect(_limit, findsNothing);
      expect(find.text('29 / 30'), findsOneWidget);
      expect(tester.widget<ListTile>(_save).onTap, isNotNull);

      await tester.ensureVisible(_save);
      await tester.pumpAndSettle();
      await tester.tap(_save);
      await tester.pumpAndSettle();
      expect(find.text('30 / 30'), findsOneWidget);
      expect(tester.widget<ListTile>(_save).onTap, isNull);
      expect(_limit, findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('below-limit preview saves once and then shows the limit',
      (tester) async {
    await tester.pumpWidget(savedViewBelowLimitPreview());
    await tester.pumpAndSettle();
    expect(_limit, findsNothing);
    await tester.tap(_save);
    await tester.pumpAndSettle();
    expect(_limit, findsOneWidget);
    expect(find.text('30 / 30'), findsOneWidget);
    await tester.tap(_save);
    await tester.pump();
    expect(find.text('30 / 30'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
