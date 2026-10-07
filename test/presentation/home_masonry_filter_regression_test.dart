import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/presentation/components/note_card_entrance.dart';

class _NoteShape {
  const _NoteShape(this.id, this.height, {required this.checklist});
  final String id;
  final double height;
  final bool checklist;
}

const _notes = [
  _NoteShape('packing', 311, checklist: true),
  _NoteShape('daily', 150, checklist: false),
  _NoteShape('mixed', 431, checklist: true),
];

class _FilteredMasonry extends StatefulWidget {
  const _FilteredMasonry({this.notes = _notes});

  final List<_NoteShape> notes;

  @override
  State<_FilteredMasonry> createState() => _FilteredMasonryState();
}

class _FilteredMasonryState extends State<_FilteredMasonry> {
  bool _checklists = false;
  bool _reordered = false;
  final _hiddenIds = <String>{};
  late final _cardKeys = {
    for (final note in widget.notes)
      note.id: GlobalKey<_StatefulNoteCardState>(),
  };

  void _setHiddenIds(Set<String> ids) => setState(() {
        _hiddenIds
          ..clear()
          ..addAll(ids);
      });

  @override
  Widget build(BuildContext context) {
    final notes = [
      for (final note in widget.notes)
        if ((!_checklists || note.checklist) && !_hiddenIds.contains(note.id))
          note,
    ];
    if (_reordered) {
      for (var index = 0; index + 1 < notes.length; index += 2) {
        final first = notes[index];
        notes[index] = notes[index + 1];
        notes[index + 1] = first;
      }
    }
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FilterChip(
                  key: const ValueKey('masonry-checklists-filter'),
                  label: const Text('Checklists'),
                  selected: _checklists,
                  onSelected: (selected) =>
                      setState(() => _checklists = selected),
                ),
                IconButton(
                  key: const ValueKey('masonry-reorder'),
                  tooltip: 'Reorder notes',
                  icon: const Icon(Icons.swap_vert),
                  onPressed: () => setState(() => _reordered = !_reordered),
                ),
                IconButton(
                  key: const ValueKey('masonry-rebuild'),
                  tooltip: 'Refresh notes',
                  icon: const Icon(Icons.refresh),
                  onPressed: () => setState(() {}),
                ),
              ],
            ),
            Expanded(
              child: CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.all(20),
                    sliver: SliverMasonryGrid(
                      gridDelegate:
                          const SliverSimpleGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2),
                      mainAxisSpacing: 20,
                      crossAxisSpacing: 16,
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final note = notes[index];
                          return KeyedSubtree(
                            key: ValueKey(index),
                            child: NoteCardEntrance(
                              child: _StatefulNoteCard(
                                key: _cardKeys[note.id],
                                note: note,
                              ),
                            ),
                          );
                        },
                        childCount: notes.length,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatefulNoteCard extends StatefulWidget {
  const _StatefulNoteCard({super.key, required this.note});

  final _NoteShape note;

  @override
  State<_StatefulNoteCard> createState() => _StatefulNoteCardState();
}

class _StatefulNoteCardState extends State<_StatefulNoteCard> {
  bool _selected = false;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: widget.note.height,
        child: Semantics(
          container: true,
          label: '${widget.note.id} note',
          selected: _selected,
          child: GestureDetector(
            onTap: () => setState(() => _selected = !_selected),
            child: ColoredBox(
              color: widget.note.checklist
                  ? Colors.orange.shade100
                  : Colors.blue.shade100,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Text(widget.note.id),
              ),
            ),
          ),
        ),
      );
}

Future<void> _pumpFrames(WidgetTester tester) async {
  await tester.pump();
  expect(tester.takeException(), isNull, reason: 'First masonry update frame');
  for (var frame = 0; frame < 24; frame++) {
    await tester.pump(const Duration(milliseconds: 16));
    expect(tester.takeException(), isNull,
        reason: 'Masonry animation frame $frame');
  }
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull, reason: 'Settled masonry update');
}

void main() {
  testWidgets(
      'three keyed masonry notes survive removing the short middle note',
      (tester) async {
    final originalPlatform = debugDefaultTargetPlatformOverride;
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    final semantics = tester.ensureSemantics();
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    try {
      await tester.pumpWidget(MaterialApp(
        theme: ThemeData(platform: TargetPlatform.iOS),
        home: const _FilteredMasonry(),
      ));
      await _pumpFrames(tester);
      final fixture =
          tester.state<_FilteredMasonryState>(find.byType(_FilteredMasonry));
      for (final note in _notes) {
        expect(tester.getSize(find.byKey(fixture._cardKeys[note.id]!)).height,
            note.height);
      }

      for (var cycle = 0; cycle < 3; cycle++) {
        for (final filtered in [true, false]) {
          final packingState = fixture._cardKeys['packing']!.currentState;
          final mixedState = fixture._cardKeys['mixed']!.currentState;
          await tester
              .tap(find.byKey(const ValueKey('masonry-checklists-filter')));
          await _pumpFrames(tester);
          expect(
              tester
                  .widget<FilterChip>(
                      find.byKey(const ValueKey('masonry-checklists-filter')))
                  .selected,
              filtered);
          expect(find.byKey(fixture._cardKeys['packing']!), findsOneWidget);
          expect(find.byKey(fixture._cardKeys['mixed']!), findsOneWidget);
          expect(find.byKey(fixture._cardKeys['daily']!),
              filtered ? findsNothing : findsOneWidget);
          expect(
              fixture._cardKeys['packing']!.currentState, same(packingState));
          expect(fixture._cardKeys['mixed']!.currentState, same(mixedState));
          final scroll =
              Scrollable.of(tester.element(find.byType(SliverMasonryGrid)))
                  .position;
          expect(scroll.pixels, 0);
          expect(tester.takeException(), isNull,
              reason: 'Middle note restoration cycle $cycle');
        }
      }
    } finally {
      semantics.dispose();
      debugDefaultTargetPlatformOverride = originalPlatform;
    }
  });

  testWidgets('masonry reordering preserves scroll and mounted card state',
      (tester) async {
    final semantics = tester.ensureSemantics();
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    try {
      final notes = [
        for (var index = 0; index < 24; index++)
          _NoteShape('note-$index', 180.0 + (index % 5) * 30.0,
              checklist: index.isEven),
      ];
      await tester.pumpWidget(MaterialApp(
        home: _FilteredMasonry(notes: notes),
      ));
      await _pumpFrames(tester);
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -620));
      await _pumpFrames(tester);

      final fixture =
          tester.state<_FilteredMasonryState>(find.byType(_FilteredMasonry));
      final scroll =
          Scrollable.of(tester.element(find.byType(SliverMasonryGrid)))
              .position;
      final scrollOffset = scroll.pixels;
      expect(scrollOffset, greaterThan(0));
      final visibleCard = find.byType(_StatefulNoteCard).hitTestable().first;
      final selectedState = tester.state<_StatefulNoteCardState>(visibleCard);
      await tester.tap(visibleCard);
      await _pumpFrames(tester);
      expect(selectedState._selected, isTrue);

      final initialGrid = tester.renderObject(find.byType(SliverMasonryGrid));
      await tester.tap(find.byKey(const ValueKey('masonry-rebuild')));
      await _pumpFrames(tester);
      expect(tester.renderObject(find.byType(SliverMasonryGrid)),
          same(initialGrid),
          reason: 'Content updates with the same order reuse masonry layout');
      expect(scroll.pixels, scrollOffset);

      for (var cycle = 0; cycle < 2; cycle++) {
        final cardStates = {
          for (final entry in fixture._cardKeys.entries)
            if (entry.value.currentState != null)
              entry.key: entry.value.currentState!,
        };
        final previousGrid =
            tester.renderObject(find.byType(SliverMasonryGrid));
        await tester.tap(find.byKey(const ValueKey('masonry-reorder')));
        await _pumpFrames(tester);
        expect(tester.renderObject(find.byType(SliverMasonryGrid)),
            same(previousGrid),
            reason: 'Moving cards keeps the masonry viewport stable');
        expect(
            Scrollable.of(tester.element(find.byType(SliverMasonryGrid)))
                .position,
            same(scroll));
        expect(scroll.pixels, scrollOffset);
        final survivingCards = cardStates.entries.where(
            (entry) => fixture._cardKeys[entry.key]!.currentState != null);
        expect(survivingCards.length, greaterThan(2));
        for (final entry in survivingCards) {
          expect(fixture._cardKeys[entry.key]!.currentState, same(entry.value),
              reason: '${entry.key} keeps its state across order changes');
        }
        expect(selectedState.mounted, isTrue);
        expect(selectedState._selected, isTrue);
      }

      final visibleIds = find
          .byType(_StatefulNoteCard)
          .hitTestable()
          .evaluate()
          .map((element) => (element.widget as _StatefulNoteCard).note.id)
          .where((id) => id != selectedState.widget.note.id)
          .toList();
      expect(visibleIds, isNotEmpty);
      final hiddenIds = {
        notes.first.id,
        visibleIds[visibleIds.length ~/ 2],
      };
      expect(hiddenIds.length, 2);
      for (final hideNotes in [true, false]) {
        fixture._setHiddenIds(hideNotes ? hiddenIds : {});
        await _pumpFrames(tester);
        expect(
            Scrollable.of(tester.element(find.byType(SliverMasonryGrid)))
                .position,
            same(scroll));
        expect(scroll.pixels, scrollOffset,
            reason: 'Membership changes preserve the current scroll offset');
        expect(selectedState.mounted, isTrue);
        expect(fixture._cardKeys[selectedState.widget.note.id]!.currentState,
            same(selectedState));
        expect(selectedState._selected, isTrue);
        if (hideNotes) {
          for (final id in hiddenIds) {
            expect(find.byKey(fixture._cardKeys[id]!), findsNothing);
          }
        }
      }

      scroll.jumpTo(0);
      await _pumpFrames(tester);
      expect(find.byKey(fixture._cardKeys[notes.first.id]!), findsOneWidget);
      for (final id in hiddenIds) {
        final restoredCard = find.byKey(fixture._cardKeys[id]!);
        await tester.scrollUntilVisible(restoredCard, 200,
            scrollable: find.byType(Scrollable));
        await _pumpFrames(tester);
        expect(restoredCard, findsOneWidget,
            reason: '$id returns after clearing the membership filter');
      }
    } finally {
      semantics.dispose();
    }
  });
}
