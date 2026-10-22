import 'package:flutter/material.dart';
import 'package:onlynote/domain/model/custom_note_template.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/services/recording_duration.dart';
import 'package:onlynote/services/note_search.dart';
import 'package:onlynote/services/note_templates.dart';

import 'search_highlight.dart';

const _snippetLength = 160;

/// A display-only prefix from stored text; it never opens template media.
String templateContentSnippet(CustomNoteTemplate template,
    {String query = ''}) {
  final match = _matchingSnippet(_searchableContent(template), query);
  if (match.isNotEmpty) return match;
  final body = _prefix([template.body]);
  if (body.isNotEmpty) return body;
  final checklist = _prefix(template.items);
  if (checklist.isNotEmpty) return checklist;
  final title = _prefix([template.title]);
  final name = _prefix([template.name]);
  return title.toLowerCase() == name.toLowerCase() ? '' : title;
}

/// Starter summaries stay familiar unless another stored field explains search.
String starterTemplateContentSnippet(NoteTemplateContent content,
    {String query = ''}) {
  final match = _matchingSnippet(
      [content.summary, content.body, ...content.items], query);
  return match.isEmpty ? content.summary : match;
}

String _matchingSnippet(Iterable<String> text, String query) {
  final pattern = searchPattern(query);
  if (pattern == null) return '';
  for (final value in text) {
    if (pattern.hasMatch(value)) {
      return _prefix([searchExcerpt(value, query, leadingContext: 0)]);
    }
  }
  return '';
}

Iterable<String> _searchableContent(CustomNoteTemplate template) sync* {
  yield template.body;
  yield* template.items;
  for (final memo in template.voiceMemos) {
    if (memo.transcript case final String text) yield text;
  }
  yield* template.tags;
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

/// Keeps content and media metadata together without opening template files.
class TemplateContentSubtitle extends StatelessWidget {
  const TemplateContentSubtitle(
      {super.key, required this.template, this.query = ''});

  final CustomNoteTemplate template;
  final String query;

  @override
  Widget build(BuildContext context) {
    final snippet = templateContentSnippet(template, query: query);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (snippet.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 6),
            child: SearchHighlight(
              snippet,
              key: ValueKey('template-content-snippet-${template.id}'),
              query: query,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        Text(
          S.of(context).Template_Details(
              template.items.length, template.imagePaths.length),
          key: ValueKey('template-content-counts-${template.id}'),
        ),
        if (template.voiceMemos.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '${S.of(context).History_Recordings(template.voiceMemos.length)} · '
              '${formatRecordingDuration(totalRecordingDurationMs(template.voiceMemos))}',
              key: ValueKey('template-recording-details-${template.id}'),
            ),
          ),
      ],
    );
  }
}
