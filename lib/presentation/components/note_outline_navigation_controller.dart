import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Connects a contextual outline action to the current editor or reader.
/// Navigation changes the caret and viewport, never note content.
class NoteOutlineNavigationController {
  Object? _owner;
  Future<bool> Function(int offset)? _jump;
  Future<bool> Function(int offset, {bool Function()? canRestore})? _restore;

  VoidCallback attach({
    required Object owner,
    required Future<bool> Function(int offset) jump,
    Future<bool> Function(int offset, {bool Function()? canRestore})? restore,
  }) {
    _owner = owner;
    _jump = jump;
    _restore = restore;
    return () {
      if (identical(_owner, owner)) {
        _owner = null;
        _jump = null;
        _restore = null;
      }
    };
  }

  Future<bool> jumpTo(int textOffset) async {
    if (textOffset < 0) return false;
    return await _jump?.call(textOffset) ?? false;
  }

  /// Restores a saved inactive caret without opening the keyboard.
  Future<bool> restoreTo(int textOffset, {bool Function()? canRestore}) async {
    if (textOffset < 0 || canRestore?.call() == false) return false;
    return await _restore?.call(textOffset, canRestore: canRestore) ?? false;
  }

  void dispose() {
    _owner = null;
    _jump = null;
    _restore = null;
  }
}

/// Finds the native text renderer inside a field or selectable paragraph.
/// Using its actual glyph rect keeps jumps accurate with large text, wrapping,
/// right-to-left text and images above the paragraph.
bool revealNoteTextOffset(BuildContext context, int textOffset,
    {bool animate = true}) {
  final root = context.findRenderObject();
  if (root == null || !root.attached) return false;
  RenderObject? target;
  Rect? rect;
  void visit(RenderObject object) {
    if (target != null) return;
    if (object is RenderEditable && object.hasSize) {
      final length = object.text?.toPlainText().length ?? 0;
      target = object;
      rect = object.getLocalRectForCaret(
          TextPosition(offset: textOffset.clamp(0, length)));
    } else if (object is RenderParagraph && object.hasSize) {
      final length = object.text.toPlainText().length;
      if (length == 0) return;
      final start = textOffset.clamp(0, length - 1);
      final boxes = object.getBoxesForSelection(
          TextSelection(baseOffset: start, extentOffset: start + 1));
      if (boxes.isNotEmpty) {
        target = object;
        rect = boxes.first.toRect();
      }
    } else {
      object.visitChildren(visit);
    }
  }

  visit(root);
  if (target == null || rect == null) return false;
  target!.showOnScreen(
    rect: rect!.inflate(24),
    duration: !animate || MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 220),
    curve: Curves.easeOut,
  );
  return true;
}
