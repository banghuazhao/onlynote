import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/domain/model/custom_note_template.dart';
import 'package:onlynote/domain/model/voice_memo.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/template_content_snippet.dart';
import 'package:onlynote/presentation/components/template_content_snippet_previews.dart';
import 'package:onlynote/services/note_templates.dart';

CustomNoteTemplate _template({
  String name = 'Planning',
  String title = '',
  String body = '',
  List<String> items = const [],
  List<VoiceMemo> voiceMemos = const [],
  List<String> tags = const [],
}) =>
    CustomNoteTemplate(
      id: 'test',
      name: name,
      title: title,
      body: body,
      items: items,
      voiceMemos: voiceMemos,
      tags: tags,
      createdAt: DateTime(2026, 10, 20),
    );

VoiceMemo _memo(String id, int durationMs, {String? transcript}) => VoiceMemo(
      id: id,
      path: 'template_audio/unavailable-$id.m4a',
      durationMs: durationMs,
      createdAt: DateTime(2026, 10, 20),
      transcript: transcript,
    );

Finder _key(String value) => find.byKey(ValueKey(value));

Future<void> _capture(WidgetTester tester, String name) async {
  if (!const bool.fromEnvironment('CAPTURE_UI')) return;
  final boundary = tester
      .renderObject<RenderRepaintBoundary>(_key('template-snippets-capture'));
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

  test('body takes priority and normalizes whitespace without editing content',
      () {
    final template = _template(
      body: '\n  Destination:\t京都\r\nTravel plans:  茶😀  ',
      items: ['Bring charger'],
      title: 'Weekend trip',
    );
    expect(
        templateContentSnippet(template), 'Destination: 京都 Travel plans: 茶😀');
    expect(template.body, '\n  Destination:\t京都\r\nTravel plans:  茶😀  ');
    expect(template.items, ['Bring charger']);
    expect(template.title, 'Weekend trip');
  });

  test('blank body falls back to nonblank checklist labels in stored order',
      () {
    expect(
        templateContentSnippet(_template(
          body: '\n\t\u3000',
          items: ['\t', '  Check  passport\n', '\u3000', 'Charge\tphone 😀'],
          title: 'Weekend trip',
        )),
        'Check passport · Charge phone 😀');
  });

  test(
      'title is used only when distinct and completely blank snippets are omitted',
      () {
    expect(
        templateContentSnippet(_template(
          body: ' ',
          items: ['\t'],
          title: '  Weekend\n trip  ',
        )),
        'Weekend trip');
    expect(
        templateContentSnippet(_template(
          name: '  Weekly Planning ',
          title: 'weekly\nplanning',
        )),
        isEmpty);
    expect(
        templateContentSnippet(_template(
          body: '\u3000\n',
          items: ['  ', '\t'],
          title: '\n',
        )),
        isEmpty);
  });

  test('long snippets retain complete emoji and CJK graphemes', () {
    final prefix = List.filled(159, '茶').join();
    const family = '👨‍👩‍👧‍👦';
    final body = '$prefix${family}more content';
    final snippet = templateContentSnippet(_template(body: body));
    expect(snippet, '$prefix$family…');
    expect(snippet.characters.length, 161);
    expect(snippet, isNot(contains('\ufffd')));
    final exact = '$prefix$family';
    expect(templateContentSnippet(_template(body: exact)), exact);
    expect(templateContentSnippet(_template(items: [body, 'Later task'])),
        snippet);
  });

  test('search reveals matching body, checklist, transcript and tag text', () {
    final prefix = List.filled(100, 'Earlier background. ').join();
    final template = _template(
      name: 'Named template',
      title: 'Stored title',
      body: '${prefix}Deepbody [2026] after the long prefix',
      items: ['Unrelated task', 'Bring [tea] and C++ notes'],
      voiceMemos: [
        _memo('memo', 1000, transcript: 'Remember the CABIN reservation')
      ],
      tags: ['Travel-tag'],
    );
    final saved = template.toJson();
    expect(templateContentSnippet(template, query: ' DEEPBODY [2026] '),
        '…Deepbody [2026] after the long prefix');
    expect(templateContentSnippet(template, query: '[TEA]'),
        '…[tea] and C++ notes');
    expect(templateContentSnippet(template, query: 'c++'), '…C++ notes');
    expect(
        templateContentSnippet(template, query: 'cabin'), '…CABIN reservation');
    expect(templateContentSnippet(template, query: 'travel-TAG'), 'Travel-tag');
    final fallback = templateContentSnippet(template);
    for (final query in [
      '',
      '\t \u3000',
      'Named template',
      'Stored title',
      '.*',
      'missing',
      'template_audio',
      'unavailable-memo',
      'memo'
    ]) {
      expect(templateContentSnippet(template, query: query), fallback,
          reason: query);
    }
    expect(template.toJson(), saved);
  });

  test(
      'search keeps empty and title-only fallback while exposing audio-only text',
      () {
    final template = _template(name: 'A name', title: 'A title');
    expect(templateContentSnippet(template, query: 'A name'), 'A title');
    expect(templateContentSnippet(template, query: 'A title'), 'A title');
    expect(
        templateContentSnippet(_template(name: 'Equal', title: 'Equal'),
            query: 'equal'),
        isEmpty);
    expect(templateContentSnippet(_template(), query: 'missing'), isEmpty);
    final audio = _template(voiceMemos: [
      _memo('audio', 1000, transcript: 'Confirm the reservation')
    ]);
    expect(templateContentSnippet(audio), isEmpty);
    expect(templateContentSnippet(audio, query: 'reservation'), '…reservation');
  });

  test('matching snippets remain bounded and retain complete Unicode graphemes',
      () {
    const family = '👨‍👩‍👧‍👦';
    const accented = 'e\u0301';
    final tail = List.filled(200, '茶').join();
    final template = _template(body: 'Before $family$accented Match $tail');
    final snippet =
        templateContentSnippet(template, query: '$family$accented Match');
    expect(snippet, startsWith('…$family$accented Match'));
    expect(snippet, endsWith('…'));
    expect(snippet.characters.length, lessThanOrEqualTo(161));
    expect(templateContentSnippet(template, query: '👩'),
        startsWith('…$family$accented'));
    expect(templateContentSnippet(template, query: '\u0301'),
        startsWith('…$accented Match'));
    expect(templateContentSnippet(_template(items: ['研究閱讀茶😀']), query: '茶😀'),
        '…茶😀');
  });

  for (final locale in S.delegate.supportedLocales) {
    test(
        'starter snippets explain localized body and checklist matches in $locale',
        () async {
      final strings = await S.load(locale);
      final content = NoteTemplate.dailyPlan.content(strings);
      for (final query in [
        '',
        '\t\u3000',
        content.title,
        content.summary,
        '.*'
      ]) {
        expect(starterTemplateContentSnippet(content, query: query),
            content.summary);
      }
      expect(starterTemplateContentSnippet(content, query: content.body.trim()),
          content.body.trim().split(RegExp(r'\s+')).join(' '));
      final item = content.items.last;
      expect(
          starterTemplateContentSnippet(content,
              query: ' ${item.toUpperCase()} '),
          item);
      final summaryEnd = content.summary.characters
          .toList()
          .reversed
          .take(5)
          .toList()
          .reversed
          .join();
      expect(starterTemplateContentSnippet(content, query: summaryEnd),
          '…$summaryEnd');
    });
  }

  for (final locale in S.delegate.supportedLocales) {
    testWidgets('recording-only template details are localized in $locale',
        (tester) async {
      tester.view.physicalSize = const Size(280, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      for (final (recordings, duration) in [
        (<VoiceMemo>[], ''),
        ([_memo('zero', 0)], '0:00'),
        (
          [
            _memo('fraction-first', 600),
            _memo('negative', -42000),
            _memo('fraction-second', 600),
          ],
          '0:01',
        ),
        (
          [
            _memo('day', const Duration(hours: 24).inMilliseconds),
            _memo('extra', const Duration(hours: 1, seconds: 5).inMilliseconds),
          ],
          '1500:05',
        ),
      ]) {
        final template = _template(voiceMemos: recordings);
        final original = template.toJson();
        await tester.pumpWidget(MaterialApp(
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
              textScaler: TextScaler.linear(2),
            ),
            child: child!,
          ),
          home: Scaffold(
            body: ListTile(
              title: Text(template.name),
              subtitle: TemplateContentSubtitle(template: template),
            ),
          ),
        ));
        await tester.pumpAndSettle();
        expect(find.text(S.current.Template_Details(0, 0)), findsOneWidget);
        expect(_key('template-content-snippet-test'), findsNothing);
        final details = _key('template-recording-details-test');
        expect(details, recordings.isEmpty ? findsNothing : findsOneWidget);
        if (recordings.isNotEmpty) {
          expect(tester.widget<Text>(details).data,
              '${S.current.History_Recordings(recordings.length)} · $duration');
        }
        expect(template.toJson(), original);
        expect(tester.takeException(), isNull);
      }
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  for (final (name, preview, size, locale, brightness) in [
    (
      'template-snippets-light',
      templateContentSnippetsLightPreview,
      const Size(390, 700),
      const Locale('en'),
      Brightness.light,
    ),
    (
      'template-snippets-dark',
      templateContentSnippetsDarkPreview,
      const Size(390, 700),
      const Locale('en'),
      Brightness.dark,
    ),
    (
      'template-snippets-chinese',
      templateContentSnippetsChinesePreview,
      const Size(280, 700),
      const Locale('zh', 'HK'),
      Brightness.light,
    ),
  ]) {
    testWidgets('$name retains counts, matching content search and selection',
        (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(RepaintBoundary(
        key: const ValueKey('template-snippets-capture'),
        child: preview(),
      ));
      await tester.pumpAndSettle();
      final search = _key('template-name-search');
      expect(Localizations.localeOf(tester.element(search)), locale);
      expect(Theme.of(tester.element(search)).brightness, brightness);
      expect(find.text(S.current.Template_Details(2, 1)), findsOneWidget);
      expect(find.text(S.current.Template_Details(3, 0)), findsOneWidget);
      expect(find.text('${S.current.History_Recordings(2)} · 8:42'),
          findsOneWidget);
      expect(find.text('${S.current.History_Recordings(1)} · 1:05'),
          findsOneWidget);
      expect(_key('template-recording-details-checklist'), findsNothing);
      expect(_key('template-content-snippet-audio'), findsNothing);
      expect(find.text('Buy fresh vegetables · Prepare lunches · Plan dinners'),
          findsOneWidget);
      expect(find.text('閱讀筆記：觀察、問題與下一步 👨‍👩‍👧‍👦'), findsOneWidget);
      final snippet =
          tester.widget<Text>(_key('template-content-snippet-body'));
      expect(snippet.maxLines, 2);
      expect(snippet.overflow, TextOverflow.ellipsis);
      await _capture(tester, name);

      final body = _key('template-snippet-select-body');
      await tester.ensureVisible(body);
      await tester.pumpAndSettle();
      expect(body.hitTestable(), findsOneWidget);
      await tester.tap(body);
      await tester.pumpAndSettle();
      expect(tester.widget<ListTile>(body).selected, isTrue);
      await tester.ensureVisible(search);
      await tester.enterText(search, 'vegetables');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();
      expect(_key('template-name-search-empty'), findsNothing);
      expect(_key('template-snippet-select-checklist'), findsOneWidget);
      expect(
          tester.widget<Text>(_key('template-content-snippet-checklist')).data,
          '…vegetables');
      for (final (query, expected) in [
        ('deepbody [2026]', '…Deepbody [2026]'),
        ('MICROPHONE', '…microphone'),
        ('planning-tag', 'planning-tag'),
        ('茶😀', '…茶😀'),
      ]) {
        await tester.ensureVisible(search);
        await tester.enterText(search, query);
        await tester.testTextInput.receiveAction(TextInputAction.search);
        await tester.pumpAndSettle();
        expect(tester.widget<ListTile>(body).selected, isTrue);
        final match = _key('template-content-snippet-body');
        expect(tester.widget<Text>(match).data, startsWith(expected));
        expect(find.text('${S.current.History_Recordings(2)} · 8:42'),
            findsOneWidget);
        await tester.ensureVisible(match);
        await tester.pumpAndSettle();
        final bounds = tester.getRect(match);
        expect(bounds.left, greaterThanOrEqualTo(0));
        expect(bounds.right, lessThanOrEqualTo(size.width));
        expect(tester.takeException(), isNull);
        if (query == 'deepbody [2026]') await _capture(tester, '$name-match');
      }
      await tester.ensureVisible(search);
      await tester.enterText(search, 'weekly');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();
      expect(tester.widget<ListTile>(body).selected, isTrue);
      expect(_key('template-snippet-select-checklist'), findsOneWidget);
      expect(_key('template-snippet-select-title'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
