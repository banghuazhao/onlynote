import 'package:onlynote/domain/model/custom_note_template.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/services/note_templates.dart';

/// Searches loaded, user-facing template text without opening media or storage.
/// Create once per filtering pass so both template groups share one pattern.
class TemplateContentSearch {
  TemplateContentSearch(String query) : _pattern = _compile(query);

  final RegExp? _pattern;

  static RegExp? _compile(String query) {
    final trimmed = query.trim();
    return trimmed.isEmpty
        ? null
        : RegExp(RegExp.escape(trimmed), caseSensitive: false, unicode: true);
  }

  bool _matches(Iterable<String> text) =>
      _pattern == null || text.any(_pattern.hasMatch);

  List<CustomNoteTemplate> filterCustom(
          Iterable<CustomNoteTemplate> templates) =>
      templates.where((template) => _matches(_customText(template))).toList(
            growable: false,
          );

  List<NoteTemplate> filterBuiltIn(
          Iterable<NoteTemplate> templates, S strings) =>
      templates.where((template) {
        final content = template.content(strings);
        return _matches([
          content.title,
          content.summary,
          content.body,
          ...content.items,
        ]);
      }).toList(growable: false);

  static Iterable<String> _customText(CustomNoteTemplate template) sync* {
    yield template.name;
    yield template.title;
    yield template.body;
    yield* template.items;
    yield* template.tags;
    for (final memo in template.voiceMemos) {
      final transcript = memo.transcript;
      if (transcript != null) yield transcript;
    }
  }
}
