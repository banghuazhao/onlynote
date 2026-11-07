import 'package:onlynote/domain/repository/note_repository.dart';

import 'custom_note_template_store.dart';
import 'note_mutations.dart';
import 'note_tag_management.dart';
import 'note_tags.dart';
import 'saved_note_views.dart';

/// What a library-wide tag change reached.
class TagEditOutcome {
  const TagEditOutcome({
    this.notes = 0,
    this.libraryNotes = 0,
    this.views = 0,
    this.templates = 0,
    this.notesKept = 0,
    this.referencesKept = false,
  });

  /// Notes whose stored tags were rewritten, archived and Trash included.
  final int notes;

  /// The part of [notes] the library lists: archived kept, Trash excluded.
  /// Manage tags counts a tag's notes the same way, so this is the figure to
  /// report back — a total including Trash would contradict the count on the
  /// row the user just tapped.
  final int libraryNotes;

  /// Saved views whose tag criteria were rewritten.
  final int views;

  /// Saved templates whose tags were rewritten.
  final int templates;

  /// Notes that still carry the old tag because their write failed.
  final int notesKept;

  /// A saved view or template kept the old tag because its store failed.
  final bool referencesKept;

  /// Every reference was reached. Retrying a partial change is safe: the
  /// notes already rewritten no longer match the old tag.
  bool get complete => notesKept == 0 && !referencesKept;

  bool get changedAnything => notes > 0 || views > 0 || templates > 0;
}

/// Renames or removes one tag everywhere the library refers to it: notes in
/// every scope, saved views, and saved templates.
class NoteTagEditor {
  NoteTagEditor({
    required NoteRepository notes,
    SavedNoteViewStore? views,
    CustomNoteTemplateStore? templates,
  })  : _notes = notes,
        _views = views ?? SavedNoteViewStore.instance,
        _templates = templates ?? CustomNoteTemplateStore.instance;

  final NoteRepository _notes;
  final SavedNoteViewStore _views;
  final CustomNoteTemplateStore _templates;

  /// Merges when [to] already exists, and changes only spelling when the two
  /// names share a [tagKey].
  Future<TagEditOutcome> rename({
    required String from,
    required String to,
  }) =>
      _apply((tags) => renameTagIn(tags, from: from, to: to));

  /// Removes the tag. Note content is untouched.
  Future<TagEditOutcome> remove(String tag) =>
      _apply((tags) => removeTagIn(tags, tag));

  Future<TagEditOutcome> _apply(
      List<String> Function(List<String> tags) rewrite) async {
    // One reservation for the whole pass over the notes: an editor saving
    // from an older snapshot in between would restore the old tag.
    final notes = await NoteMutations.run(() => _rewriteNotes(rewrite));
    var kept = false;
    var views = 0;
    var templates = 0;
    // Views and templates own separate stores. Notes are the library itself,
    // so a failure here is reported rather than undoing a finished rename.
    try {
      views = await _views.rewriteTags(rewrite);
    } catch (_) {
      kept = true;
    }
    try {
      templates = await _templates.rewriteTags(rewrite);
    } catch (_) {
      kept = true;
    }
    return TagEditOutcome(
      notes: notes.changed,
      libraryNotes: notes.changedInLibrary,
      views: views,
      templates: templates,
      notesKept: notes.kept,
      referencesKept: kept,
    );
  }

  Future<({int changed, int changedInLibrary, int kept})> _rewriteNotes(
      List<String> Function(List<String> tags) rewrite) async {
    var changed = 0;
    var changedInLibrary = 0;
    var kept = 0;
    for (final note in _notes.getAllNotes()) {
      if (note.id == null) continue;
      final current = note.tags ?? const <String>[];
      final updated = rewrite(current);
      if (sameNoteTags(current, updated)) continue;
      try {
        // Only the tags change: no media cleanup, no content validation, and
        // no edit-history version for metadata the editor never touched.
        await _notes.addUpdateNote(note.copyWith(tags: updated));
        changed++;
        if (!note.isDeleted) changedInLibrary++;
      } catch (_) {
        kept++;
      }
    }
    return (changed: changed, changedInLibrary: changedInLibrary, kept: kept);
  }
}
