import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/services/note_search.dart';
import 'package:onlynote/services/saved_note_views.dart';

import '../support/memory_preferences.dart';

class _FailingPreferences extends MemoryPreferences {
  _FailingPreferences(this.shouldFail);
  final bool Function() shouldFail;
  @override
  Future<void> setString(String key, String value) async {
    if (shouldFail()) throw StateError('Storage unavailable');
    await super.setString(key, value);
  }
}

void main() {
  test('saved view round trips its search, filters, tags, folder and scope',
      () async {
    final preferences = MemoryPreferences();
    final store = SavedNoteViewStore(preferences: preferences);
    addTearDown(store.dispose);
    final view = await store.create(
      name: '  Work follow-ups  ',
      query: '会议',
      filters: {NoteSearchFilter.unfinished, NoteSearchFilter.pinned},
      tags: [' Work ', 'work', 'Important'],
      folderId: 'projects',
      archiveScope: NoteArchiveScope.all,
    );
    final reopened = SavedNoteViewStore(preferences: preferences);
    addTearDown(reopened.dispose);
    await reopened.load();
    final saved = reopened.views.single;
    expect(saved.id, view.id);
    expect(saved.name, 'Work follow-ups');
    expect(saved.query, '会议');
    expect(
        saved.filters, {NoteSearchFilter.unfinished, NoteSearchFilter.pinned});
    expect(saved.tags, ['Work', 'Important']);
    expect(saved.folderId, 'projects');
    expect(saved.archiveScope, NoteArchiveScope.all);
  });

  test('deleted folder fallback preserves all other view criteria', () {
    final view = SavedNoteView(
        id: 'view',
        name: 'Follow-ups',
        query: 'call',
        folderId: 'deleted',
        tags: ['Work'],
        archiveScope: NoteArchiveScope.archived);
    final resolved = view.withAvailableFolders({'other'});
    expect(resolved.folderId, isNull);
    expect(resolved.query, 'call');
    expect(resolved.tags, ['Work']);
    expect(resolved.archiveScope, NoteArchiveScope.archived);
    expect(view.folderId, 'deleted');
  });

  test('concurrent creates serialize without losing views', () async {
    final store = SavedNoteViewStore(preferences: MemoryPreferences());
    addTearDown(store.dispose);
    await Future.wait([
      store.create(name: 'One'),
      store.create(name: 'Two'),
      store.create(name: 'Three'),
    ]);
    expect(store.views.map((view) => view.name), ['One', 'Two', 'Three']);
    expect(store.views.map((view) => view.id).toSet().length, 3);
  });

  test('failed writes retain the last durable list and allow retry', () async {
    var failWrites = false;
    final preferences = _FailingPreferences(() => failWrites);
    final store = SavedNoteViewStore(preferences: preferences);
    addTearDown(store.dispose);
    final first = await store.create(name: 'Original');
    failWrites = true;
    await expectLater(store.rename(first.id, 'Changed'), throwsStateError);
    expect(store.views.single.name, 'Original');
    failWrites = false;
    await store.rename(first.id, 'Changed');
    expect(store.views.single.name, 'Changed');
    await store.delete(first.id);
    expect(store.views, isEmpty);
  });

  test('malformed or unsupported storage is never overwritten by create',
      () async {
    for (final raw in [
      jsonEncode({'version': 2, 'views': []}),
      jsonEncode({
        'version': 1,
        'views': [
          {'id': 'broken'}
        ]
      }),
      '{',
    ]) {
      final preferences = MemoryPreferences();
      await preferences.setString(SavedNoteViewStore.storageKey, raw);
      final store = SavedNoteViewStore(preferences: preferences);
      addTearDown(store.dispose);
      await expectLater(store.create(name: 'New'), throwsFormatException);
      expect(preferences.values[SavedNoteViewStore.storageKey], raw);
    }
  });

  test('captures mutable caller filters and tags before queued persistence',
      () async {
    final store = SavedNoteViewStore(preferences: MemoryPreferences());
    addTearDown(store.dispose);
    final filters = {NoteSearchFilter.photos};
    final tags = ['Research'];
    final pending =
        store.create(name: 'Research', filters: filters, tags: tags);
    filters.clear();
    tags.clear();
    final saved = await pending;
    expect(saved.filters, {NoteSearchFilter.photos});
    expect(saved.tags, ['Research']);
    expect(() => saved.tags.add('Mutation'), throwsUnsupportedError);
  });

  test('backup imports preserve data and rollback removes only imported IDs',
      () async {
    final store = SavedNoteViewStore(preferences: MemoryPreferences());
    addTearDown(store.dispose);
    final existing = await store.create(name: 'Existing');
    await store.importViews([
      SavedNoteView(
          id: 'fresh',
          name: 'Restored',
          folderId: 'fresh-folder',
          tags: ['Archive'],
          archiveScope: NoteArchiveScope.archived),
    ]);
    expect(store.views.length, 2);
    await expectLater(
        store.importViews([
          SavedNoteView(id: existing.id, name: 'Collision'),
        ]),
        throwsFormatException);
    expect(store.views.first.name, 'Existing');
    await store.deleteViews({'fresh'});
    expect(store.views.single.id, existing.id);
  });

  test('view names and supported filter values are validated', () {
    expect(() => validatedViewName(' '), throwsFormatException);
    expect(() => validatedViewName('👩🏽‍💻' * 81), throwsFormatException);
    expect(validatedViewName('👩🏽‍💻' * 80), '👩🏽‍💻' * 80);
    expect(
        () => SavedNoteView.fromJson({
              'id': 'view',
              'name': 'View',
              'query': '',
              'filters': ['future-filter'],
              'tags': [],
              'archiveScope': 'active',
            }),
        throwsFormatException);
  });
}
