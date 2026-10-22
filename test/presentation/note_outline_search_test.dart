import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/domain/model/note_text_style.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/note_outline_preview.dart';
import 'package:onlynote/presentation/components/note_outline_sheet.dart';
import 'package:onlynote/services/note_outline.dart';

import '../support/search_highlight_text.dart';

const _searchKey = ValueKey('note-outline-search');
const _clearKey = ValueKey('note-outline-search-clear');
const _emptyKey = ValueKey('note-outline-search-empty');

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  Size size = const Size(390, 700),
  double textScale = 1,
  Locale locale = const Locale('en'),
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(MaterialApp(
    locale: locale,
    localizationsDelegates: const [
      S.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: S.delegate.supportedLocales,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        disableAnimations: true,
        textScaler: TextScaler.linear(textScale),
      ),
      child: child!,
    ),
    home: Scaffold(body: child),
  ));
  await tester.pumpAndSettle();
}

Finder _entry(int offset) => find.byKey(ValueKey('note-outline-entry-$offset'));

Future<void> _search(WidgetTester tester, String query) async {
  await tester.ensureVisible(find.byKey(_searchKey));
  await tester.enterText(find.byKey(_searchKey), query);
  await tester.pumpAndSettle();
}

List<int> _visibleOffsets(WidgetTester tester) => tester
    .widgetList<ListTile>(find.byType(ListTile))
    .map((tile) => int.parse((tile.key! as ValueKey<String>)
        .value
        .substring('note-outline-entry-'.length)))
    .toList();

void main() {
  testWidgets('heading search is literal, case insensitive and trims Unicode',
      (tester) async {
    const entries = [
      NoteOutlineEntry(text: 'Café [plan].*', start: 0, end: 13),
      NoteOutlineEntry(text: 'CAFÉ review', start: 40, end: 51),
      NoteOutlineEntry(text: '今天的計劃', start: 80, end: 85),
      NoteOutlineEntry(text: 'Plan without punctuation', start: 120, end: 144),
    ];
    await _pump(tester, const NoteOutlineSheet(entries: entries));

    await _search(tester, '  CAFÉ  ');
    expect(_visibleOffsets(tester), [0, 40]);
    expect(highlightedSearchText(tester, _entry(0)), ['Café']);
    expect(highlightedSearchText(tester, _entry(40)), ['CAFÉ']);
    await _search(tester, '[plan].*');
    expect(_visibleOffsets(tester), [0]);
    expect(highlightedSearchText(tester, _entry(0)), ['[plan].*']);
    await _search(tester, '\u3000計劃\u3000');
    expect(_visibleOffsets(tester), [80]);
    expect(highlightedSearchText(tester, _entry(80)), ['計劃']);
    await _search(tester, '  \n\t\u3000');
    expect(_visibleOffsets(tester), [0, 40, 80, 120]);
    expect(highlightedSearchText(tester, _entry(0)), isEmpty);
    expect(find.byKey(_emptyKey), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('highlighted Unicode headings keep original UTF-16 navigation',
      (tester) async {
    const heading = 'C++ [plan].* 茶室😀 👩🏽‍💻';
    const prefix = '🙂 Preamble\n';
    const separator = '\nInterlude😀\n';
    const body = '$prefix$heading$separator$heading';
    final firstOffset = prefix.length;
    final lastOffset = body.lastIndexOf(heading);
    final entries = buildNoteOutline(body, [
      for (final offset in [firstOffset, lastOffset])
        NoteTextStyleRange(
            start: offset,
            end: offset + heading.length,
            kind: NoteTextStyleKind.heading),
    ]);
    NoteOutlineEntry? selected;
    await _pump(
        tester,
        Builder(
          builder: (context) => TextButton(
            onPressed: () async => selected = await showNoteOutlineSheet(
                context: context, entries: entries, currentOffset: lastOffset),
            child: const Text('Open outline'),
          ),
        ),
        size: const Size(280, 700),
        textScale: 2);
    await tester.tap(find.text('Open outline'));
    await tester.pumpAndSettle();
    for (final (query, highlighted) in [
      (' [PLAN].* ', '[plan].*'),
      ('茶室😀', '茶室😀'),
      ('👩', '👩🏽‍💻'),
    ]) {
      await _search(tester, query);
      expect(_visibleOffsets(tester), [firstOffset, lastOffset]);
      expect(highlightedSearchText(tester, _entry(lastOffset)), [highlighted]);
      expect(tester.widget<ListTile>(_entry(lastOffset)).selected, isTrue);
      expect(selected, isNull);
      expect(tester.takeException(), isNull);
    }
    await tester.ensureVisible(find.byKey(_clearKey));
    await tester.tap(find.byKey(_clearKey));
    await tester.pumpAndSettle();
    expect(highlightedSearchText(tester, _entry(lastOffset)), isEmpty);
    expect(tester.widget<ListTile>(_entry(lastOffset)).selected, isTrue);
    await _search(tester, '茶室😀');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.ensureVisible(_entry(lastOffset));
    await tester.pumpAndSettle();
    await tester.tap(_entry(lastOffset));
    await tester.pumpAndSettle();
    expect(selected, same(entries.last));
    expect(selected!.start, lastOffset);
    expect(selected!.end, lastOffset + heading.length);
    expect(body.substring(selected!.start, selected!.end), heading);
    expect(find.byType(NoteOutlineSheet), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('hidden current heading never transfers its indicator to a match',
      (tester) async {
    const entries = [
      NoteOutlineEntry(text: 'Shared start', start: 0, end: 12),
      NoteOutlineEntry(text: 'Private section', start: 100, end: 115),
      NoteOutlineEntry(text: 'Shared end', start: 200, end: 210),
    ];
    await _pump(
        tester, const NoteOutlineSheet(entries: entries, currentOffset: 150));
    expect(tester.widget<ListTile>(_entry(100)).selected, isTrue);
    await _search(tester, 'shared');
    expect(_visibleOffsets(tester), [0, 200]);
    expect(find.text(S.current.Note_Outline_Current), findsNothing);
    expect(tester.widget<ListTile>(_entry(0)).selected, isFalse);
    expect(tester.widget<ListTile>(_entry(200)).selected, isFalse);

    await tester.tap(find.byKey(_clearKey));
    await tester.pumpAndSettle();
    expect(_visibleOffsets(tester), [0, 100, 200]);
    expect(tester.widget<ListTile>(_entry(100)).selected, isTrue);
    expect(find.text(S.current.Note_Outline_Current), findsOneWidget);
  });

  testWidgets('matching duplicate headings return their original offsets',
      (tester) async {
    const entries = [
      NoteOutlineEntry(text: 'Same heading', start: 8, end: 20),
      NoteOutlineEntry(text: 'Other heading', start: 70, end: 83),
      NoteOutlineEntry(text: 'Same heading', start: 140, end: 152),
    ];
    NoteOutlineEntry? selected;
    await _pump(
        tester,
        Builder(
          builder: (context) => TextButton(
            onPressed: () async => selected = await showNoteOutlineSheet(
              context: context,
              entries: entries,
              currentOffset: 145,
            ),
            child: const Text('Open outline'),
          ),
        ));
    await tester.tap(find.text('Open outline'));
    await tester.pumpAndSettle();
    await _search(tester, 'same');
    expect(_visibleOffsets(tester), [8, 140]);
    expect(tester.widget<ListTile>(_entry(140)).selected, isTrue);
    await tester.tap(_entry(140));
    await tester.pumpAndSettle();
    expect(selected, same(entries.last));
    expect(selected!.start, 140);
    expect(selected!.end, 152);
    expect(find.byType(NoteOutlineSheet), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('selection callback unfocuses search and keeps the query',
      (tester) async {
    const entries = [
      NoteOutlineEntry(text: 'First heading', start: 0, end: 13),
      NoteOutlineEntry(text: 'Next heading', start: 60, end: 72),
    ];
    NoteOutlineEntry? selected;
    var offset = 0;
    await _pump(tester, StatefulBuilder(builder: (context, setState) {
      return NoteOutlineSheet(
        entries: entries,
        currentOffset: offset,
        onEntrySelected: (entry) {
          selected = entry;
          setState(() => offset = entry.start);
        },
      );
    }));
    await _search(tester, 'next');
    final editable = tester.state<EditableTextState>(find.byType(EditableText));
    expect(editable.widget.focusNode.hasFocus, isTrue);
    await tester.tap(_entry(60));
    await tester.pumpAndSettle();
    expect(selected, same(entries.last));
    expect(editable.widget.focusNode.hasFocus, isFalse);
    expect(tester.widget<TextField>(find.byKey(_searchKey)).controller!.text,
        'next');
    expect(tester.widget<ListTile>(_entry(60)).selected, isTrue);
    expect(find.byType(NoteOutlineSheet), findsOneWidget);
  });

  testWidgets('query survives outline and current offset updates',
      (tester) async {
    const original = [
      NoteOutlineEntry(text: 'Target first', start: 0, end: 12),
      NoteOutlineEntry(text: 'Hidden current', start: 50, end: 64),
    ];
    const replacement = [
      NoteOutlineEntry(text: 'Target new', start: 20, end: 30),
      NoteOutlineEntry(text: 'Target last', start: 90, end: 101),
    ];
    var entries = original;
    var offset = 55;
    late StateSetter rebuild;
    await _pump(tester, StatefulBuilder(builder: (context, setState) {
      rebuild = setState;
      return NoteOutlineSheet(entries: entries, currentOffset: offset);
    }));
    await _search(tester, 'target');
    expect(find.text(S.current.Note_Outline_Current), findsNothing);
    rebuild(() {
      entries = replacement;
      offset = 95;
    });
    await tester.pumpAndSettle();
    expect(_visibleOffsets(tester), [20, 90]);
    expect(tester.widget<ListTile>(_entry(20)).selected, isFalse);
    expect(tester.widget<ListTile>(_entry(90)).selected, isTrue);
    expect(tester.widget<TextField>(find.byKey(_searchKey)).controller!.text,
        'target');
    rebuild(() => offset = 25);
    await tester.pumpAndSettle();
    expect(tester.widget<ListTile>(_entry(20)).selected, isTrue);
    expect(tester.widget<ListTile>(_entry(90)).selected, isFalse);
  });

  testWidgets('no results is localized and clear restores the complete outline',
      (tester) async {
    const entries = [
      NoteOutlineEntry(text: '今天', start: 0, end: 2),
      NoteOutlineEntry(text: '明天', start: 10, end: 12),
    ];
    await _pump(tester, const NoteOutlineSheet(entries: entries),
        locale: const Locale('zh', 'HK'));
    expect(find.text(S.current.Note_Outline_Search), findsOneWidget);
    await _search(tester, '昨天');
    expect(find.byKey(_emptyKey), findsOneWidget);
    expect(find.text(S.current.Note_Outline_Search_Empty), findsOneWidget);
    expect(find.byTooltip(S.current.Clear_Search), findsOneWidget);
    expect(find.byType(ListTile), findsNothing);
    await tester.tap(find.byKey(_clearKey));
    await tester.pumpAndSettle();
    expect(find.byKey(_emptyKey), findsNothing);
    expect(_visibleOffsets(tester), [0, 10]);
    expect(find.byKey(_clearKey), findsNothing);
  });

  testWidgets('canceling a filtered modal returns null and reopening resets it',
      (tester) async {
    const entries = [
      NoteOutlineEntry(text: 'First', start: 0, end: 5),
      NoteOutlineEntry(text: 'Last', start: 30, end: 34),
    ];
    var completed = false;
    NoteOutlineEntry? selected = entries.first;
    await _pump(
        tester,
        Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              selected = await showNoteOutlineSheet(
                context: context,
                entries: entries,
              );
              completed = true;
            },
            child: const Text('Open outline'),
          ),
        ));
    await tester.tap(find.text('Open outline'));
    await tester.pumpAndSettle();
    await _search(tester, 'missing');
    final controller =
        tester.widget<TextField>(find.byKey(_searchKey)).controller!;
    final clear = tester.widget<IconButton>(find.byKey(_clearKey)).onPressed!;
    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    expect(completed, isTrue);
    expect(selected, isNull);
    expect(find.byType(NoteOutlineSheet), findsNothing);
    expect(() => controller.addListener(() {}), throwsFlutterError);
    expect(clear, returnsNormally);
    await tester.tap(find.text('Open outline'));
    await tester.pumpAndSettle();
    expect(
        tester.widget<TextField>(find.byKey(_searchKey)).controller!.text, '');
    expect(_visibleOffsets(tester), [0, 30]);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'narrow large text modal fits with the keyboard and empty results',
      (tester) async {
    const entries = [
      NoteOutlineEntry(text: '今天的想法與需要記住的重要細節', start: 0, end: 16),
      NoteOutlineEntry(text: '下一步與本週需要完成的事情', start: 100, end: 113),
    ];
    await _pump(
        tester,
        Builder(
          builder: (context) => TextButton(
            onPressed: () => showNoteOutlineSheet(
              context: context,
              entries: entries,
            ),
            child: const Text('Open outline'),
          ),
        ),
        locale: const Locale('zh', 'HK'),
        size: const Size(320, 640),
        textScale: 2);
    await tester.tap(find.text('Open outline'));
    await tester.pumpAndSettle();
    tester.view.viewInsets = const FakeViewPadding(bottom: 280);
    addTearDown(tester.view.resetViewInsets);
    await _search(tester, 'missing');
    expect(find.byKey(_emptyKey), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.byKey(_clearKey));
    await tester.tap(find.byKey(_clearKey));
    await tester.pumpAndSettle();
    await tester.ensureVisible(_entry(100));
    await tester.tap(_entry(100));
    await tester.pumpAndSettle();
    expect(find.byType(NoteOutlineSheet), findsNothing);
    expect(tester.takeException(), isNull);
  });

  for (final preview in [
    ('light', noteOutlinePreview),
    ('dark', noteOutlineDarkPreview),
    ('large Chinese text', noteOutlineLargeTextPreview),
  ]) {
    testWidgets('outline ${preview.$1} preview supports search and selection',
        (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 640);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(preview.$2());
      await tester.pumpAndSettle();
      await _search(
          tester, preview.$1 == 'large Chinese text' ? '下一步' : 'next');
      expect(_visibleOffsets(tester), [400]);
      await tester.ensureVisible(_entry(400));
      await tester.tap(_entry(400));
      await tester.pumpAndSettle();
      expect(tester.widget<ListTile>(_entry(400)).selected, isTrue);
      expect(find.text(S.current.Note_Outline_Current), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
