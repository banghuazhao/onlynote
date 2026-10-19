import 'package:flutter/material.dart';
import 'package:onlynote/domain/model/custom_note_template.dart';
import 'package:onlynote/generated/l10n.dart';

const _snippetLength = 160;

/// A display-only prefix from stored text; it never opens template media.
String templateContentSnippet(CustomNoteTemplate template) {
  final body = _prefix([template.body]);
  if (body.isNotEmpty) return body;
  final checklist = _prefix(template.items);
  if (checklist.isNotEmpty) return checklist;
  final title = _prefix([template.title]);
  final name = _prefix([template.name]);
  return title.toLowerCase() == name.toLowerCase() ? '' : title;
}

String _prefix(Iterable<String> parts) {
  // Only inspect enough normalized graphemes to detect a truncated prefix.
  final characters =
      _normalizedCharacters(parts).take(_snippetLength + 1).toList();
  if (characters.length <= _snippetLength) return characters.join();
  return '${characters.take(_snippetLength).join().trimRight()}…';
}

Iterable<String> _normalizedCharacters(Iterable<String> parts) sync* {
  var previousPart = false;
  for (final text in parts) {
    var started = false;
    var pendingSpace = false;
    for (final character in text.characters) {
      if (character.trim().isEmpty) {
        if (started) pendingSpace = true;
        continue;
      }
      if (!started && previousPart) {
        yield ' ';
        yield '·';
        yield ' ';
      } else if (pendingSpace) {
        yield ' ';
      }
      yield character;
      started = true;
      previousPart = true;
      pendingSpace = false;
    }
  }
}

/// Keeps the existing checklist/photo counts alongside the content preview.
class TemplateContentSubtitle extends StatelessWidget {
  const TemplateContentSubtitle({super.key, required this.template});

  final CustomNoteTemplate template;

  @override
  Widget build(BuildContext context) {
    final snippet = templateContentSnippet(template);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (snippet.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 6),
            child: Text(
              snippet,
              key: ValueKey('template-content-snippet-${template.id}'),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        Text(
          S.of(context).Template_Details(
              template.items.length, template.imagePaths.length),
          key: ValueKey('template-content-counts-${template.id}'),
        ),
      ],
    );
  }
}
