import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:onlynote/domain/model/note_text_style.dart';
import 'package:onlynote/services/note_text_format.dart';

/// A normal native text field with three small formatting actions. The body
/// remains plain text; no markup or replacement characters affect selection.
class SimpleFormattingController extends TextEditingController {
  SimpleFormattingController({
    super.text,
    List<NoteTextStyleRange> styles = const [],
  }) {
    _styles = normalizeNoteTextStyles(styles, text);
  }

  List<NoteTextStyleRange> _styles = const [];
  int _documentRevision = 0;

  /// Explicit document replacement lets segmented editors distinguish a
  /// library refresh from ordinary typing and keep supplied photo positions.
  int get documentRevision => _documentRevision;
  bool? _typingBold;
  bool _typingBoldExplicit = false;
  int? _editedPartStart;
  int? _editedPartEnd;
  int? _emptyHeadingAt;
  final List<_FormattingSnapshot> _undo = [];
  final List<_FormattingSnapshot> _redo = [];

  List<NoteTextStyleRange> get styles => _styles;

  bool get isBold {
    final selected = _selectionRange;
    if (selected.isCollapsed) {
      return _typingBold ?? _kindAt(selected.start, NoteTextStyleKind.bold);
    }
    return _covers(selected.start, selected.end, NoteTextStyleKind.bold);
  }

  bool get isHeading {
    final paragraphs = _paragraphsForSelection();
    return paragraphs.every((paragraph) => paragraph.isCollapsed
        ? _emptyHeadingAt == paragraph.start
        : _covers(paragraph.start, paragraph.end, NoteTextStyleKind.heading));
  }

  bool get isBulleted => _paragraphsForSelection().every(
        (paragraph) =>
            text.substring(paragraph.start, paragraph.end).startsWith('• '),
      );

  bool get _isComposing =>
      value.composing.isValid && !value.composing.isCollapsed;

  TextRange get _selectionRange {
    if (!selection.isValid) return TextRange.collapsed(text.length);
    final start = selection.start.clamp(0, text.length);
    final end = selection.end.clamp(0, text.length);
    if (start == end) return TextRange.collapsed(start);
    final safe = normalizeNoteTextStyles([
      NoteTextStyleRange(start: start, end: end, kind: NoteTextStyleKind.bold),
    ], text);
    return safe.isEmpty
        ? TextRange.collapsed(start)
        : TextRange(start: safe.single.start, end: safe.single.end);
  }

  /// Replaces the saved document and clears temporary typing modes. Inserting
  /// OCR/transcript text with the existing ranges therefore keeps it plain.
  void setDocument(String text, List<NoteTextStyleRange> styles) {
    _documentRevision++;
    final clean = normalizeNoteTextStyles(styles, text);
    _styles = clean;
    _typingBold = null;
    _typingBoldExplicit = false;
    _emptyHeadingAt = null;
    _undo.clear();
    _redo.clear();
    final oldValue = value;
    final next = TextEditingValue(
      text: text,
      selection: oldValue.selection.isValid
          ? TextSelection(
              baseOffset: oldValue.selection.baseOffset.clamp(0, text.length),
              extentOffset:
                  oldValue.selection.extentOffset.clamp(0, text.length),
              affinity: oldValue.selection.affinity,
              isDirectional: oldValue.selection.isDirectional,
            )
          : TextSelection.collapsed(offset: text.length),
    );
    super.value = next;
    if (next == oldValue) notifyListeners();
  }

  /// Applies a native editing value from one text part of an image document.
  /// Keeping its changed region local avoids assigning styles to the wrong
  /// paragraph when two parts contain identical text.
  void applySegmentValue(
    TextEditingValue next, {
    required int editedPartStart,
    required int editedPartEnd,
  }) {
    final previousStart = _editedPartStart;
    final previousEnd = _editedPartEnd;
    _editedPartStart = editedPartStart;
    _editedPartEnd = editedPartEnd;
    try {
      value = next;
    } finally {
      _editedPartStart = previousStart;
      _editedPartEnd = previousEnd;
    }
  }

  NoteTextChange _textChange(String before, String after) => noteTextChange(
        before,
        after,
        editedPartStart: _editedPartStart,
        editedPartEnd: _editedPartEnd,
      );

  void toggleBold() {
    if (_isComposing) return;
    final selected = _selectionRange;
    if (selected.isCollapsed) {
      _typingBold = !isBold;
      _typingBoldExplicit = true;
    } else {
      _styles = normalizeNoteTextStyles(
        isBold
            ? removeNoteTextStyle(
                _styles,
                selected.start,
                selected.end,
                NoteTextStyleKind.bold,
              )
            : [
                ..._styles,
                NoteTextStyleRange(
                  start: selected.start,
                  end: selected.end,
                  kind: NoteTextStyleKind.bold,
                ),
              ],
        text,
      );
      _typingBold = null;
      _typingBoldExplicit = false;
    }
    notifyListeners();
  }

  void toggleHeading() {
    if (_isComposing) return;
    final enabled = !isHeading;
    final paragraphs = _paragraphsForSelection();
    var updated = _styles;
    for (final paragraph in paragraphs) {
      if (paragraph.isCollapsed) {
        _emptyHeadingAt = enabled ? paragraph.start : null;
      } else if (enabled) {
        updated = [
          ...updated,
          NoteTextStyleRange(
            start: paragraph.start,
            end: paragraph.end,
            kind: NoteTextStyleKind.heading,
          ),
        ];
      } else {
        updated = removeNoteTextStyle(
          updated,
          paragraph.start,
          paragraph.end,
          NoteTextStyleKind.heading,
        );
      }
    }
    _styles = normalizeNoteTextStyles(updated, text);
    notifyListeners();
  }

  void toggleBullets() {
    if (_isComposing) return;
    final remove = isBulleted;
    final paragraphs = _paragraphsForSelection();
    var nextText = text;
    var nextStyles = _styles;
    var nextSelection = selection.isValid
        ? selection
        : TextSelection.collapsed(offset: text.length);
    for (final paragraph in paragraphs.reversed) {
      final bulleted =
          text.substring(paragraph.start, paragraph.end).startsWith('• ');
      if (remove && !bulleted || !remove && bulleted) continue;
      final start = paragraph.start;
      final end = start + (remove ? 2 : 0);
      final inserted = remove ? '' : '• ';
      final updatedText = nextText.replaceRange(start, end, inserted);
      nextStyles = rebaseNoteTextStyles(
        nextText,
        updatedText,
        nextStyles,
        insertedBold: false,
        insertedHeading: _kindAt(start, NoteTextStyleKind.heading),
      );
      nextSelection = TextSelection(
        baseOffset:
            _moveOffset(nextSelection.baseOffset, start, end, inserted.length),
        extentOffset: _moveOffset(
            nextSelection.extentOffset, start, end, inserted.length),
        affinity: nextSelection.affinity,
        isDirectional: nextSelection.isDirectional,
      );
      nextText = updatedText;
    }
    if (nextText == text) return;
    _remember();
    _redo.clear();
    _styles = nextStyles;
    _emptyHeadingAt = null;
    super.value = TextEditingValue(text: nextText, selection: nextSelection);
  }

  @override
  set value(TextEditingValue next) {
    final previous = super.value;
    if (previous.text == next.text) {
      if (previous.selection != next.selection && previous.selection.isValid) {
        _typingBold = null;
        _typingBoldExplicit = false;
        if (_emptyHeadingAt != null &&
            _paragraphAt(
                        next.text,
                        next.selection.isValid
                            ? next.selection.extentOffset
                            : next.text.length)
                    .start !=
                _emptyHeadingAt) {
          _emptyHeadingAt = null;
        }
      }
      super.value = next;
      return;
    }
    // Leave IME composition untouched. Native input owns its active range.
    final composing = next.composing.isValid && !next.composing.isCollapsed;
    var change = _textChange(previous.text, next.text);
    if (!composing &&
        change.inserted == '\n' &&
        change.start == change.oldEnd &&
        previous.selection.isCollapsed) {
      final paragraph = _paragraphAt(previous.text, change.start);
      final line = previous.text.substring(paragraph.start, paragraph.end);
      if (line.startsWith('• ') && change.start >= paragraph.start + 2) {
        if (line == '• ' && change.start == paragraph.end) {
          final updated =
              next.text.replaceRange(paragraph.start, change.start + 1, '');
          next = TextEditingValue(
            text: updated,
            selection: TextSelection.collapsed(offset: paragraph.start),
          );
        } else {
          next = TextEditingValue(
            text: next.text
                .replaceRange(change.start + 1, change.start + 1, '• '),
            selection: TextSelection.collapsed(offset: change.start + 3),
          );
        }
        change = _textChange(previous.text, next.text);
      }
    }
    // Flutter can undo a group of several keystrokes in one value change.
    // Search this bounded companion history rather than only its last entry.
    // An explicit toolbar choice takes precedence over matching text when the
    // user deliberately types the same characters again.
    final intentionalTyping = change.inserted.isNotEmpty &&
        (_typingBoldExplicit || _emptyHeadingAt != null);
    final undoIndex = intentionalTyping
        ? -1
        : _undo.lastIndexWhere((snapshot) => snapshot.text == next.text);
    final redoIndex = intentionalTyping
        ? -1
        : _redo.lastIndexWhere((snapshot) => snapshot.text == next.text);
    if (undoIndex >= 0) {
      _redo.add(_FormattingSnapshot(previous.text, _styles));
      _trimStack(_redo);
      _styles = _undo[undoIndex].styles;
      _undo.removeRange(undoIndex, _undo.length);
      _typingBold = null;
      _typingBoldExplicit = false;
      _emptyHeadingAt = null;
    } else if (redoIndex >= 0) {
      _remember();
      _styles = _redo[redoIndex].styles;
      _redo.removeRange(redoIndex, _redo.length);
      _typingBold = null;
      _typingBoldExplicit = false;
      _emptyHeadingAt = null;
    } else {
      _remember();
      _redo.clear();
      final heading = _emptyHeadingAt != null &&
          _paragraphAt(previous.text, change.start).start == _emptyHeadingAt;
      _styles = rebaseNoteTextStyles(
        previous.text,
        next.text,
        _styles,
        insertedBold: _typingBold,
        insertedHeading: heading ? true : null,
        changeOverride: change,
      );
      if (change.inserted.contains('\n') &&
          (_kindAt(change.start, NoteTextStyleKind.heading) || heading)) {
        _typingBold = false;
        _typingBoldExplicit = false;
      }
      if (heading && change.inserted.isNotEmpty) _emptyHeadingAt = null;
    }
    super.value = next;
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) =>
      TextSpan(
        style: style,
        children: buildNoteTextSpans(
          text: text,
          styles: _styles,
          baseStyle: style,
          composing: withComposing ? value.composing : TextRange.empty,
        ),
      );

  bool _kindAt(int offset, NoteTextStyleKind kind) {
    return _styles.any((range) =>
        range.kind == kind &&
        range.start <= offset &&
        range.end >= offset &&
        !(range.end == offset &&
            offset > 0 &&
            offset <= text.length &&
            text[offset - 1] == '\n'));
  }

  bool _covers(int start, int end, NoteTextStyleKind kind) => _styles.any(
        (range) =>
            range.kind == kind && range.start <= start && range.end >= end,
      );

  List<TextRange> _paragraphsForSelection() {
    final selected = _selectionRange;
    final first = _paragraphAt(text, selected.start);
    final endOffset = selected.isCollapsed
        ? selected.end
        : math.max(selected.start, selected.end - 1);
    final last = _paragraphAt(text, endOffset);
    final paragraphs = <TextRange>[];
    var current = first;
    while (true) {
      paragraphs.add(current);
      if (current.start == last.start || current.end >= text.length) break;
      current = _paragraphAt(text, current.end + 1);
    }
    return paragraphs;
  }

  static TextRange _paragraphAt(String text, int offset) {
    final cursor = offset.clamp(0, text.length);
    final preceding = cursor == 0 ? -1 : text.lastIndexOf('\n', cursor - 1);
    final following = text.indexOf('\n', cursor);
    return TextRange(
        start: preceding + 1, end: following < 0 ? text.length : following);
  }

  static int _moveOffset(int offset, int start, int end, int insertedLength) {
    if (offset < start) return offset;
    if (offset >= end) return offset + insertedLength - (end - start);
    return start + insertedLength;
  }

  void _remember() {
    _undo.add(_FormattingSnapshot(text, _styles));
    _trimStack(_undo);
  }

  void _trimStack(List<_FormattingSnapshot> stack) {
    // Native text undo owns text history; this small companion only retains
    // styles, with a bounded amount of duplicate text for matching its edits.
    while (stack.length > 40 ||
        stack.fold<int>(0, (total, snapshot) => total + snapshot.text.length) >
            1000000) {
      stack.removeAt(0);
    }
  }
}

class _FormattingSnapshot {
  const _FormattingSnapshot(this.text, this.styles);
  final String text;
  final List<NoteTextStyleRange> styles;
}
