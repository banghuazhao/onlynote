import 'package:flutter/foundation.dart';
import 'package:onlynote/common/constants.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/services/note_selection.dart';
import 'package:uuid/uuid.dart';

enum NoteSelectionChecklistStatus { empty, tooLong, ready }

/// Parsed titles remain intact even when one exceeds the storage limit, so a
/// caller can report a rejected transaction without silently losing text.
@immutable
class NoteSelectionChecklist {
  const NoteSelectionChecklist._({required this.status, required this.titles});

  final NoteSelectionChecklistStatus status;
  final List<String> titles;

  bool get isEmpty => titles.isEmpty;
  bool get canApply => status == NoteSelectionChecklistStatus.ready;
}

final _lineBreak = RegExp(r'\r\n?|\n|\u2028|\u2029');
final _lineMarker = RegExp(
  r'^(?:[-*+•◦‣▪●○–][\uFE0E\uFE0F]?|\([1-9][0-9]{0,8}\)|[1-9][0-9]{0,8}[.)]|\[[ \t]*[xX✓✔]?[ \t]*\]|[☐☑☒✅✓✔][\uFE0E\uFE0F]?)(?:[ \t]+|$)',
);

/// Keep selected line order, including repeated lines. Marker removal operates
/// on whole strings and leaves emoji, combining characters, and prose intact.
NoteSelectionChecklist parseNoteSelectionChecklist(String selectedText) {
  final titles = <String>[];
  for (final selectedLine in selectedText.split(_lineBreak)) {
    var title = selectedLine.trim();
    RegExpMatch? marker;
    while ((marker = _lineMarker.firstMatch(title)) != null) {
      title = title.substring(marker!.end).trimLeft();
    }
    if (title.isNotEmpty) titles.add(title);
  }
  return NoteSelectionChecklist._(
    status: titles.isEmpty
        ? NoteSelectionChecklistStatus.empty
        : titles.any((title) => title.length > todoMaxCharCount)
            ? NoteSelectionChecklistStatus.tooLong
            : NoteSelectionChecklistStatus.ready,
    titles: List.unmodifiable(titles),
  );
}

@immutable
class NoteSelectionChecklistResult {
  const NoteSelectionChecklistResult._({
    required this.status,
    this.note,
    this.addedTodoIds = const [],
  });

  final NoteSelectionChecklistStatus status;
  final Note? note;
  final List<String> addedTodoIds;
}

/// Add unchecked checklist rows without removing or restyling the source
/// prose. Reject every new row together if any title would be truncated by DTO
/// storage, whose title cap is measured in UTF-16 code units.
NoteSelectionChecklistResult appendSelectionToChecklist(
  Note destination,
  NoteTextSelection selection,
) {
  final parsed = parseNoteSelectionChecklist(selection.text);
  if (!parsed.canApply) {
    return NoteSelectionChecklistResult._(status: parsed.status);
  }
  const uuid = Uuid();
  final usedIds = destination.todo.map((todo) => todo.id).toSet();
  final added = <Todo>[];
  for (final title in parsed.titles) {
    var id = uuid.v4();
    while (!usedIds.add(id)) {
      id = uuid.v4();
    }
    added.add(Todo(id: id, title: title));
  }
  return NoteSelectionChecklistResult._(
    status: NoteSelectionChecklistStatus.ready,
    note: destination.copyWith(todo: [...destination.todo, ...added]),
    addedTodoIds: List.unmodifiable(added.map((todo) => todo.id!)),
  );
}

/// Reader Undo targets only rows created by this action. Newer prose, metadata,
/// unrelated checklist edits, and additional rows stay in their latest form.
Note undoSelectionChecklist(Note latest, Iterable<String> addedTodoIds) {
  final ids = addedTodoIds.toSet();
  if (ids.isEmpty || !latest.todo.any((todo) => ids.contains(todo.id))) {
    return latest;
  }
  return latest.copyWith(
      todo: latest.todo.where((todo) => !ids.contains(todo.id)).toList());
}
