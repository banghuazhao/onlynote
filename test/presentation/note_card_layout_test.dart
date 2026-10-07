import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/presentation/components/note_card_entrance.dart';
import 'package:onlynote/presentation/components/sliver_note_card_layout.dart';
import 'package:onlynote/presentation/theme/note_grid_layout.dart';

class _CardSpec {
  const _CardSpec(this.id, this.columns, this.height);
  final String id;
  final int columns;
  final double height;
}

class _Library extends StatefulWidget {
  const _Library({required this.cards});
  final List<_CardSpec> cards;

  @override
  State<_Library> createState() => _LibraryState();
}

class _LibraryState extends State<_Library> {
  final scroll = ScrollController();
  final cardKeys = <String, GlobalKey<_CardState>>{};
  final builtIds = <String>{};
  final hiddenIds = <String>{};
  bool reverse = false;
  final columnOverrides = <String, int>{};

  void update(VoidCallback mutation) => setState(mutation);

  @override
  void dispose() {
    scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cards =
        widget.cards.where((card) => !hiddenIds.contains(card.id)).toList();
    if (reverse) cards.setAll(0, cards.reversed.toList());
    return CustomScrollView(
      controller: scroll,
      semanticChildCount: cards.length,
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverNoteCardLayout(
            columns: [
              for (final card in cards)
                columnOverrides[card.id] ?? card.columns,
            ],
            itemBuilder: (context, index) {
              final card = cards[index];
              builtIds.add(card.id);
              return NoteCardEntrance(
                child: _Card(
                  key: cardKeys.putIfAbsent(
                    card.id,
                    () => GlobalKey<_CardState>(),
                  ),
                  spec: card,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _Card extends StatefulWidget {
  const _Card({super.key, required this.spec});
  final _CardSpec spec;

  @override
  State<_Card> createState() => _CardState();
}

class _CardState extends State<_Card> {
  bool selected = false;

  @override
  Widget build(BuildContext context) => Semantics(
        container: true,
        label: widget.spec.id,
        selected: selected,
        child: GestureDetector(
          onTap: () => setState(() => selected = !selected),
          child: SizedBox(
            height: widget.spec.height,
            child: ColoredBox(
              color: selected ? Colors.blue : Colors.amber,
              child: Center(child: Text(widget.spec.id)),
            ),
          ),
        ),
      );
}

Future<_LibraryState> _open(
  WidgetTester tester,
  List<_CardSpec> cards, {
  double width = 390,
}) async {
  tester.view.physicalSize = Size(width, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester
      .pumpWidget(MaterialApp(home: Scaffold(body: _Library(cards: cards))));
  await _frames(tester);
  return tester.state<_LibraryState>(find.byType(_Library));
}

Future<void> _frames(WidgetTester tester) async {
  await tester.pump();
  expect(tester.takeException(), isNull);
  for (var frame = 0; frame < 16; frame++) {
    await tester.pump(const Duration(milliseconds: 16));
    expect(tester.takeException(), isNull,
        reason: 'Layout update frame $frame');
  }
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

void main() {
  testWidgets(
      'individual card sizes use actual widths and preserve library order',
      (tester) async {
    final library = await _open(tester, const [
      _CardSpec('half', 2, 180),
      _CardSpec('full', 1, 140),
      _CardSpec('third-one', 3, 100),
      _CardSpec('third-two', 3, 200),
      _CardSpec('third-three', 3, 160),
    ]);
    Size size(String id) => tester.getSize(find.byKey(library.cardKeys[id]!));
    Offset top(String id) =>
        tester.getTopLeft(find.byKey(library.cardKeys[id]!));
    expect(size('full').width, 358);
    expect(size('half').width, 173);
    expect(size('third-one').width, closeTo(334 / 3, .001));
    expect(top('full').dy, greaterThan(top('half').dy));
    expect(top('third-one').dy, greaterThan(top('full').dy));
    expect(top('third-one').dy, top('third-two').dy);
    expect(top('third-two').dy, top('third-three').dy);
    expect(top('third-one').dx, lessThan(top('third-two').dx));
    expect(top('third-two').dx, lessThan(top('third-three').dx));
  });

  testWidgets(
      'filter restoration and resizing retain mounted card state and semantics',
      (tester) async {
    final library = await _open(tester, const [
      _CardSpec('packing', 2, 220),
      _CardSpec('daily', 1, 90),
      _CardSpec('mixed', 2, 300),
    ]);
    final packing = library.cardKeys['packing']!.currentState!;
    final mixed = library.cardKeys['mixed']!.currentState!;
    await tester.tap(find.byKey(library.cardKeys['mixed']!));
    await _frames(tester);
    expect(mixed.selected, isTrue);
    final position = library.scroll.position;
    for (var cycle = 0; cycle < 3; cycle++) {
      library.update(() => library.hiddenIds.add('daily'));
      await _frames(tester);
      expect(find.byType(SliverMasonryGrid), findsOneWidget);
      expect(find.byKey(library.cardKeys['daily']!), findsNothing);
      expect(library.cardKeys['packing']!.currentState, same(packing));
      expect(library.cardKeys['mixed']!.currentState, same(mixed));
      library.update(() => library.hiddenIds.clear());
      await _frames(tester);
      expect(find.byType(SliverMasonryGrid), findsNothing);
      expect(find.byKey(library.cardKeys['daily']!), findsOneWidget);
      expect(library.cardKeys['packing']!.currentState, same(packing));
      expect(library.cardKeys['mixed']!.currentState, same(mixed));
      expect(mixed.selected, isTrue);
      expect(library.scroll.position, same(position));
    }
    library.update(() => library.columnOverrides['mixed'] = 1);
    await _frames(tester);
    expect(tester.getSize(find.byKey(library.cardKeys['mixed']!)).width, 358);
    expect(library.cardKeys['mixed']!.currentState, same(mixed));
    library.update(() => library.reverse = true);
    await _frames(tester);
    expect(library.cardKeys['packing']!.currentState, same(packing));
    expect(library.cardKeys['mixed']!.currentState, same(mixed));
  });

  testWidgets('mixed card rows build lazily and keep scrolling when refreshed',
      (tester) async {
    final library = await _open(tester, [
      for (var index = 0; index < 180; index++)
        _CardSpec('note-$index', index % 5 == 0 ? 1 : 2, 180),
    ]);
    expect(library.builtIds.length, lessThan(20));
    expect(library.builtIds.contains('note-179'), isFalse);
    library.scroll.jumpTo(650);
    await _frames(tester);
    final position = library.scroll.position;
    library.update(() {});
    await _frames(tester);
    expect(library.scroll.position, same(position));
    expect(library.scroll.offset, 650);
    expect(library.builtIds.length, lessThan(30));
  });

  testWidgets(
      'large accessible text keeps resized cards within a narrow screen',
      (tester) async {
    final columns = [
      for (final preferred in [3, 2, 1])
        noteGridColumns(
          width: 320,
          textScaler: const TextScaler.linear(2),
          preferredColumns: preferred,
          appFontScale: 1.2,
        ),
    ];
    final library = await _open(
        tester,
        [
          for (var index = 0; index < columns.length; index++)
            _CardSpec('note-$index', columns[index], 120),
        ],
        width: 320);
    for (var index = 0; index < columns.length; index++) {
      final bounds =
          tester.getRect(find.byKey(library.cardKeys['note-$index']!));
      expect(bounds.width, 288);
      expect(bounds.left, 16);
      expect(bounds.right, 304);
    }
  });
}
