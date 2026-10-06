import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:onlynote/services/note_position_store.dart';

/// Reads and restores the rendered document's content position. Owners attach
/// while mounted; captures inspect native glyphs without touching selection or
/// focus, and restoration never animates or opens the keyboard.
class NoteReaderPositionController {
  Object? _owner;
  NoteReadingPosition? Function()? _capture;
  Future<bool> Function(NoteReadingPosition, bool Function())? _restore;
  var _generation = 0;

  VoidCallback attach({
    required Object owner,
    required NoteReadingPosition? Function() capture,
    required Future<bool> Function(NoteReadingPosition, bool Function())
        restore,
  }) {
    cancelPendingRestore();
    _owner = owner;
    _capture = capture;
    _restore = restore;
    return () {
      if (!identical(_owner, owner)) return;
      cancelPendingRestore();
      _owner = null;
      _capture = null;
      _restore = null;
    };
  }

  NoteReadingPosition? capture() => _capture?.call();

  Future<bool> restore(NoteReadingPosition position,
      {bool Function()? canRestore}) async {
    final restore = _restore;
    if (restore == null) return false;
    final generation = ++_generation;
    bool allowed() => generation == _generation && (canRestore?.call() ?? true);
    if (!allowed()) return false;
    return restore(position, allowed);
  }

  /// Call when the reader starts a gesture, Find or another explicit jump so
  /// a delayed initial restoration cannot overwrite the user's navigation.
  void cancelPendingRestore() => _generation++;

  void dispose() {
    cancelPendingRestore();
    _owner = null;
    _capture = null;
    _restore = null;
  }
}

/// A native text renderer can be selectable text, ordinary rich text or Find's
/// highlighted text. All measurements come from the actual current layout.
class NoteReaderGlyph {
  const NoteReaderGlyph(this.render, this.length);
  final RenderBox render;
  final int length;

  static NoteReaderGlyph? fromContext(BuildContext context) {
    final root = context.findRenderObject();
    if (root == null || !root.attached) return null;
    NoteReaderGlyph? result;
    void visit(RenderObject object) {
      if (result != null) return;
      if (object is RenderEditable && object.hasSize) {
        result =
            NoteReaderGlyph(object, object.text?.toPlainText().length ?? 0);
      } else if (object is RenderParagraph && object.hasSize) {
        result = NoteReaderGlyph(object, object.text.toPlainText().length);
      } else {
        object.visitChildren(visit);
      }
    }

    visit(root);
    return result;
  }

  Rect get globalBounds => render.localToGlobal(Offset.zero) & render.size;

  int positionNearTop(double globalTop, TextDirection direction) {
    final bounds = globalBounds;
    final object = render;
    int offsetAt(double top) {
      final point = Offset(
        direction == TextDirection.rtl ? bounds.right - 1 : bounds.left + 1,
        top.clamp(bounds.top, math.max(bounds.top, bounds.bottom - 1)),
      );
      return switch (object) {
        RenderEditable() => object.getPositionForPoint(point).offset,
        RenderParagraph() =>
          object.getPositionForOffset(object.globalToLocal(point)).offset,
        _ => 0,
      };
    }

    var best = offsetAt(globalTop);
    final rect = globalRectForOffset(best);
    if (rect == null) return best;
    var distance = (rect.top - globalTop).abs();
    // Hit testing at the viewport edge can select a partly hidden preceding
    // line even when the next line starts closer to that edge. Compare the
    // adjacent native line positions using their actual rendered geometry.
    final lineHeight = rect.height > 0
        ? rect.height
        : switch (object) {
            RenderEditable() => object.preferredLineHeight,
            RenderParagraph() =>
              object.getFullHeightForCaret(TextPosition(offset: best)),
            _ => 1.0,
          };
    for (final top in [
      rect.top - lineHeight / 2,
      rect.bottom + lineHeight / 2,
    ]) {
      final candidate = offsetAt(top);
      final candidateRect = globalRectForOffset(candidate);
      if (candidateRect == null) continue;
      final gap = (candidateRect.top - globalTop).abs();
      if (gap < distance) {
        best = candidate;
        distance = gap;
      }
    }
    return best;
  }

  Rect? globalRectForOffset(int offset) {
    final object = render;
    Rect? rect;
    if (object is RenderEditable) {
      rect = object
          .getLocalRectForCaret(TextPosition(offset: offset.clamp(0, length)));
    } else if (object is RenderParagraph && length > 0) {
      final text = object.text.toPlainText();
      final start = clampNotePositionOffset(text, offset.clamp(0, length - 1));
      final end = clampNotePositionOffset(text, start + 1, roundUp: true);
      final boxes = object.getBoxesForSelection(
          TextSelection(baseOffset: start, extentOffset: end));
      if (boxes.isNotEmpty) rect = boxes.first.toRect();
    }
    return rect?.shift(object.localToGlobal(Offset.zero));
  }
}

/// The document's enclosing scroll view includes title/checklist content as
/// well, so a glyph below or above the viewport can preserve that reading spot.
class NoteReaderViewport {
  const NoteReaderViewport._(this.scrollable, this.bounds);
  final ScrollableState scrollable;
  final Rect bounds;

  static NoteReaderViewport? fromContext(BuildContext context) {
    final scrollable = Scrollable.maybeOf(context, axis: Axis.vertical);
    final box = scrollable?.context.findRenderObject();
    if (scrollable == null || box is! RenderBox || !box.hasSize) return null;
    return NoteReaderViewport._(
        scrollable, box.localToGlobal(Offset.zero) & box.size);
  }

  bool restoreTop(double globalTop, double leadingDisplacement) {
    final position = scrollable.position;
    if (!position.hasContentDimensions || !globalTop.isFinite) return false;
    final delta = globalTop - bounds.top - leadingDisplacement;
    final direction = position.axisDirection == AxisDirection.up ? -1 : 1;
    final target = (position.pixels + delta * direction)
        .clamp(position.minScrollExtent, position.maxScrollExtent);
    position.jumpTo(target);
    return true;
  }
}
