import 'dart:ui' show SemanticsAction;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/library_filter_labels.dart';
import 'package:onlynote/presentation/components/note_active_criteria_summary.dart';
import 'package:onlynote/services/note_search.dart';
import 'package:onlynote/services/note_tags.dart';

Widget _host(Widget child,
        {Locale locale = const Locale('en'), double textScale = 1}) =>
    MaterialApp(
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
          textScaler: TextScaler.linear(textScale),
          disableAnimations: true,
        ),
        child: child!,
      ),
      home: Scaffold(body: Align(alignment: Alignment.topLeft, child: child)),
    );

Finder _key(String value) => find.byKey(ValueKey(value));

Finder _deleteTarget(WidgetTester tester, String key, String tooltip) {
  final deleteTooltip =
      find.descendant(of: _key(key), matching: find.byTooltip(tooltip));
  final target =
      find.descendant(of: deleteTooltip, matching: _key('$key-delete-target'));
  expect(target, findsOneWidget);
  final renderedSize = tester.getSize(target);
  expect(renderedSize.width, greaterThanOrEqualTo(48), reason: tooltip);
  expect(renderedSize.height, greaterThanOrEqualTo(48), reason: tooltip);
  return target;
}

Future<void> _tapDeleteEdge(WidgetTester tester, Finder target) async {
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  final edge = tester.getCenter(target) + const Offset(18, 0);
  expect(tester.getRect(target).contains(edge), isTrue);
  final icon = find.descendant(of: target, matching: find.byType(Icon));
  expect(icon, findsOneWidget);
  expect(tester.getRect(icon).contains(edge), isFalse);
  await tester.tapAt(edge);
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

Future<void> _remove(WidgetTester tester, String key, String label) async {
  final chip = _key(key);
  await tester.ensureVisible(chip);
  await tester.pumpAndSettle();
  final tooltip = S.current.Remove_Library_Criterion(label);
  expect(tester.widget<InputChip>(chip).deleteButtonTooltipMessage, tooltip);
  await _tapDeleteEdge(tester, _deleteTarget(tester, key, tooltip));
}

void main() {
  testWidgets('empty criteria reserve no summary row or chips', (tester) async {
    await tester.pumpWidget(_host(NoteActiveCriteriaSummary(
      filters: const {},
      tags: const {},
      onRemoveFilter: (_) => fail('No filter is selected'),
      onRemoveTag: (_) => fail('No tag is selected'),
    )));
    await tester.pumpAndSettle();
    expect(_key('home-active-criteria-summary'), findsNothing);
    expect(find.byType(InputChip), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows selected criteria and reports deletion without mutation',
      (tester) async {
    final filters = <NoteSearchFilter>{
      NoteSearchFilter.pinned,
      NoteSearchFilter.recordings,
      NoteSearchFilter.scans,
    };
    final tags = <String>{'Research', '项目'};
    final originalFilters = Set<NoteSearchFilter>.of(filters);
    final originalTags = Set<String>.of(tags);
    final removedFilters = <NoteSearchFilter>[];
    final removedTags = <String>[];
    var removedScope = 0;
    await tester.pumpWidget(_host(NoteActiveCriteriaSummary(
      filters: filters,
      tags: tags,
      includeArchived: true,
      onRemoveFilter: removedFilters.add,
      onRemoveTag: removedTags.add,
      onRemoveIncludeArchived: () => removedScope++,
    )));
    await tester.pumpAndSettle();

    expect(_key('home-active-criteria-summary'), findsOneWidget);
    expect(find.byType(InputChip), findsNWidgets(6));
    for (final filter in NoteSearchFilter.values) {
      expect(_key('active-filter-${filter.name}'),
          filters.contains(filter) ? findsOneWidget : findsNothing);
    }
    for (final filter in filters) {
      await _remove(tester, 'active-filter-${filter.name}',
          noteSearchFilterLabel(filter, S.current));
    }
    for (final tag in tags) {
      await _remove(
          tester, 'active-tag-${tagKey(tag)}', '${S.current.Tags}: $tag');
    }
    await _remove(
        tester, 'active-scope-include-archived', S.current.Include_Archived);

    expect(removedFilters, filters.toList());
    expect(removedTags, tags.toList());
    expect(removedScope, 1);
    expect(filters, originalFilters);
    expect(tags, originalTags);
    expect(find.byType(InputChip), findsNWidgets(6));
  });

  testWidgets('parent removes just one criterion until the summary disappears',
      (tester) async {
    var filters = <NoteSearchFilter>{
      NoteSearchFilter.pinned,
      NoteSearchFilter.recordings,
    };
    var tags = <String>{'Research'};
    var includeArchived = true;
    await tester.pumpWidget(_host(StatefulBuilder(
      builder: (context, setState) => NoteActiveCriteriaSummary(
        filters: filters,
        tags: tags,
        includeArchived: includeArchived,
        onRemoveFilter: (filter) =>
            setState(() => filters = {...filters}..remove(filter)),
        onRemoveTag: (tag) => setState(() => tags = {
              for (final selected in tags)
                if (tagKey(selected) != tagKey(tag)) selected,
            }),
        onRemoveIncludeArchived: () => setState(() => includeArchived = false),
      ),
    )));
    await tester.pumpAndSettle();
    await _remove(tester, 'active-filter-pinned', S.current.Filter_Pinned);
    expect(_key('active-filter-pinned'), findsNothing);
    expect(_key('active-filter-recordings'), findsOneWidget);
    expect(_key('active-tag-research'), findsOneWidget);
    expect(_key('active-scope-include-archived'), findsOneWidget);
    await _remove(tester, 'active-tag-research', '${S.current.Tags}: Research');
    expect(_key('active-tag-research'), findsNothing);
    expect(_key('active-filter-recordings'), findsOneWidget);
    expect(_key('active-scope-include-archived'), findsOneWidget);
    await _remove(
        tester, 'active-scope-include-archived', S.current.Include_Archived);
    expect(_key('active-scope-include-archived'), findsNothing);
    expect(_key('active-filter-recordings'), findsOneWidget);
    await _remove(
        tester, 'active-filter-recordings', S.current.Filter_Recordings);
    expect(_key('home-active-criteria-summary'), findsNothing);
    expect(find.byType(InputChip), findsNothing);
  });

  for (final locale in S.delegate.supportedLocales) {
    for (final size in [const Size(180, 320), const Size(320, 180)]) {
      testWidgets('localized removals scroll at 2x text in $locale at $size',
          (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final semantics = tester.ensureSemantics();
        try {
          final filters = NoteSearchFilter.values.toSet();
          final tags = {'Research', '個人工作計劃' * 6};
          final removedFilters = <NoteSearchFilter>[];
          final removedTags = <String>[];
          var removedScope = 0;
          await tester.pumpWidget(_host(
            NoteActiveCriteriaSummary(
              filters: filters,
              tags: tags,
              includeArchived: true,
              onRemoveFilter: removedFilters.add,
              onRemoveTag: removedTags.add,
              onRemoveIncludeArchived: () => removedScope++,
            ),
            locale: locale,
            textScale: 2,
          ));
          await tester.pumpAndSettle();
          final summary = _key('home-active-criteria-summary');
          final scrollable =
              find.descendant(of: summary, matching: find.byType(Scrollable));
          expect(scrollable, findsOneWidget);
          final position = tester.state<ScrollableState>(scrollable).position;
          expect(position.axis, Axis.horizontal);
          expect(position.maxScrollExtent, greaterThan(0));

          for (final (key, label) in [
            for (final filter in filters)
              (
                'active-filter-${filter.name}',
                noteSearchFilterLabel(filter, S.current),
              ),
            for (final tag in tags)
              ('active-tag-${tagKey(tag)}', '${S.current.Tags}: $tag'),
            ('active-scope-include-archived', S.current.Include_Archived),
          ]) {
            final chip = _key(key);
            await tester.ensureVisible(chip);
            await tester.pumpAndSettle();
            final tooltip = S.current.Remove_Library_Criterion(label);
            expect(tester.widget<InputChip>(chip).deleteButtonTooltipMessage,
                tooltip);
            final target = _deleteTarget(tester, key, tooltip);
            await tester.ensureVisible(target);
            await tester.pumpAndSettle();
            final data = tester.getSemantics(target).getSemanticsData();
            expect(data.tooltip, contains(tooltip));
            expect(data.hasAction(SemanticsAction.tap), isTrue);
            await _tapDeleteEdge(tester, target);
            expect(tester.takeException(), isNull);
          }
          expect(removedFilters, filters.toList());
          expect(removedTags, tags.toList());
          expect(removedScope, 1);
          expect(position.pixels, greaterThan(0));
          await tester.drag(summary, const Offset(120, 0));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        } finally {
          semantics.dispose();
        }
      });
    }
  }
}
