import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/services/note_tags.dart';

import 'app_sheet.dart';

/// Only an explicit save returns tags. Closing or cancelling returns null.
Future<List<String>?> showNoteTagsSheet(
  BuildContext context, {
  required List<String> tags,
  List<String> suggestions = const [],
}) =>
    showAppSheet<List<String>>(
      context: context,
      builder: (_) => NoteTagsSheet(tags: tags, suggestions: suggestions),
    );

class NoteTagsSheet extends StatefulWidget {
  const NoteTagsSheet({
    super.key,
    required this.tags,
    this.suggestions = const [],
  });

  final List<String> tags;
  final List<String> suggestions;

  @override
  State<NoteTagsSheet> createState() => _NoteTagsSheetState();
}

class _NoteTagsSheetState extends State<NoteTagsSheet> {
  final _controller = TextEditingController();
  late List<String> _tags;
  late final List<String> _suggestions;
  bool _invalid = false;
  String _lastInput = '';

  @override
  void initState() {
    super.initState();
    _tags = normalizeNoteTags(widget.tags).toList();
    // Suggestions can come from many notes; their combined count is unlimited.
    final keys = <String>{};
    _suggestions = [];
    for (final suggestion in widget.suggestions) {
      try {
        final normalized = normalizeNoteTags([suggestion]);
        if (normalized.isNotEmpty && keys.add(tagKey(normalized.single))) {
          _suggestions.add(normalized.single);
        }
      } on FormatException {
        // A malformed suggestion must not prevent editing valid note tags.
      }
    }
    _controller.addListener(_inputChanged);
  }

  void _inputChanged() {
    if (_controller.text == _lastInput) return;
    _lastInput = _controller.text;
    setState(() => _invalid = false);
  }

  bool _add(String value, {bool clearInput = false}) {
    try {
      final tags = normalizeNoteTags([..._tags, value]);
      setState(() {
        _tags = tags.toList();
        _invalid = false;
      });
      if (clearInput) _controller.clear();
      return true;
    } on FormatException {
      setState(() => _invalid = true);
      return false;
    }
  }

  void _remove(String tag) => setState(() {
        _tags.removeWhere((value) => tagKey(value) == tagKey(tag));
        _invalid = false;
      });

  void _save() {
    if (!_add(_controller.text, clearInput: true)) return;
    Navigator.pop(context, normalizeNoteTags(_tags));
  }

  @override
  void dispose() {
    _controller.removeListener(_inputChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final colors = Theme.of(context).colorScheme;
    final selectedKeys = _tags.map(tagKey).toSet();
    final query = tagKey(_controller.text);
    final suggestions = _suggestions
        .where((suggestion) =>
            !selectedKeys.contains(tagKey(suggestion)) &&
            tagKey(suggestion).contains(query))
        .toList();
    final noMatchingSuggestions =
        _suggestions.isNotEmpty && query.isNotEmpty && suggestions.isEmpty;
    final chipAnimation = MediaQuery.disableAnimationsOf(context)
        ? ChipAnimationStyle(
            enableAnimation: AnimationStyle.noAnimation,
            selectAnimation: AnimationStyle.noAnimation,
            avatarDrawerAnimation: AnimationStyle.noAnimation,
            deleteDrawerAnimation: AnimationStyle.noAnimation,
          )
        : null;

    return AppSheet(
      title: l10n.Edit_Tags,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              key: const ValueKey('note-tag-input'),
              controller: _controller,
              textInputAction: TextInputAction.done,
              onSubmitted: (value) => _add(value, clearInput: true),
              onTapOutside: (_) => FocusScope.of(context).unfocus(),
              decoration: InputDecoration(
                labelText: l10n.Tags,
                hintText: l10n.Tag_Hint,
                border: const OutlineInputBorder(),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_controller.text.isNotEmpty)
                      IconButton(
                        key: const ValueKey('note-tags-clear-input'),
                        tooltip: l10n.Clear_Search,
                        onPressed: _controller.clear,
                        icon: const Icon(Icons.clear_rounded),
                      ),
                    IconButton(
                      key: const ValueKey('note-tags-add'),
                      tooltip: l10n.Tag_Hint,
                      onPressed: query.isEmpty
                          ? null
                          : () => _add(_controller.text, clearInput: true),
                      icon: const Icon(Icons.add_rounded),
                    ),
                  ],
                ),
              ),
            ),
            if (_invalid) ...[
              const SizedBox(height: 8),
              Semantics(
                liveRegion: true,
                child: Text(
                  l10n.Tag_Invalid,
                  key: const ValueKey('note-tags-error'),
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: colors.error),
                ),
              ),
            ],
            const SizedBox(height: 16),
            LayoutBuilder(builder: (context, constraints) {
              // RawChip reserves room for its controls after measuring text.
              // Constraining the label first keeps long tags fully readable.
              Widget label(String tag) => ConstrainedBox(
                    constraints: BoxConstraints(
                        minHeight: 24,
                        maxWidth: math.max(0, constraints.maxWidth - 80)),
                    child: Text(tag),
                  );
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_tags.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final tag in _tags)
                          InputChip(
                            key: ValueKey('note-tag-${tagKey(tag)}'),
                            label: label(tag),
                            onDeleted: () => _remove(tag),
                            deleteIcon: Icon(Icons.close_rounded,
                                key:
                                    ValueKey('note-tag-remove-${tagKey(tag)}')),
                            deleteIconBoxConstraints:
                                const BoxConstraints.tightFor(
                                    width: 48, height: 24),
                            deleteButtonTooltipMessage:
                                '${MaterialLocalizations.of(context).deleteButtonTooltip} $tag',
                            materialTapTargetSize: MaterialTapTargetSize.padded,
                            chipAnimationStyle: chipAnimation,
                          ),
                      ],
                    ),
                  if (_tags.isNotEmpty &&
                      (suggestions.isNotEmpty || noMatchingSuggestions))
                    const Divider(height: 24),
                  if (suggestions.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final tag in suggestions)
                          ActionChip(
                            key: ValueKey('note-tag-suggestion-${tagKey(tag)}'),
                            label: label(tag),
                            avatar: const Icon(Icons.add_rounded, size: 18),
                            avatarBoxConstraints: const BoxConstraints.tightFor(
                                width: 24, height: 24),
                            onPressed: () => _add(tag, clearInput: true),
                            materialTapTargetSize: MaterialTapTargetSize.padded,
                            chipAnimationStyle: chipAnimation,
                          ),
                      ],
                    ),
                  if (noMatchingSuggestions)
                    Text(
                      l10n.Tag_Suggestions_Empty,
                      key: const ValueKey('note-tag-suggestions-empty'),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                    ),
                ],
              );
            }),
            const SizedBox(height: 20),
            FilledButton.icon(
              key: const ValueKey('note-tags-save'),
              onPressed: _save,
              icon: const Icon(Icons.check_rounded),
              label: Text(l10n.Done),
            ),
            const SizedBox(height: 8),
            TextButton(
              key: const ValueKey('note-tags-cancel'),
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.Cancel),
            ),
          ],
        ),
      ),
    );
  }
}
