import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/domain/model/note_text_style.dart';
import 'package:onlynote/services/note_outline.dart';
import 'package:onlynote/services/note_text_format.dart';

/// Text input is grouped into short, continuous runs. All other actions are
/// separate undo steps, including formatting, checklist structure and photos.
enum NoteEditKind { titleTyping, bodyTyping, todoTyping, discrete }

/// Editor content plus cursor locations. Note identity, timestamps and library
/// metadata are preserved from the live note when this snapshot is restored.
@immutable
class NoteEditSnapshot {
  NoteEditSnapshot({
    required Note note,
    this.titleSelection,
    this.bodySelection,
    Map<String, TextSelection> todoSelections = const {},
    this.focusedField,
  })  : note = note.copyWith(
          todo: List.unmodifiable(note.todo),
          imagePaths: List.unmodifiable(note.imagePaths),
          voiceMemos: List.unmodifiable(note.voiceMemos),
          textStyles: List.unmodifiable(note.textStyles),
          imageLayouts: List.unmodifiable(note.imageLayouts),
        ),
        todoSelections = Map.unmodifiable(todoSelections);

  final Note note;
  final TextSelection? titleSelection;
  final TextSelection? bodySelection;
  final Map<String, TextSelection> todoSelections;

  /// `title`, `body`, or a checklist item's ID; interpreted by the editor.
  final String? focusedField;

  Note applyTo(Note latest) => latest.copyWith(
        title: note.title,
        description: note.description,
        color: note.color,
        todo: note.todo,
        imagePaths: note.imagePaths,
        voiceMemos: note.voiceMemos,
        textStyles: _restoreHeadingAnchors(note, latest),
        imageLayouts: note.imageLayouts,
      );

  NoteEditSnapshot withNote(Note value) => NoteEditSnapshot(
        note: value,
        titleSelection: titleSelection,
        bodySelection: bodySelection,
        todoSelections: todoSelections,
        focusedField: focusedField,
      );

  bool sameContent(NoteEditSnapshot other) =>
      note.title == other.note.title &&
      note.description == other.note.description &&
      note.color == other.note.color &&
      listEquals(note.todo, other.note.todo) &&
      listEquals(note.imagePaths, other.note.imagePaths) &&
      listEquals(note.voiceMemos, other.note.voiceMemos) &&
      _sameVisibleTextStyles(note, other.note) &&
      listEquals(note.imageLayouts, other.note.imageLayouts);

  bool _sameSelection(NoteEditSnapshot other) =>
      titleSelection == other.titleSelection &&
      bodySelection == other.bodySelection &&
      mapEquals(todoSelections, other.todoSelections) &&
      focusedField == other.focusedField;
}

/// Bounded, in-session undo for the whole note. Attachments in both undo and
/// redo stacks retain file ownership until their steps are evicted or disposed.
class NoteEditHistory extends ChangeNotifier {
  NoteEditHistory({
    required NoteEditSnapshot initial,
    this.maxSteps = 100,
    this.maxTextBytes = 4 * 1024 * 1024,
    this.coalesceDelay = const Duration(milliseconds: 800),
    DateTime Function()? now,
  })  : _current = initial,
        _now = now ?? DateTime.now {
    if (maxSteps < 1) throw ArgumentError.value(maxSteps, 'maxSteps');
    if (maxTextBytes < 1) {
      throw ArgumentError.value(maxTextBytes, 'maxTextBytes');
    }
    if (coalesceDelay.isNegative) {
      throw ArgumentError.value(coalesceDelay, 'coalesceDelay');
    }
    _live.add(this);
  }

  static final Set<NoteEditHistory> _live = {};

  /// Cleanup reads these unions even when an attachment is absent from the
  /// current autosaved note. Every open editor owns its own history instance.
  static Set<String> get heldImages => {
        for (final history in _live) ...history.referencedImages,
      };
  static Set<String> get heldAudio => {
        for (final history in _live) ...history.referencedAudio,
      };

  final int maxSteps;

  /// One largest live note is the baseline; additional UTF-16 snapshot text is
  /// bounded by this budget. The baseline stays consistent across undo/redo.
  final int maxTextBytes;
  final Duration coalesceDelay;
  final DateTime Function() _now;
  NoteEditSnapshot _current;
  final List<_EditStep> _past = [];
  final List<_EditStep> _future = [];
  bool _coalescing = false;
  bool _disposed = false;

  NoteEditSnapshot get current => _current;
  bool get canUndo => _past.isNotEmpty;
  bool get canRedo => _future.isNotEmpty;
  int get undoCount => _past.length;
  int get redoCount => _future.length;

  int get retainedTextBytes {
    // Unchanged paragraphs share immutable strings between snapshots.
    final strings = Set<String>.identity();
    var baseline = 0;
    for (final snapshot in _snapshots) {
      final noteStrings = Set<String>.identity()..addAll(_textValues(snapshot));
      strings.addAll(noteStrings);
      final bytes =
          noteStrings.fold<int>(0, (bytes, text) => bytes + text.length * 2);
      if (bytes > baseline) baseline = bytes;
    }
    return strings.fold<int>(0, (bytes, text) => bytes + text.length * 2) -
        baseline;
  }

  Iterable<NoteEditSnapshot> get _snapshots sync* {
    yield _current;
    for (final step in [..._past, ..._future]) {
      yield step.before;
      yield step.after;
    }
  }

  Set<String> get referencedImages => {
        for (final snapshot in _snapshots) ...snapshot.note.imagePaths,
      };
  Set<String> get referencedAudio => {
        for (final snapshot in _snapshots)
          for (final memo in snapshot.note.voiceMemos) memo.path,
      };

  /// Call before adopting unrelated saved changes from another screen.
  void reset(NoteEditSnapshot initial) {
    if (_disposed) return;
    _current = initial;
    _past.clear();
    _future.clear();
    _coalescing = false;
    notifyListeners();
  }

  /// Call for the newly captured editor state, before deleting removed media.
  /// Selection-only and library metadata changes never consume an undo step.
  bool record(NoteEditSnapshot next,
      {NoteEditKind kind = NoteEditKind.discrete, String? fieldId}) {
    if (_disposed) return false;
    if (next.note.id != _current.note.id) {
      reset(next);
      return false;
    }
    _backfillHeadingAnchors(next.note);
    if (_current.sameContent(next)) {
      if (!_current._sameSelection(next) && !_selectionAtTypingCaret(next)) {
        _coalescing = false;
      }
      _current = next;
      return false;
    }

    final before = _current;
    final now = _now();
    final typing = _typingChange(before.note, next.note, kind, fieldId);
    final last = _past.lastOrNull;
    final elapsed = last == null ? null : now.difference(last.time);
    final merge = _coalescing &&
        _future.isEmpty &&
        last != null &&
        last.kind == kind &&
        last.fieldId == fieldId &&
        elapsed != null &&
        !elapsed.isNegative &&
        elapsed <= coalesceDelay &&
        typing != null &&
        last.typing != null &&
        typing.touches(last.typing!.caret);
    _future.clear();
    if (merge) {
      _past[_past.length - 1] = _EditStep(
          before: last.before,
          after: next,
          kind: kind,
          fieldId: fieldId,
          time: now,
          typing: typing);
    } else {
      _past.add(_EditStep(
          before: before,
          after: next,
          kind: kind,
          fieldId: fieldId,
          time: now,
          typing: typing));
      if (_past.length > maxSteps) _past.removeAt(0);
    }
    _current = next;
    _enforceTextBudget();
    _coalescing = typing != null;
    notifyListeners();
    return true;
  }

  /// Heading identities are library metadata created after earlier edits may
  /// already exist. Backfill that metadata into surviving styled paragraphs so
  /// an undo that temporarily removes a heading can still redo its identity.
  /// This changes no written text, formatting coverage or history boundaries.
  void _backfillHeadingAnchors(Note next) {
    final known = _current.note.textStyles
        .map((range) => range.anchorId)
        .whereType<String>()
        .toSet();
    if (!next.textStyles.any(
        (range) => range.anchorId != null && !known.contains(range.anchorId))) {
      return;
    }
    NoteEditSnapshot adopt(NoteEditSnapshot snapshot) {
      final styles = _restoreHeadingAnchors(snapshot.note, next);
      if (listEquals(styles, snapshot.note.textStyles)) return snapshot;
      return snapshot.withNote(snapshot.note.copyWith(textStyles: styles));
    }

    _EditStep adoptStep(_EditStep step) => _EditStep(
        before: adopt(step.before),
        after: adopt(step.after),
        kind: step.kind,
        fieldId: step.fieldId,
        time: step.time,
        typing: step.typing);
    _current = adopt(_current);
    for (var index = 0; index < _past.length; index++) {
      _past[index] = adoptStep(_past[index]);
    }
    for (var index = 0; index < _future.length; index++) {
      _future[index] = adoptStep(_future[index]);
    }
  }

  NoteEditSnapshot? undo() {
    if (_disposed || !canUndo) return null;
    final step = _past.removeLast();
    _future.add(step);
    _current = step.before.withNote(step.before.applyTo(_current.note));
    _coalescing = false;
    _enforceTextBudget();
    notifyListeners();
    return _current;
  }

  NoteEditSnapshot? redo() {
    if (_disposed || !canRedo) return null;
    final step = _future.removeLast();
    _past.add(step);
    _current = step.after.withNote(step.after.applyTo(_current.note));
    _coalescing = false;
    _enforceTextBudget();
    notifyListeners();
    return _current;
  }

  /// Useful when a modal action or focus change separates two typing runs.
  void breakCoalescing() => _coalescing = false;

  bool _selectionAtTypingCaret(NoteEditSnapshot next) {
    final last = _past.lastOrNull;
    final typing = last?.typing;
    if (!_coalescing ||
        last == null ||
        typing == null ||
        _current.focusedField != next.focusedField) {
      return false;
    }
    final selection = switch (last.kind) {
      NoteEditKind.titleTyping => next.titleSelection,
      NoteEditKind.bodyTyping => next.bodySelection,
      NoteEditKind.todoTyping => next.todoSelections[last.fieldId],
      NoteEditKind.discrete => null,
    };
    return selection?.isCollapsed == true &&
        selection?.extentOffset == typing.caret;
  }

  void _enforceTextBudget() {
    while (_past.isNotEmpty && retainedTextBytes > maxTextBytes) {
      _past.removeAt(0);
    }
    while (_future.isNotEmpty && retainedTextBytes > maxTextBytes) {
      _future.removeAt(0);
    }
    if (_past.isEmpty) _coalescing = false;
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _live.remove(this);
    _past.clear();
    _future.clear();
    super.dispose();
  }
}

/// Restore the snapshot's exact visible formatting while retaining identities
/// on headings that survive the text change. A snapshot's own explicit ID wins.
List<NoteTextStyleRange> _restoreHeadingAnchors(Note snapshot, Note latest) {
  final text = snapshot.description ?? '';
  final restored = normalizeNoteTextStyles(snapshot.textStyles, text);
  if (!restored.any((range) =>
      range.kind == NoteTextStyleKind.heading && range.anchorId == null)) {
    return restored;
  }
  final anchored =
      rebaseNoteTextStyles(latest.description ?? '', text, latest.textStyles)
          .where((range) =>
              range.kind == NoteTextStyleKind.heading && range.anchorId != null)
          .toList();
  if (anchored.isEmpty) return restored;
  final used =
      restored.map((range) => range.anchorId).whereType<String>().toSet();
  final additions = <(int, int, String)>[];
  for (final heading in buildNoteOutline(text, restored)) {
    if (heading.anchorId != null) continue;
    final candidate = anchored
        .where((range) =>
            range.start < heading.end &&
            range.end > heading.start &&
            !used.contains(range.anchorId))
        .firstOrNull;
    if (candidate == null) continue;
    final start =
        heading.start == 0 ? 0 : text.lastIndexOf('\n', heading.start - 1) + 1;
    final lineBreak = text.indexOf('\n', heading.end);
    final end = lineBreak < 0 ? text.length : lineBreak;
    additions.add((start, end, candidate.anchorId!));
    used.add(candidate.anchorId!);
  }
  if (additions.isEmpty) return restored;
  final result = <NoteTextStyleRange>[];
  for (final range in restored) {
    if (range.kind != NoteTextStyleKind.heading || range.anchorId != null) {
      result.add(range);
      continue;
    }
    final points = <int>{range.start, range.end};
    for (final (start, end, _) in additions) {
      if (start > range.start && start < range.end) points.add(start);
      if (end > range.start && end < range.end) points.add(end);
    }
    final boundaries = points.toList()..sort();
    for (var index = 0; index + 1 < boundaries.length; index++) {
      final start = boundaries[index];
      final end = boundaries[index + 1];
      final target = additions
          .where((anchor) => anchor.$1 <= start && anchor.$2 >= end)
          .firstOrNull;
      result.add(NoteTextStyleRange(
          start: start, end: end, kind: range.kind, anchorId: target?.$3));
    }
  }
  return normalizeNoteTextStyles(result, text);
}

/// IDs do not affect the visible result and must never consume an undo step.
bool _sameVisibleTextStyles(Note a, Note b) {
  if (a.textStyles.length == b.textStyles.length &&
      a.textStyles.indexed.every((item) =>
          item.$2.start == b.textStyles[item.$1].start &&
          item.$2.end == b.textStyles[item.$1].end &&
          item.$2.kind == b.textStyles[item.$1].kind)) {
    return true;
  }
  List<NoteTextStyleRange> withoutIds(Note note) => normalizeNoteTextStyles([
        for (final range in note.textStyles)
          NoteTextStyleRange(
              start: range.start, end: range.end, kind: range.kind)
      ], note.description ?? '');
  return listEquals(withoutIds(a), withoutIds(b));
}

class _EditStep {
  const _EditStep({
    required this.before,
    required this.after,
    required this.kind,
    required this.fieldId,
    required this.time,
    required this.typing,
  });
  final NoteEditSnapshot before;
  final NoteEditSnapshot after;
  final NoteEditKind kind;
  final String? fieldId;
  final DateTime time;
  final _TypingChange? typing;
}

class _TypingChange {
  const _TypingChange(this.start, this.oldEnd, this.caret);
  final int start;
  final int oldEnd;
  final int caret;

  bool touches(int previousCaret) =>
      start == previousCaret || oldEnd == previousCaret;
}

Iterable<String> _textValues(NoteEditSnapshot snapshot) sync* {
  final note = snapshot.note;
  if (note.title case final title?) yield title;
  if (note.description case final description?) yield description;
  for (final todo in note.todo) {
    if (todo.title case final title?) yield title;
  }
  for (final memo in note.voiceMemos) {
    if (memo.transcript case final transcript?) yield transcript;
  }
}

_TypingChange? _typingChange(
    Note before, Note after, NoteEditKind kind, String? fieldId) {
  if (kind == NoteEditKind.discrete ||
      before.color != after.color ||
      !listEquals(before.imagePaths, after.imagePaths) ||
      !listEquals(before.voiceMemos, after.voiceMemos)) {
    return null;
  }
  String? oldText;
  String? newText;
  switch (kind) {
    case NoteEditKind.titleTyping:
      if (before.description != after.description ||
          !listEquals(before.todo, after.todo) ||
          !listEquals(before.textStyles, after.textStyles) ||
          !listEquals(before.imageLayouts, after.imageLayouts)) {
        return null;
      }
      oldText = before.title ?? '';
      newText = after.title ?? '';
    case NoteEditKind.bodyTyping:
      if (before.title != after.title ||
          !listEquals(before.todo, after.todo) ||
          !_sameImageGeometry(before, after)) {
        return null;
      }
      // Text edits legitimately move formatting ranges and image anchors.
      oldText = before.description ?? '';
      newText = after.description ?? '';
    case NoteEditKind.todoTyping:
      if (fieldId == null ||
          before.title != after.title ||
          before.description != after.description ||
          !listEquals(before.textStyles, after.textStyles) ||
          !listEquals(before.imageLayouts, after.imageLayouts) ||
          before.todo.length != after.todo.length) {
        return null;
      }
      for (var index = 0; index < before.todo.length; index++) {
        final oldTodo = before.todo[index];
        final newTodo = after.todo[index];
        if (oldTodo.id != newTodo.id ||
            oldTodo.completed != newTodo.completed) {
          return null;
        }
        if (oldTodo.id == fieldId) {
          oldText = oldTodo.title ?? '';
          newText = newTodo.title ?? '';
        } else if (oldTodo.title != newTodo.title) {
          return null;
        }
      }
    case NoteEditKind.discrete:
      return null;
  }
  if (oldText == null || newText == null || oldText == newText) return null;
  var prefix = 0;
  while (prefix < oldText.length &&
      prefix < newText.length &&
      oldText.codeUnitAt(prefix) == newText.codeUnitAt(prefix)) {
    prefix++;
  }
  var oldEnd = oldText.length;
  var newEnd = newText.length;
  while (oldEnd > prefix &&
      newEnd > prefix &&
      oldText.codeUnitAt(oldEnd - 1) == newText.codeUnitAt(newEnd - 1)) {
    oldEnd--;
    newEnd--;
  }
  return _TypingChange(prefix, oldEnd, newEnd);
}

bool _sameImageGeometry(Note before, Note after) {
  if (before.imageLayouts.length != after.imageLayouts.length) return false;
  for (var index = 0; index < before.imageLayouts.length; index++) {
    final oldLayout = before.imageLayouts[index];
    final newLayout = after.imageLayouts[index];
    if (oldLayout.path != newLayout.path ||
        oldLayout.widthFactor != newLayout.widthFactor ||
        oldLayout.xFactor != newLayout.xFactor ||
        oldLayout.aspectRatio != newLayout.aspectRatio ||
        oldLayout.isDocumentPage != newLayout.isDocumentPage) {
      return false;
    }
  }
  return true;
}
