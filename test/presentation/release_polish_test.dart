import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/empty_note_library.dart';
import 'package:onlynote/presentation/components/missing_note_photo.dart';
import 'package:onlynote/presentation/components/release_polish_previews.dart';
import 'package:onlynote/presentation/theme/theme.dart';

Widget _host(Widget child,
        {Locale locale = const Locale('en'),
        bool dark = false,
        double textScale = 1}) =>
    MaterialApp(
      locale: locale,
      supportedLocales: S.delegate.supportedLocales,
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: dark ? AppTheme.dark : AppTheme.light,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(textScale),
          disableAnimations: true,
        ),
        child: child!,
      ),
      home: Scaffold(body: child),
    );

Future<void> _capture(WidgetTester tester, String name) async {
  if (!const bool.fromEnvironment('CAPTURE_UI')) return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(const ValueKey('polish-capture')));
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 2);
    try {
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      await File('/tmp/onlynote-polish-$name.png')
          .writeAsBytes(data!.buffer.asUint8List());
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
      final loader = FontLoader(family)..addFont(rootBundle.load(asset));
      await loader.load();
    }
  });

  for (final locale in S.delegate.supportedLocales) {
    testWidgets('empty library guides existing actions once in $locale',
        (tester) async {
      tester.view.physicalSize = const Size(280, 600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      var adds = 0;
      var templates = 0;
      await tester.pumpWidget(_host(
        EmptyNoteLibrary(
          onAdd: () => adds++,
          onTemplates: () => templates++,
        ),
        locale: locale,
        textScale: 2,
      ));
      await tester.pumpAndSettle();
      expect(find.text(S.current.No_notes_found), findsOneWidget);
      expect(find.text(S.current.Empty_Library_Description), findsOneWidget);
      for (final (key, expectedAdds, expectedTemplates) in [
        ('empty-library-add', 1, 0),
        ('empty-library-templates', 1, 1),
      ]) {
        final button = find.byKey(ValueKey(key));
        await tester.ensureVisible(button);
        await tester.pumpAndSettle();
        await tester.tap(button);
        await tester.pumpAndSettle();
        expect(adds, expectedAdds);
        expect(templates, expectedTemplates);
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('missing photo is described with its original label in $locale',
        (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        await tester.pumpWidget(_host(
          const Center(
            child: MissingNotePhoto(
              width: 280,
              height: 200,
              semanticLabel: 'Holiday album',
            ),
          ),
          locale: locale,
        ));
        await tester.pumpAndSettle();
        final label = '${S.current.Photo_Unavailable}. Holiday album';
        expect(find.bySemanticsLabel(label), findsOneWidget);
        expect(find.byTooltip(label), findsOneWidget);
        expect(find.text(S.current.Photo_Unavailable), findsOneWidget);
        expect(tester.getSize(find.byType(MissingNotePhoto)),
            const Size(280, 200));
        expect(tester.takeException(), isNull);
      } finally {
        semantics.dispose();
      }
    });
  }

  testWidgets('small and unconstrained photo placeholders keep their geometry',
      (tester) async {
    for (final dimensions in [(64.0, 52.0), (null, null)]) {
      await tester.pumpWidget(_host(Center(
        child: UnconstrainedBox(
          child: MissingNotePhoto(width: dimensions.$1, height: dimensions.$2),
        ),
      )));
      await tester.pumpAndSettle();
      expect(find.text(S.current.Photo_Unavailable), findsNothing);
      expect(find.byTooltip(S.current.Photo_Unavailable), findsOneWidget);
      expect(tester.getSize(find.byType(MissingNotePhoto)),
          Size(dimensions.$1 ?? 32, dimensions.$2 ?? 32));
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('photo feedback adapts to a small parent and large text',
      (tester) async {
    for (final (width, height, scale) in [
      (64.0, 52.0, 1.0),
      (140.0, 100.0, 2.0),
    ]) {
      await tester.pumpWidget(_host(
        Center(
          child: SizedBox(
            width: width,
            height: height,
            child: const MissingNotePhoto(width: 280, height: 200),
          ),
        ),
        textScale: scale,
      ));
      await tester.pumpAndSettle();
      expect(
          tester.getSize(find.byType(MissingNotePhoto)), Size(width, height));
      expect(find.text(S.current.Photo_Unavailable), findsNothing);
      expect(find.byTooltip(S.current.Photo_Unavailable), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('missing photo uses readable theme colors in light and dark',
      (tester) async {
    for (final dark in [false, true]) {
      await tester.pumpWidget(_host(
          const Center(child: MissingNotePhoto(width: 280, height: 200)),
          dark: dark));
      await tester.pumpAndSettle();
      final icon = find.byIcon(Icons.image_not_supported_outlined);
      final scheme = Theme.of(tester.element(icon)).colorScheme;
      expect(tester.widget<Icon>(icon).color, scheme.onSurfaceVariant);
      final container = find.descendant(
          of: find.byType(MissingNotePhoto), matching: find.byType(Container));
      expect(tester.widget<Container>(container).color,
          scheme.surfaceContainerHighest);
      expect(tester.takeException(), isNull);
    }
  });

  for (final (name, preview, photo, chinese, dark) in [
    ('empty-light', emptyLibraryLightPreview, false, false, false),
    ('empty-dark', emptyLibraryDarkPreview, false, false, true),
    ('empty-chinese', emptyLibraryChinesePreview, false, true, false),
    ('photo-light', missingPhotoLightPreview, true, false, false),
    ('photo-dark', missingPhotoDarkPreview, true, false, true),
    ('photo-chinese', missingPhotoChinesePreview, true, true, false),
  ]) {
    testWidgets('$name preview fits and retains accessible feedback',
        (tester) async {
      tester.view.physicalSize = Size(chinese ? 280 : 390, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(RepaintBoundary(
        key: const ValueKey('polish-capture'),
        child: preview(),
      ));
      await tester.pumpAndSettle();
      final target = find.byType(photo ? MissingNotePhoto : EmptyNoteLibrary);
      final element = tester.element(target.first);
      expect(Localizations.localeOf(element),
          chinese ? const Locale('zh', 'HK') : const Locale('en'));
      expect(Theme.of(element).brightness,
          dark ? Brightness.dark : Brightness.light);
      if (photo) {
        expect(find.byTooltip(S.current.Photo_Unavailable), findsNWidgets(2));
      } else {
        expect(find.text(S.current.Empty_Library_Description), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
      await _capture(tester, name);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
