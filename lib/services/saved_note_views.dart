import 'dart:convert';

import 'package:characters/characters.dart';
import 'package:flutter/foundation.dart';
import 'package:onlynote/services/note_search.dart';
import 'package:onlynote/services/note_tags.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

enum NoteArchiveScope { active, archived, all }

@immutable
class SavedNoteView {
  SavedNoteView({
    required this.id,
    required this.name,
    this.query = '',
    Set<NoteSearchFilter> filters = const {},
    List<String> tags = const [],
    this.folderId,
    this.archiveScope = NoteArchiveScope.active,
  })  : filters = Set.unmodifiable(filters),
        tags = normalizeNoteTags(tags);

  final String id;
  final String name;
  final String query;
  final Set<NoteSearchFilter> filters;
  final List<String> tags;
  final String? folderId;
  final NoteArchiveScope archiveScope;

  SavedNoteView withAvailableFolders(Set<String> folderIds) => SavedNoteView(
        id: id,
        name: name,
        query: query,
        filters: filters,
        tags: tags,
        folderId: folderIds.contains(folderId) ? folderId : null,
        archiveScope: archiveScope,
      );

  SavedNoteView renamed(String name) => SavedNoteView(
        id: id,
        name: validatedViewName(name),
        query: query,
        filters: filters,
        tags: tags,
        folderId: folderId,
        archiveScope: archiveScope,
      );

  Map<String, Object?> toJson() => {
        'id': id,
        'name': name,
        'query': query,
        'filters': [for (final filter in filters) filter.name],
        'tags': tags,
        'folderId': folderId,
        'archiveScope': archiveScope.name,
      };

  factory SavedNoteView.fromJson(Map json) {
    final id = json['id'];
    final name = json['name'];
    final query = json['query'];
    final filters = json['filters'];
    final tags = json['tags'];
    final folderId = json['folderId'];
    final scope = NoteArchiveScope.values
        .where((scope) => scope.name == json['archiveScope'])
        .firstOrNull;
    if (id is! String ||
        id.isEmpty ||
        id.length > 128 ||
        name is! String ||
        query is! String ||
        query.length > 10000 ||
        filters is! List ||
        filters.any((value) =>
            !NoteSearchFilter.values.any((filter) => filter.name == value)) ||
        tags is! List ||
        tags.any((value) => value is! String) ||
        (folderId != null && folderId is! String) ||
        scope == null) {
      throw const FormatException('Invalid saved view');
    }
    return SavedNoteView(
      id: id,
      name: validatedViewName(name),
      query: query,
      filters: {
        for (final value in filters)
          NoteSearchFilter.values.firstWhere((filter) => filter.name == value),
      },
      tags: tags.cast<String>(),
      folderId: folderId as String?,
      archiveScope: scope,
    );
  }
}

String validatedViewName(String value) {
  final name = value.trim();
  if (name.isEmpty || name.characters.length > 80) {
    throw const FormatException('Invalid saved view name');
  }
  return name;
}

class SavedNoteViewStore extends ChangeNotifier {
  SavedNoteViewStore({SharedPreferencesAsync? preferences})
      : _preferences = preferences ?? SharedPreferencesAsync();
  static final instance = SavedNoteViewStore();
  static const storageKey = 'saved_note_views_v1';
  static const maxViews = 30;
  final SharedPreferencesAsync _preferences;
  List<SavedNoteView> _views = [];
  bool _loaded = false;
  Future<void> _tail = Future.value();

  List<SavedNoteView> get views => List.unmodifiable(_views);

  Future<T> _serial<T>(Future<T> Function() operation) {
    final result = _tail.then((_) => operation());
    _tail = result.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return result;
  }

  Future<void> load() => _serial(_load);

  Future<void> _load() async {
    if (_loaded) return;
    final raw = await _preferences.getString(storageKey);
    final views = <SavedNoteView>[];
    if (raw != null) {
      final json = jsonDecode(raw);
      if (json is! Map || json['version'] != 1 || json['views'] is! List) {
        throw const FormatException('Unreadable saved views');
      }
      final ids = <String>{};
      for (final entry in json['views'] as List) {
        if (entry is! Map) throw const FormatException('Unreadable saved view');
        final view = SavedNoteView.fromJson(entry);
        if (!ids.add(view.id) || views.length >= maxViews) {
          throw const FormatException('Invalid saved views');
        }
        views.add(view);
      }
    }
    _views = views;
    _loaded = true;
    notifyListeners();
  }

  Future<void> _write(List<SavedNoteView> views) async {
    await _preferences.setString(
        storageKey,
        jsonEncode({
          'version': 1,
          'views': [for (final v in views) v.toJson()]
        }));
    _views = views;
    notifyListeners();
  }

  Future<SavedNoteView> create({
    required String name,
    String query = '',
    Set<NoteSearchFilter> filters = const {},
    List<String> tags = const [],
    String? folderId,
    NoteArchiveScope archiveScope = NoteArchiveScope.active,
  }) {
    // Capture caller-owned collections before the asynchronous queue runs.
    final view = SavedNoteView(
        id: const Uuid().v4(),
        name: validatedViewName(name),
        query: query,
        filters: filters,
        tags: tags,
        folderId: folderId,
        archiveScope: archiveScope);
    if (query.length > 10000) {
      throw const FormatException('Saved view query is too long');
    }
    return _serial(() async {
      await _load();
      if (_views.length >= maxViews) {
        throw StateError('Saved view limit reached');
      }
      await _write([..._views, view]);
      return view;
    });
  }

  Future<void> rename(String id, String name) => _serial(() async {
        await _load();
        final target = _views.where((view) => view.id == id).firstOrNull;
        if (target == null) throw StateError('Saved view is unavailable');
        final renamed = target.renamed(name);
        await _write([
          for (final view in _views)
            if (view.id == id) renamed else view,
        ]);
      });

  Future<void> delete(String id) => _serial(() async {
        await _load();
        await _write(_views.where((view) => view.id != id).toList());
      });

  /// Backup restore supplies fresh identities and remapped folder IDs.
  Future<void> importViews(List<SavedNoteView> views) {
    final copies = [
      for (final view in views) SavedNoteView.fromJson(view.toJson()),
    ];
    return _serial(() async {
      await _load();
      final ids = _views.map((view) => view.id).toSet();
      if (copies.any((view) => !ids.add(view.id)) ||
          _views.length + copies.length > maxViews) {
        throw const FormatException('Invalid imported saved views');
      }
      await _write([..._views, ...copies]);
    });
  }

  Future<void> deleteViews(Set<String> ids) => _serial(() async {
        await _load();
        await _write(_views.where((view) => !ids.contains(view.id)).toList());
      });
}
