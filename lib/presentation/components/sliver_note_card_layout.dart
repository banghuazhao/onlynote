import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

/// Lazy card placement with natural heights and optional individual widths.
/// Uniform sizes retain masonry; mixed sizes are packed into ordered rows.
class SliverNoteCardLayout extends StatefulWidget {
  const SliverNoteCardLayout({
    super.key,
    required this.columns,
    required this.itemBuilder,
    this.mainAxisSpacing = 16,
    this.crossAxisSpacing = 12,
  });

  /// Each card's desired share of the available width (1, 1/2, 1/3, ...).
  final List<int> columns;
  final IndexedWidgetBuilder itemBuilder;
  final double mainAxisSpacing;
  final double crossAxisSpacing;

  @override
  State<SliverNoteCardLayout> createState() => _SliverNoteCardLayoutState();
}

class _SliverNoteCardLayoutState extends State<SliverNoteCardLayout> {
  double? _rowWidth;
  List<List<NoteCardRowItem>>? _rows;
  Widget? _mixedSliver;

  @override
  void didUpdateWidget(covariant SliverNoteCardLayout oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(oldWidget.columns, widget.columns) ||
        oldWidget.crossAxisSpacing != widget.crossAxisSpacing) {
      _rows = null;
    }
    // Refresh card content on library changes, without repacking on scroll.
    _mixedSliver = null;
  }

  Widget _buildCard(BuildContext context, int index) => KeyedSubtree(
        // Placement belongs to the slot; the card owns its note identity.
        key: ValueKey(index),
        child: widget.itemBuilder(context, index),
      );

  @override
  Widget build(BuildContext context) {
    final uniformColumns = widget.columns.isEmpty ? 1 : widget.columns.first;
    if (widget.columns.every((count) => count == uniformColumns)) {
      return SliverMasonryGrid(
        gridDelegate: SliverSimpleGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: uniformColumns,
        ),
        mainAxisSpacing: widget.mainAxisSpacing,
        crossAxisSpacing: widget.crossAxisSpacing,
        delegate: SliverChildBuilderDelegate(
          _buildCard,
          childCount: widget.columns.length,
        ),
      );
    }

    return SliverLayoutBuilder(builder: (context, constraints) {
      final width = constraints.crossAxisExtent;
      if (_rows == null || _rowWidth != width) {
        _rows = packNoteCardRows(
          width: width,
          columns: widget.columns,
          spacing: widget.crossAxisSpacing,
        );
        _rowWidth = width;
        _mixedSliver = null;
      }
      final rows = _rows!;
      return _mixedSliver ??= SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, rowIndex) => Padding(
            key: ValueKey(rowIndex),
            padding: EdgeInsets.only(
              bottom: rowIndex == rows.length - 1 ? 0 : widget.mainAxisSpacing,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var position = 0;
                    position < rows[rowIndex].length;
                    position++) ...[
                  if (position > 0) SizedBox(width: widget.crossAxisSpacing),
                  SizedBox(
                    width: rows[rowIndex][position].width,
                    child: IndexedSemantics(
                      index: rows[rowIndex][position].index,
                      child: _buildCard(
                        context,
                        rows[rowIndex][position].index,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          childCount: rows.length,
          // A mixed row contains several separately indexed cards.
          addSemanticIndexes: false,
        ),
      );
    });
  }
}

class NoteCardRowItem {
  const NoteCardRowItem({required this.index, required this.width});

  final int index;
  final double width;
}

/// Preserve library order while filling rows with each card's requested width.
List<List<NoteCardRowItem>> packNoteCardRows({
  required double width,
  required List<int> columns,
  required double spacing,
}) {
  final rows = <List<NoteCardRowItem>>[];
  var row = <NoteCardRowItem>[];
  var occupied = 0.0;
  for (var index = 0; index < columns.length; index++) {
    final count = columns[index];
    final cardWidth =
        ((width - spacing * (count - 1)) / count).clamp(0.0, width).toDouble();
    final nextWidth = occupied + (row.isEmpty ? 0 : spacing) + cardWidth;
    if (row.isNotEmpty && nextWidth > width + 0.001) {
      rows.add(row);
      row = [];
      occupied = 0;
    }
    occupied += (row.isEmpty ? 0 : spacing) + cardWidth;
    row.add(NoteCardRowItem(index: index, width: cardWidth));
  }
  if (row.isNotEmpty) rows.add(row);
  return rows;
}
