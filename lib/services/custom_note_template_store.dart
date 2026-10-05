import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:onlynote/domain/model/custom_note_template.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'custom_template_images.dart';
import 'custom_template_images_factory.dart';

class CustomNoteTemplateStore extends ChangeNotifier {
  CustomNoteTemplateStore({
    SharedPreferencesAsync? preferences,
    CustomTemplateImages? images,
    String? documentsPath,
  })  : _preferences = preferences ?? SharedPreferencesAsync(),
        _images =
            images ?? createDeviceTemplateImages(documentsPath: documentsPath);

  static final instance = CustomNoteTemplateStore();
  static const storageKey = 'custom_note_templates_v1';
  final SharedPreferencesAsync _preferences;
  final CustomTemplateImages _images;
  List<CustomNoteTemplate> _templates = [];
  bool _loaded = false;
  Future<void> _tail = Future.value();

  List<CustomNoteTemplate> get templates => List.unmodifiable(_templates);

  Future<T> _serial<T>(Future<T> Function() operation) {
    final result = _tail.then((_) => operation());
    _tail = result.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return result;
  }

  Future<void> load() => _serial(_load);

  Future<void> _load({bool prune = true}) async {
    if (_loaded) return;
    final value = await _preferences.getString(storageKey);
    final templates = <CustomNoteTemplate>[];
    if (value != null) {
      final data = jsonDecode(value);
      if (data is! Map || data['version'] != 1 || data['templates'] is! List) {
        throw const FormatException('Unreadable templates');
      }
      for (final record in data['templates'] as List) {
        if (record is! Map) throw const FormatException('Unreadable template');
        templates.add(
            CustomNoteTemplate.fromJson(Map<String, dynamic>.from(record)));
      }
      _validate(templates);
    }
    _templates = templates;
    _loaded = true;
    notifyListeners();
    if (prune) {
      try {
        await _images.pruneTemplates({
          for (final template in templates) ...template.imagePaths,
        });
      } catch (_) {
        // Housekeeping must never prevent reading valid template content.
      }
    }
  }

  void _validate(List<CustomNoteTemplate> templates) {
    final ids = <String>{};
    for (final template in templates) {
      validatedTemplateName(template.name);
      if (template.id.isEmpty ||
          !ids.add(template.id) ||
          (template.color != null &&
              (template.color! < 0 || template.color! > 0xffffffff)) ||
          template.imagePaths.any((path) => !isOwnedTemplateImagePath(path))) {
        throw const FormatException('Invalid template references');
      }
    }
  }

  Future<void> _write(List<CustomNoteTemplate> templates) async {
    _validate(templates);
    await _preferences.setString(
        storageKey,
        jsonEncode({
          'version': 1,
          'templates': [for (final template in templates) template.toJson()],
        }));
    _templates = templates;
    notifyListeners();
  }

  Future<CustomNoteTemplate> saveFromNote(Note note, {required String name}) =>
      _serial(() async {
        await _load();
        validatedTemplateName(name);
        final photos = await _images.copyToTemplate(note.imagePaths);
        try {
          final template = CustomNoteTemplate.fromNote(note,
              name: name, imageCopies: photos);
          await _write([..._templates, template]);
          return template;
        } catch (_) {
          await _images.deleteTemplates(photos);
          rethrow;
        }
      });

  Future<void> rename(String id, String name) => _serial(() async {
        await _load();
        validatedTemplateName(name);
        if (!_templates.any((template) => template.id == id)) {
          throw StateError('Template no longer exists');
        }
        await _write([
          for (final template in _templates)
            template.id == id ? template.copyWith(name: name) : template,
        ]);
      });

  Future<void> delete(String id) => deleteTemplates({id});

  Future<void> deleteTemplates(Set<String> ids) => _serial(() async {
        await _load();
        final removed =
            _templates.where((template) => ids.contains(template.id)).toList();
        if (removed.isEmpty) return;
        final retained =
            _templates.where((template) => !ids.contains(template.id)).toList();
        await _write(retained);
        final keep = {for (final template in retained) ...template.imagePaths};
        await _images.deleteTemplates([
          for (final template in removed)
            ...template.imagePaths.where((path) => !keep.contains(path)),
        ]);
      });

  /// Backup restore owns new IDs/photos and its own rollback journal.
  Future<void> importTemplates(List<CustomNoteTemplate> templates) =>
      _serial(() async {
        // Import owns staged photos that aren't referenced by stored records yet.
        await _load(prune: false);
        await _write([..._templates, ...templates]);
      });

  Future<Note> createNote(String id, {String? folderId, DateTime? now}) =>
      _serial(() async {
        await _load();
        final template =
            _templates.where((template) => template.id == id).firstOrNull;
        if (template == null) throw StateError('Template no longer exists');
        final photos = await _images.copyToNote(template.imagePaths);
        return template.createNote(
            imageCopies: photos, folderId: folderId, now: now);
      });
}
