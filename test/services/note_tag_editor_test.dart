import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/data/dto/note_dto.dart';
import 'package:onlynote/domain/model/custom_note_template.dart';
import 'package:onlynote/domain/repository/note_repository.dart';
import 'package:onlynote/services/custom_note_template_store.dart';
import 'package:onlynote/services/note_search.dart';
import 'package:onlynote/services/note_tag_editor.dart';
import 'package:onlynote/services/saved_note_views.dart';

import '../support/memory_preferences.dart';
import '../support/template_images.dart';

class _Notes implements NoteRepository {
  _Notes(Iterable<NoteDto> notes) {
    for (final note in notes) {
      saved[note.id!] = note;
    }
  }

  final saved = <String, NoteDto>{};
  final writes = <String>[];

  /// Ids whose write fails, standing in for a storage error.
  final failing = <String>{};

  @override
  List<NoteDto> getAllNotes() => saved.values.toList();
  @override
  Future<NoteDto> getNote(String id) async => saved[id]!;
  @override
  Future<void> addUpdateNote(NoteDto note) async {
    if (failing.contains(note.id)) throw StateError('write failed');
    writes.add(note.id!);
    saved[note.id!] = note;
  }

  @override
  Future<void> deleteNote(String id) async => saved.remove(id);
  @override
  Future<void> deleteMultiNotes(List<String> ids) async {
    for (final id in ids) {
      saved.remove(id);
    }
  }
}

/// A store whose writes always fail, standing in for unreadable preferences.
class _BrokenViews extends SavedNoteViewStore {
  _BrokenViews() : super(preferences: MemoryPreferences());
  @override
  Future<int> rewriteTags(List<String> Function(List<String>) rewrite) =>
      Future.error(StateError('views unavailable'));
}

void main() {
  late _Notes notes;
  late SavedNoteViewStore views;
  late CustomNoteTemplateStore templates;

  NoteTagEditor editor({SavedNoteViewStore? overrideViews}) => NoteTagEditor(
        notes: notes,
        views: overrideViews ?? views,
        templates: templates,
      );

  setUp(() async {
    notes = _Notes([
      NoteDto(id: 'active', title: 'Current', tags: ['Work', 'Research']),
      NoteDto(id: 'archived', title: 'Old', isArchived: true, tags: ['work']),
      NoteDto(
          id: 'trashed',
          title: 'Removed',
          deletedAt: DateTime.utc(2026).toIso8601String(),
          tags: ['Work']),
      NoteDto(id: 'untagged', title: 'Plain'),
      NoteDto(id: 'other', title: 'Personal', tags: ['Personal']),
    ]);
    views = SavedNoteViewStore(preferences: MemoryPreferences());
    await views.create(name: 'Work research', tags: ['Work', 'Research']);
    await views.create(name: 'Work only', tags: ['work']);
    await views.create(name: 'Personal', tags: ['Personal']);
    // Seeded through storage so the template needs no purchase or media.
    final preferences = MemoryPreferences();
    preferences.values[CustomNoteTemplateStore.storageKey] = jsonEncode({
      'version': 1,
      'templates': [
        CustomNoteTemplate(
          id: 'weekly-review',
          name: 'Weekly review',
          title: 'Review',
          tags: ['Work', 'Research'],
          createdAt: DateTime.utc(2026),
        ).toJson(),
      ],
    });
    templates = CustomNoteTemplateStore(
      preferences: preferences,
      images: MemoryTemplateImages(),
    );
  });

  tearDown(() {
    views.dispose();
    templates.dispose();
  });

  test('rename reaches notes in every scope and leaves the rest alone',
      () async {
    final outcome = await editor().rename(from: 'work', to: 'Job');

    expect(outcome.complete, isTrue);
    expect(outcome.notes, 3);
    // Manage tags lists a tag's notes without Trash, so the change reports
    // that scope separately: three rewritten, two of them listed.
    expect(outcome.libraryNotes, 2);
    expect(notes.writes, ['active', 'archived', 'trashed']);
    expect(notes.saved['active']!.tags, ['Job', 'Research']);
    expect(notes.saved['archived']!.tags, ['Job']);
    // Trash keeps the new name, so restoring a note cannot bring back the old.
    expect(notes.saved['trashed']!.tags, ['Job']);
    expect(notes.saved['untagged']!.tags, isEmpty);
    expect(notes.saved['other']!.tags, ['Personal']);
  });

  test('rename updates the saved views that filter on the tag', () async {
    final outcome = await editor().rename(from: 'Work', to: 'Job');

    expect(outcome.views, 2);
    expect(
        {for (final view in views.views) view.name: view.tags},
        {
          'Work research': ['Job', 'Research'],
          'Work only': ['Job'],
          'Personal': ['Personal'],
        });
  });

  test('merging a tag joins it on notes and views without repeating it',
      () async {
    final outcome = await editor().rename(from: 'Research', to: 'work');

    expect(outcome.complete, isTrue);
    expect(notes.saved['active']!.tags, ['work']);
    expect(views.views.first.tags, ['work']);
  });

  test('removal clears the tag everywhere and keeps other criteria', () async {
    await views.create(
        name: 'Pinned work',
        tags: ['Work'],
        query: 'release',
        filters: {NoteSearchFilter.pinned});

    final outcome = await editor().remove('WORK');

    expect(outcome.complete, isTrue);
    expect(outcome.notes, 3);
    expect(outcome.libraryNotes, 2);
    expect(notes.saved['active']!.tags, ['Research']);
    expect(notes.saved['archived']!.tags, isEmpty);
    expect(notes.saved['trashed']!.tags, isEmpty);
    final remaining = views.views.firstWhere((v) => v.name == 'Pinned work');
    expect(remaining.tags, isEmpty);
    // A view that loses its last tag keeps the criteria it still has.
    expect(remaining.query, 'release');
    expect(remaining.filters, {NoteSearchFilter.pinned});
  });

  test('saved templates follow the rename and the removal', () async {
    final renamed = await editor().rename(from: 'work', to: 'Job');

    expect(renamed.templates, 1);
    expect(renamed.complete, isTrue);
    expect(templates.templates.single.tags, ['Job', 'Research']);

    final removed = await editor().remove('Job');

    expect(removed.templates, 1);
    expect(templates.templates.single.tags, ['Research']);
  });

  test('a note whose write fails is reported, not silently skipped', () async {
    notes.failing.add('archived');

    final outcome = await editor().rename(from: 'work', to: 'Job');

    expect(outcome.notes, 2);
    expect(outcome.notesKept, 1);
    expect(outcome.complete, isFalse);
    expect(notes.saved['archived']!.tags, ['work']);
  });

  test('retrying after a partial rename finishes it', () async {
    notes.failing.add('archived');
    await editor().rename(from: 'work', to: 'Job');
    notes.failing.clear();

    final retry = await editor().rename(from: 'work', to: 'Job');

    expect(retry.complete, isTrue);
    // Only the note that kept the old tag is written the second time.
    expect(retry.notes, 1);
    expect(notes.saved['archived']!.tags, ['Job']);
    expect(notes.saved['active']!.tags, ['Job', 'Research']);
  });

  test('an unreadable view store does not undo a finished note rename',
      () async {
    final outcome =
        await editor(overrideViews: _BrokenViews()).rename(from: 'work', to: 'Job');

    expect(outcome.notes, 3);
    expect(outcome.referencesKept, isTrue);
    expect(outcome.complete, isFalse);
    expect(notes.saved['active']!.tags, ['Job', 'Research']);
  });

  test('a tag only Trash carries counts nothing for the library', () async {
    notes.saved.remove('active');
    notes.saved.remove('archived');

    final outcome = await editor().remove('Work');

    // Such a tag is never listed, so this count never reaches a toast. It
    // stays honest anyway: nothing the library shows lost the tag.
    expect(outcome.notes, 1);
    expect(outcome.libraryNotes, 0);
    expect(notes.saved['trashed']!.tags, isEmpty);
  });

  test('a tag no note carries changes nothing', () async {
    final outcome = await editor().rename(from: 'missing', to: 'Job');

    expect(outcome.changedAnything, isFalse);
    expect(outcome.complete, isTrue);
    expect(notes.writes, isEmpty);
  });
}
