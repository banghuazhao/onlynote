import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/template_name_search.dart';
import 'package:onlynote/presentation/components/template_name_search_previews.dart';

class _NamedTemplate {
  _NamedTemplate(this.name);
  final String name;
}

Finder _key(String key) => find.byKey(ValueKey(key));
Finder get _field => _key('template-name-search');
Finder get _clear => _key('template-name-clear-search');
Finder get _empty => _key('template-name-search-empty');

Widget _host(Widget child, {Locale locale = const Locale('en')}) => MaterialApp(
      locale: locale,
      supportedLocales: S.delegate.supportedLocales,
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: const TextScaler.linear(2)),
        child: child!,
      ),
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );

Future<void> _search(WidgetTester tester, String query) async {
  await tester.ensureVisible(_field);
  await tester.pumpAndSettle();
  await tester.enterText(_field, query);
  await tester.pumpAndSettle();
  expect(tester.widget<TextField>(_field).controller!.text, query);
  expect(tester.takeException(), isNull);
}

Future<void> _capture(WidgetTester tester, String name) async {
  if (!const bool.fromEnvironment('CAPTURE_UI')) return;
  final boundary = tester
      .renderObject<RenderRepaintBoundary>(_key('template-search-capture'));
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

  test(
      'template name search is literal, Unicode-aware and retains identity/order',
      () {
    final templates = [
      _NamedTemplate('C++ [2026]'),
      _NamedTemplate('Work routine'),
      _NamedTemplate('WORK workshop'),
      _NamedTemplate('閱讀與研究茶😀'),
      _NamedTemplate('Ångström notes'),
      _NamedTemplate('Literal .* suffix'),
      _NamedTemplate('CCC 2026'),
      _NamedTemplate('Work routine'),
    ];
    final original = List<_NamedTemplate>.of(templates);
    List<_NamedTemplate> matches(String query) =>
        filterTemplateNames(templates, query,
            displayName: (template) => template.name);
    for (final query in ['', '  \t\n ']) {
      final result = matches(query);
      expect(result, orderedEquals(templates));
      for (var index = 0; index < templates.length; index++) {
        expect(result[index], same(templates[index]));
      }
    }
    expect(matches(' c++ '), [templates[0]]);
    expect(matches('[2026]'), [templates[0]]);
    expect(matches('['), [templates[0]]);
    expect(matches('.*'), [templates[5]]);
    expect(matches(' 茶😀 '), [templates[3]]);
    expect(matches(' ÅNGSTRÖM '), [templates[4]]);
    final work = matches(' wOrK ');
    expect(work, [templates[1], templates[2], templates[7]]);
    expect(work.first, same(templates[1]));
    expect(work.last, same(templates[7]));
    expect(matches('missing'), isEmpty);
    expect(templates, orderedEquals(original));
    expect(
        filterTemplateNames<int>([7, 11, 17], ' 7 ',
            displayName: (value) => 'Template $value'),
        [7, 17]);
  });

  for (final locale in [const Locale('en'), const Locale('zh', 'HK')]) {
    testWidgets(
        '$locale template field clears once and exposes localized empty semantics',
        (tester) async {
      tester.view.physicalSize = const Size(280, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final controller = TextEditingController();
      final changes = <String>[];
      final semantics = tester.ensureSemantics();
      try {
        await tester.pumpWidget(_host(
            StatefulBuilder(
              builder: (context, setState) => Column(
                children: [
                  TemplateNameSearchField(
                    controller: controller,
                    onChanged: (query) {
                      changes.add(query);
                      setState(() {});
                    },
                  ),
                  const TemplateNameSearchEmpty(),
                ],
              ),
            ),
            locale: locale));
        await tester.pumpAndSettle();
        expect(tester.widget<TextField>(_field).decoration!.labelText,
            S.current.Search_Templates);
        expect(_clear, findsNothing);
        await _search(tester, 'C++ [2026]');
        expect(changes, ['C++ [2026]']);
        await tester.testTextInput.receiveAction(TextInputAction.search);
        await tester.pumpAndSettle();
        expect(
            tester
                .widget<EditableText>(find.descendant(
                    of: _field, matching: find.byType(EditableText)))
                .focusNode
                .hasFocus,
            isFalse);
        expect(controller.text, 'C++ [2026]');
        await tester.ensureVisible(_clear);
        expect(tester.getSize(_clear).width, greaterThanOrEqualTo(48));
        expect(tester.getSize(_clear).height, greaterThanOrEqualTo(48));
        expect(find.byTooltip(S.current.Clear_Search), findsOneWidget);
        final clearData = tester.getSemantics(_clear).getSemanticsData();
        expect('${clearData.label} ${clearData.tooltip}',
            contains(S.current.Clear_Search));
        expect(clearData.hasAction(ui.SemanticsAction.tap), isTrue);
        expect(tester.getSemantics(_empty).getSemanticsData().label,
            contains(S.current.Templates_Search_Empty));
        expect(
            find.byWidgetPredicate((widget) =>
                widget is Semantics && widget.properties.liveRegion == true),
            findsOneWidget);
        await tester.tap(_clear);
        await tester.pumpAndSettle();
        expect(controller.text, isEmpty);
        expect(changes, ['C++ [2026]', '']);
        expect(_clear, findsNothing);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      } finally {
        semantics.dispose();
        controller.dispose();
      }
    });
  }

  testWidgets('disabled template search cannot clear or request text input',
      (tester) async {
    final controller = TextEditingController(text: 'Keep this query');
    var changes = 0;
    try {
      await tester.pumpWidget(_host(TemplateNameSearchField(
        controller: controller,
        enabled: false,
        onChanged: (_) => changes++,
      )));
      await tester.pumpAndSettle();
      expect(tester.widget<TextField>(_field).enabled, isFalse);
      expect(tester.widget<IconButton>(_clear).onPressed, isNull);
      await tester.tap(_field, warnIfMissed: false);
      await tester.tap(_clear, warnIfMissed: false);
      await tester.pump();
      expect(tester.testTextInput.isVisible, isFalse);
      expect(controller.text, 'Keep this query');
      expect(changes, 0);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    } finally {
      controller.dispose();
    }
  });

  testWidgets(
      'captured template clear callback ignores covered and detached routes',
      (tester) async {
    final controller = TextEditingController(text: 'Keep this query');
    var changes = 0;
    await tester.pumpWidget(_host(TemplateNameSearchField(
      controller: controller,
      onChanged: (_) => changes++,
    )));
    await tester.pumpAndSettle();
    final clear = tester.widget<IconButton>(_clear).onPressed!;
    final context = tester.element(_field);
    showDialog<void>(
        context: context,
        builder: (_) => const AlertDialog(
              content: Text('Covered route'),
            ));
    await tester.pumpAndSettle();
    clear();
    await tester.pump();
    expect(controller.text, 'Keep this query');
    expect(changes, 0);
    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
    clear();
    await tester.pump();
    expect(changes, 0);
    expect(tester.takeException(), isNull);
  });

  for (final (name, preview, size, locale, brightness) in [
    (
      'template-search-light',
      templateNameSearchLightPreview,
      const Size(390, 700),
      const Locale('en'),
      Brightness.light
    ),
    (
      'template-search-dark',
      templateNameSearchDarkPreview,
      const Size(390, 700),
      const Locale('en'),
      Brightness.dark
    ),
    (
      'template-search-chinese',
      templateNameSearchChinesePreview,
      const Size(280, 700),
      const Locale('zh', 'HK'),
      Brightness.light
    ),
  ]) {
    testWidgets(
        '$name searches custom and localized starter names without changing selection',
        (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final semantics = tester.ensureSemantics();
      try {
        await tester.pumpWidget(RepaintBoundary(
          key: const ValueKey('template-search-capture'),
          child: preview(),
        ));
        await tester.pumpAndSettle();
        expect(Localizations.localeOf(tester.element(_field)), locale);
        expect(Theme.of(tester.element(_field)).brightness, brightness);
        expect(_key('template-search-selected'), findsNothing);
        await _search(tester, '[2026]');
        final literal = _key('custom-template-literal');
        expect(literal, findsOneWidget);
        expect(_key('custom-template-work'), findsNothing);
        expect(_key('template-meeting'), findsNothing);
        await tester.ensureVisible(literal);
        await tester.pumpAndSettle();
        expect(tester.getSize(literal).height, greaterThanOrEqualTo(48));
        expect(
            tester
                .getSemantics(literal)
                .getSemanticsData()
                .hasAction(ui.SemanticsAction.tap),
            isTrue);
        await tester.tap(literal);
        await tester.pumpAndSettle();
        expect(tester.widget<Text>(_key('template-search-selected')).data,
            'C++ [2026]');
        for (final query in [
          'weekly review',
          ' quarterly budget ',
          'SUPPLIER',
          'finance',
          'projector',
        ]) {
          await _search(tester, query);
          expect(_key('custom-template-work'), findsOneWidget);
          expect(_key('custom-template-literal'), findsNothing);
          expect(_key('custom-template-cjk'), findsNothing);
          expect(tester.widget<Text>(_key('template-search-selected')).data,
              'C++ [2026]');
        }
        await tester.testTextInput.receiveAction(TextInputAction.search);
        await tester.pumpAndSettle();
        await _capture(tester, '$name-content-match');
        await _search(tester, '👨‍👩‍👧‍👦');
        expect(_key('custom-template-cjk'), findsOneWidget);
        await _search(tester, ' 茶😀 ');
        expect(_key('custom-template-cjk'), findsOneWidget);
        expect(literal, findsNothing);
        expect(tester.widget<Text>(_key('template-search-selected')).data,
            'C++ [2026]');
        await _search(tester, S.current.Template_Packing_Summary);
        expect(_key('template-packing'), findsOneWidget);
        expect(_key('custom-template-work'), findsNothing);
        final starterName = S.current.Template_Meeting_Title;
        await _search(tester, starterName);
        final meeting = _key('template-meeting');
        expect(meeting, findsOneWidget);
        expect(_key('custom-template-cjk'), findsNothing);
        expect(_key('template-shopping'), findsNothing);
        expect(_empty, findsNothing);
        await tester.testTextInput.receiveAction(TextInputAction.search);
        await tester.pumpAndSettle();
        await tester.ensureVisible(meeting);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await _capture(tester, '$name-matched');
        await tester.tap(meeting);
        await tester.pumpAndSettle();
        expect(tester.widget<Text>(_key('template-search-selected')).data,
            starterName);
        await _search(tester, 'not a template 😀');
        expect(_empty, findsOneWidget);
        expect(tester.getSemantics(_empty).getSemanticsData().label,
            contains(S.current.Templates_Search_Empty));
        expect(meeting, findsNothing);
        expect(tester.widget<Text>(_key('template-search-selected')).data,
            starterName);
        await tester.testTextInput.receiveAction(TextInputAction.search);
        await tester.pumpAndSettle();
        await tester.ensureVisible(_empty);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await _capture(tester, '$name-empty');
        await tester.ensureVisible(_clear);
        await tester.pumpAndSettle();
        await tester.tap(_clear);
        await tester.pumpAndSettle();
        expect(_empty, findsNothing);
        expect(tester.widget<TextField>(_field).controller!.text, isEmpty);
        for (final id in ['work', 'literal', 'cjk']) {
          expect(_key('custom-template-$id'), findsOneWidget);
        }
        for (final id in ['shopping', 'packing', 'dailyPlan', 'meeting']) {
          expect(_key('template-$id'), findsOneWidget);
        }
        expect(tester.getTopLeft(_key('custom-template-work')).dy,
            lessThan(tester.getTopLeft(literal).dy));
        expect(tester.widget<Text>(_key('template-search-selected')).data,
            starterName);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
      } finally {
        semantics.dispose();
      }
    });
  }
}
