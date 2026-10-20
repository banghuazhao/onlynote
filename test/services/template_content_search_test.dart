import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/domain/model/custom_note_template.dart';
import 'package:onlynote/domain/model/note_text_style.dart';
import 'package:onlynote/domain/model/voice_memo.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/services/note_templates.dart';
import 'package:onlynote/services/template_content_search.dart';

CustomNoteTemplate _template(
  String id, {
  String name = 'Routine',
  String title = '',
  String body = '',
  List<String> items = const [],
  List<String> tags = const [],
  String? transcript,
}) =>
    CustomNoteTemplate(
      id: id,
      name: name,
      title: title,
      body: body,
      items: items,
      tags: tags,
      imagePaths: const ['template_images/unavailable-photo.jpg'],
      linkedNoteIds: const ['linked-secret-id'],
      textStyles: body.isEmpty
          ? const []
          : [
              NoteTextStyleRange(
                  start: 0, end: body.length, kind: NoteTextStyleKind.bold),
            ],
      voiceMemos: [
        VoiceMemo(
          id: 'unavailable-memo-id',
          path: 'template_audio/unavailable-audio.m4a',
          durationMs: 1000,
          transcript: transcript,
          createdAt: DateTime.utc(2026, 10, 20),
        ),
      ],
      createdAt: DateTime.utc(2026, 10, 20),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('custom search includes each user-facing field and keeps identity/order',
      () {
    final templates = [
      _template('name', name: 'Quarterly routine'),
      _template('title', title: 'Quarterly review'),
      _template('body', body: 'Prepare the quarterly report'),
      _template('items', items: ['Collect invoices', 'Quarterly budget']),
      _template('tags', tags: ['quarterly']),
      _template('transcript', transcript: 'Discuss quarterly results'),
      _template('unrelated'),
      _template('duplicate', name: 'Quarterly routine'),
    ];
    final before = [for (final template in templates) template.toJson()];
    final result =
        TemplateContentSearch('  QuArTeRlY  ').filterCustom(templates);
    expect(result, orderedEquals([...templates.take(6), templates.last]));
    for (final value in result) {
      expect(value, same(templates.firstWhere((item) => item.id == value.id)));
    }
    expect([for (final template in templates) template.toJson()], before);
  });

  test(
      'blank queries retain empty and populated templates in their original order',
      () {
    final templates = [_template('empty'), _template('other', body: 'Notes')];
    for (final query in ['', ' \t\n\u3000 ']) {
      final result = TemplateContentSearch(query).filterCustom(templates);
      expect(result, orderedEquals(templates));
      expect(result.first, same(templates.first));
    }
    expect(TemplateContentSearch('notes').filterCustom([]), isEmpty);
    expect(TemplateContentSearch('missing').filterCustom(templates), isEmpty);
  });

  test('queries are literal and Unicode-aware across stored fields', () {
    final templates = [
      _template('syntax', body: 'C++ [2026] .* ? \\'),
      _template('cjk', items: ['閱讀與研究茶😀 👨‍👩‍👧‍👦']),
      _template('case', tags: ['Ångström']),
      _template('other', body: 'CCC 2026'),
    ];
    for (final query in [' c++ ', '[2026]', '[', '.*', '?', '\\']) {
      expect(
          TemplateContentSearch(query).filterCustom(templates), [templates[0]]);
    }
    for (final query in [' 研究茶😀 ', '👨‍👩‍👧‍👦']) {
      expect(
          TemplateContentSearch(query).filterCustom(templates), [templates[1]]);
    }
    expect(TemplateContentSearch(' ÅNGSTRÖM ').filterCustom(templates),
        [templates[2]]);
  });

  test('technical metadata and boundaries between text fields are excluded',
      () {
    final template = _template('template-secret-id',
        name: 'Alpha', title: 'Beta', body: 'Notes');
    for (final query in [
      'template-secret-id',
      'linked-secret-id',
      'unavailable-memo-id',
      'unavailable-photo',
      'unavailable-audio',
      'template_images',
      'template_audio',
      '.m4a',
      'bold',
      '2026-10-20',
      'Alpha Beta',
    ]) {
      expect(TemplateContentSearch(query).filterCustom([template]), isEmpty,
          reason: query);
    }
  });

  for (final locale in S.delegate.supportedLocales) {
    test(
        'starter search includes localized title, summary, body and items in $locale',
        () async {
      final strings = await S.load(locale);
      const template = NoteTemplate.dailyPlan;
      final content = template.content(strings);
      for (final query in [
        content.title,
        content.summary,
        content.body,
        ...content.items
      ]) {
        expect(query.trim(), isNotEmpty);
        final result = TemplateContentSearch(' ${query.toUpperCase()} ')
            .filterBuiltIn(NoteTemplate.values, strings);
        expect(result, contains(template), reason: query);
        expect(
            result, orderedEquals(NoteTemplate.values.where(result.contains)));
      }
      expect(
          TemplateContentSearch('\u3000')
              .filterBuiltIn(NoteTemplate.values, strings),
          orderedEquals(NoteTemplate.values));
      expect(
          TemplateContentSearch('.*')
              .filterBuiltIn(NoteTemplate.values, strings),
          isEmpty);
    });
  }
}
