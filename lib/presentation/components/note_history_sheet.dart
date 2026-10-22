import 'package:onlynote/presentation/components/note_document_view.dart';
import 'package:flutter/material.dart';
import 'package:onlynote/data/dto/note_dto.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/app_sheet.dart';
import 'package:onlynote/presentation/components/note_history_content_snippet.dart';
import 'package:onlynote/presentation/components/note_history_search.dart';
import 'package:onlynote/presentation/components/note_history_version_tile.dart';
import 'package:onlynote/presentation/components/search_result_summary.dart';
import 'package:onlynote/presentation/theme/typography.dart';
import 'package:onlynote/services/note_history.dart';
import 'package:onlynote/services/note_dates.dart';

Future<bool?> showNoteHistorySheet(BuildContext context,
        {required String noteId,
        NoteHistory? history,
        VoidCallback? onRestored}) =>
    showAppSheet<bool>(
        context: context,
        builder: (_) => NoteHistorySheet(
            noteId: noteId, history: history, onRestored: onRestored));

/// Versions are previews until the user explicitly chooses Restore. Repository
/// failures keep the selected preview and offer a retry of the same version.
class NoteHistorySheet extends StatefulWidget {
  const NoteHistorySheet({
    super.key,
    required this.noteId,
    this.history,
    this.readVersions,
    this.restoreVersion,
    this.changes,
    this.onRestored,
  });

  final String noteId;
  final NoteHistory? history;
  final List<NoteHistoryVersion> Function()? readVersions;
  final Future<NoteHistoryRestoreResult> Function(String versionId)?
      restoreVersion;
  final Listenable? changes;
  final VoidCallback? onRestored;

  @override
  State<NoteHistorySheet> createState() => _NoteHistorySheetState();
}

class _NoteHistorySheetState extends State<NoteHistorySheet> {
  final _search = TextEditingController();
  NoteHistoryVersion? _selected;
  bool _restoring = false;
  NoteHistoryRestoreResult? _result;
  NoteHistory? get _history =>
      widget.history ?? NoteHistory.initializedInstance;
  Listenable? _changes;

  @override
  void initState() {
    super.initState();
    _changes = widget.changes ?? _history;
    _changes?.addListener(_refresh);
  }

  @override
  void didUpdateWidget(covariant NoteHistorySheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    final changes = widget.changes ?? _history;
    if (identical(changes, _changes)) return;
    _changes?.removeListener(_refresh);
    _changes = changes;
    _changes?.addListener(_refresh);
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _changes?.removeListener(_refresh);
    _search.dispose();
    super.dispose();
  }

  void _clearSearch() {
    if (!mounted || ModalRoute.of(context)?.isCurrent == false) return;
    setState(_search.clear);
  }

  Future<void> _restore() async {
    final selected = _selected;
    if (!mounted ||
        _restoring ||
        selected == null ||
        ModalRoute.of(context)?.isCurrent == false) {
      return;
    }
    final onRestored = widget.onRestored;
    setState(() {
      _restoring = true;
      _result = null;
    });
    NoteHistoryRestoreResult result;
    try {
      result = await (widget.restoreVersion?.call(selected.id) ??
          _history?.restore(widget.noteId, selected.id) ??
          Future.value(NoteHistoryRestoreResult.unavailable));
    } catch (_) {
      result = NoteHistoryRestoreResult.failed;
    }
    if (result == NoteHistoryRestoreResult.restored) {
      // Persistence can complete after the sheet is dismissed. Its owner must
      // still refresh, even though this route can no longer return true.
      try {
        onRestored?.call();
      } catch (error) {
        // A refresh error does not undo the successful repository write.
        debugPrint('Restored note refresh deferred: $error');
      }
    }
    if (!mounted) return;
    if (result == NoteHistoryRestoreResult.restored) {
      // The user may have dismissed or covered this sheet during the write.
      // Its completion must never pop a different route.
      if (ModalRoute.of(context)?.isCurrent != false) {
        Navigator.pop(context, true);
        return;
      }
    }
    setState(() {
      _restoring = false;
      _result = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final selected = _selected;
    final versions = widget.readVersions?.call() ??
        _history?.versionsFor(widget.noteId) ??
        const <NoteHistoryVersion>[];
    final matches = filterNoteHistoryVersions(versions, _search.text,
        searchableText: (version) => _searchableText(version.note));
    return AppSheet(
      title: selected == null ? s.History_Title : s.History_Preview,
      footer: selected == null
          ? null
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_result != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                    child: Text(
                      switch (_result!) {
                        NoteHistoryRestoreResult.failed =>
                          s.History_Restore_Failed,
                        NoteHistoryRestoreResult.unavailable =>
                          s.History_Unavailable,
                        NoteHistoryRestoreResult.unchanged => s.History_Current,
                        NoteHistoryRestoreResult.restored => s.History_Restored,
                      },
                      key: const ValueKey('history-restore-result'),
                      style: TextStyle(
                          color: _result == NoteHistoryRestoreResult.failed ||
                                  _result ==
                                      NoteHistoryRestoreResult.unavailable
                              ? Theme.of(context).colorScheme.error
                              : null),
                    ),
                  ),
                FilledButton.icon(
                  key: const ValueKey('history-restore-action'),
                  onPressed: _restoring ? null : _restore,
                  icon: _restoring
                      ? MediaQuery.disableAnimationsOf(context)
                          ? const Icon(Icons.hourglass_empty_rounded)
                          : const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.restore_rounded),
                  label: Text(_result == NoteHistoryRestoreResult.failed
                      ? s.Retry
                      : s.History_Restore),
                ),
              ],
            ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: selected == null
            ? Column(
                children: [
                  if (versions.isNotEmpty || _search.text.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: NoteHistorySearchField(
                        controller: _search,
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (_search.text.trim().isNotEmpty)
                    SearchResultSummary(
                      key: const ValueKey('history-search-count'),
                      label: s.History_Search_Count(
                          matches.length, versions.length),
                    ),
                  if (matches.isEmpty && _search.text.trim().isNotEmpty)
                    NoteHistorySearchEmpty(onClear: _clearSearch)
                  else if (versions.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(children: [
                        Icon(Icons.history_rounded,
                            size: 36,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant),
                        const SizedBox(height: 16),
                        Text(s.History_Empty, textAlign: TextAlign.center),
                      ]),
                    )
                  else
                    for (final version in matches)
                      NoteHistoryVersionTile(
                        key: ValueKey('history-version-${version.id}'),
                        query: _search.text,
                        title: _title(version.note, s),
                        dateLabel: _date(version.savedAt),
                        snippet: noteHistoryContentSnippet(version.note,
                            query: _search.text),
                        mediaCounts: _MediaCounts(note: version.note),
                        onPressed: () {
                          FocusScope.of(context).unfocus();
                          setState(() {
                            _selected = version;
                            _result = null;
                          });
                        },
                      ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: TextButton.icon(
                      onPressed: _restoring
                          ? null
                          : () => setState(() {
                                _selected = null;
                                _result = null;
                              }),
                      icon: const Icon(Icons.arrow_back_rounded),
                      label: Text(s.History_Title),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: _HistoryPreview(version: selected),
                  ),
                ],
              ),
      ),
    );
  }

  String _date(DateTime date) => noteReaderDateTimeLabel(
        dateTime: date,
        locale: Localizations.localeOf(context).toString(),
        use24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
      );

  String _title(NoteDto note, S s) {
    if (note.title?.trim().isNotEmpty ?? false) return note.title!;
    final snippet = noteHistoryContentSnippet(note);
    return snippet.isEmpty ? s.History_Title : snippet.split('\n').first;
  }

  static Iterable<String> _searchableText(NoteDto note) sync* {
    yield note.title ?? '';
    yield note.description ?? '';
    for (final todo in note.todoList ?? const <TodoDto>[]) {
      yield todo.title ?? '';
    }
    for (final memo in note.voiceMemos ?? const <Map>[]) {
      final transcript = memo['transcript'];
      if (transcript is String) yield transcript;
    }
  }
}

class _HistoryPreview extends StatelessWidget {
  const _HistoryPreview({required this.version});
  final NoteHistoryVersion version;

  @override
  Widget build(BuildContext context) {
    final note = version.note;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
            noteReaderDateTimeLabel(
              dateTime: version.savedAt,
              locale: Localizations.localeOf(context).toString(),
              use24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
            ),
            style: Theme.of(context).textTheme.labelLarge),
        if (note.title?.isNotEmpty ?? false) ...[
          const SizedBox(height: 16),
          SelectableText(note.title!,
              style: Theme.of(context).textTheme.titleLarge),
        ],
        if ((note.description?.isNotEmpty ?? false) ||
            (note.imagePaths?.isNotEmpty ?? false)) ...[
          const SizedBox(height: 12),
          NoteDocumentView(
            text: note.description ?? '',
            styles: note.toDomain().textStyles,
            imagePaths: note.imagePaths ?? const [],
            imageLayouts: note.toDomain().imageLayouts,
            style: AppTypography.formText.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
        if (note.todoList?.isNotEmpty ?? false) ...[
          const SizedBox(height: 16),
          for (final todo in note.todoList!)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Semantics(
                checked: todo.completed ?? false,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                        todo.completed ?? false
                            ? Icons.check_circle_outline_rounded
                            : Icons.radio_button_unchecked_rounded,
                        size: 22),
                    const SizedBox(width: 12),
                    Expanded(child: SelectableText(todo.title ?? '')),
                  ],
                ),
              ),
            ),
        ],
        _MediaCounts(note: note),
        for (final memo in note.voiceMemos ?? const <Map>[])
          if (memo['transcript'] is String &&
              (memo['transcript'] as String).trim().isNotEmpty) ...[
            const SizedBox(height: 16),
            Row(children: [
              const Icon(Icons.mic_none_rounded, size: 20),
              const SizedBox(width: 8),
              Text(_duration(memo['durationMs'])),
            ]),
            const SizedBox(height: 8),
            SelectableText(memo['transcript'] as String),
          ],
      ],
    );
  }

  static String _duration(Object? milliseconds) {
    final seconds = milliseconds is num
        ? (milliseconds.toInt() ~/ 1000).clamp(0, 86400)
        : 0;
    return '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
  }
}

class _MediaCounts extends StatelessWidget {
  const _MediaCounts({required this.note});
  final NoteDto note;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final images = note.imagePaths?.length ?? 0;
    final recordings = note.voiceMemos?.length ?? 0;
    if (images == 0 && recordings == 0) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Wrap(spacing: 16, runSpacing: 8, children: [
        if (images > 0)
          Text.rich(TextSpan(children: [
            const WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: Icon(Icons.photo_outlined, size: 18)),
            TextSpan(text: '  ${s.History_Photos(images)}'),
          ])),
        if (recordings > 0)
          Text.rich(TextSpan(children: [
            const WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: Icon(Icons.mic_none_rounded, size: 18)),
            TextSpan(text: '  ${s.History_Recordings(recordings)}'),
          ])),
      ]),
    );
  }
}
