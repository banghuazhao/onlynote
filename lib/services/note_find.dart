import 'package:flutter/widgets.dart';
import 'package:onlynote/domain/model/note.dart';

@immutable
class NoteSearchField {
  const NoteSearchField(this.id, this.text);
  final String id;
  final String text;
}

@immutable
class NoteSearchMatch {
  const NoteSearchMatch(this.fieldId, this.start, this.end);
  final String fieldId;
  final int start;
  final int end;

  @override
  bool operator ==(Object other) =>
      other is NoteSearchMatch &&
      fieldId == other.fieldId &&
      start == other.start &&
      end == other.end;
  @override
  int get hashCode => Object.hash(fieldId, start, end);
}

/// Fields follow the order in the reader, including completed checklist items.
List<NoteSearchField> noteSearchFields(Note note) => [
      NoteSearchField('title', note.title ?? ''),
      for (final completed in [false, true])
        for (final (index, todo) in note.todo.indexed)
          if (todo.completed == completed)
            NoteSearchField('todo:${todo.id ?? index}', todo.title ?? ''),
      NoteSearchField('body', note.description ?? ''),
      for (final memo in note.voiceMemos)
        NoteSearchField('voice:${memo.id}', memo.transcript ?? ''),
    ];

/// Literal, case-insensitive matches retain offsets into the original text.
/// Highlight boundaries encompass whole graphemes, including joined emoji.
List<NoteSearchMatch> findNoteMatches(
    Iterable<NoteSearchField> fields, String query) {
  final needle = query.trim();
  if (needle.isEmpty) return const [];
  final pattern =
      RegExp(RegExp.escape(needle), caseSensitive: false, unicode: true);
  final result = <NoteSearchMatch>[];
  for (final field in fields) {
    final raw = pattern.allMatches(field.text).toList();
    if (raw.isEmpty) continue;
    final boundaries = <int>[0];
    var offset = 0;
    for (final character in field.text.characters) {
      offset += character.length;
      boundaries.add(offset);
    }
    var boundaryIndex = 0;
    NoteSearchMatch? previous;
    for (final match in raw) {
      while (boundaryIndex + 1 < boundaries.length &&
          boundaries[boundaryIndex + 1] <= match.start) {
        boundaryIndex++;
      }
      final start = boundaries[boundaryIndex];
      var endIndex = boundaryIndex;
      while (boundaries[endIndex] < match.end) {
        endIndex++;
      }
      final found = NoteSearchMatch(field.id, start, boundaries[endIndex]);
      // A query can occur twice within a joined grapheme; highlight it once.
      if (found != previous) result.add(found);
      previous = found;
    }
  }
  return result;
}

class _SearchTarget {
  const _SearchTarget(this.fieldId, this.start, this.end, this.reveal);
  final String fieldId;
  final int start;
  final int end;
  final ValueChanged<NoteSearchMatch> reveal;
  bool contains(NoteSearchMatch match) =>
      fieldId == match.fieldId && start <= match.start && match.start < end;
}

/// Search state never changes a note. Targets may be reader paragraphs or
/// editor fields, so the same bar works with saved notes and current drafts.
class NoteSearchController extends ChangeNotifier {
  List<NoteSearchField> _fields = const [];
  String _query = '';
  List<NoteSearchMatch> _matches = const [];
  int _currentIndex = -1;
  final _targets = <Object, _SearchTarget>{};
  int _revealGeneration = 0;
  bool _disposed = false;

  String get query => _query;
  List<NoteSearchMatch> get matches => _matches;
  int get currentIndex => _currentIndex;
  NoteSearchMatch? get currentMatch =>
      _currentIndex < 0 ? null : _matches[_currentIndex];

  void setFields(List<NoteSearchField> fields, {bool notify = true}) {
    if (fields.length == _fields.length &&
        fields.indexed.every((item) =>
            item.$2.id == _fields[item.$1].id &&
            item.$2.text == _fields[item.$1].text)) {
      return;
    }
    _fields = List.of(fields);
    final previous = currentMatch;
    _matches = List.unmodifiable(findNoteMatches(_fields, _query));
    final retained = previous == null ? -1 : _matches.indexOf(previous);
    _currentIndex = _matches.isEmpty ? -1 : (retained < 0 ? 0 : retained);
    if (notify) notifyListeners();
    if (_query.isNotEmpty) revealCurrent();
  }

  void setQuery(String query) {
    if (query == _query) return;
    _query = query;
    _matches = List.unmodifiable(findNoteMatches(_fields, query));
    _currentIndex = _matches.isEmpty ? -1 : 0;
    notifyListeners();
    revealCurrent();
  }

  void next() => _move(1);
  void previous() => _move(-1);
  void _move(int delta) {
    if (_matches.isEmpty) return;
    _currentIndex = (_currentIndex + delta) % _matches.length;
    notifyListeners();
    revealCurrent();
  }

  VoidCallback registerTarget({
    required Object owner,
    required String fieldId,
    required ValueChanged<NoteSearchMatch> reveal,
    int start = 0,
    int end = 0x7fffffff,
  }) {
    _targets[owner] = _SearchTarget(fieldId, start, end, reveal);
    return () => _targets.remove(owner);
  }

  /// Wait for highlights and expanded completed rows to finish their layout.
  void revealCurrent() {
    final generation = ++_revealGeneration;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_disposed || generation != _revealGeneration) return;
      final match = currentMatch;
      if (match == null) return;
      for (final target in _targets.values) {
        if (target.contains(match)) {
          target.reveal(match);
          return;
        }
      }
    });
    // Targets can also be registered without a listening text widget. Request
    // a frame so programmatic navigation still reveals its target.
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  @override
  void dispose() {
    _disposed = true;
    _targets.clear();
    super.dispose();
  }
}
