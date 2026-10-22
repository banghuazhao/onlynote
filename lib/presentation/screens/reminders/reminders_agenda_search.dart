import 'package:flutter/material.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/search_result_summary.dart';
import 'package:onlynote/services/note_search.dart';
import 'package:onlynote/services/reminder_agenda.dart';

import 'reminders_agenda_list.dart';

/// Filters the loaded notes without changing reminder order or schedule.
/// Only stored text is searched; recording files and photo text stay unloaded.
List<ReminderAgendaEntry> filterReminderAgenda(
    List<ReminderAgendaEntry> entries, String query) {
  final pattern = searchPattern(query);
  if (pattern == null) return entries;
  return entries.where((entry) {
    final note = entry.note;
    return pattern.hasMatch(note.title ?? '') ||
        pattern.hasMatch(note.description ?? '') ||
        note.todo.any((todo) => pattern.hasMatch(todo.title ?? '')) ||
        note.tags.any(pattern.hasMatch) ||
        note.voiceMemos.any((memo) => pattern.hasMatch(memo.transcript ?? ''));
  }).toList(growable: false);
}

/// Local search state stays in place while the controller refreshes its data.
/// This view has no storage, notification, or navigation dependencies.
class SearchableRemindersAgenda extends StatefulWidget {
  const SearchableRemindersAgenda({
    super.key,
    required this.entries,
    required this.now,
    required this.onOpen,
    required this.onSnooze,
    required this.onReschedule,
    this.busyReminderId,
    this.onRefresh,
    this.loading = false,
  });

  final List<ReminderAgendaEntry> entries;
  final DateTime now;
  final int? busyReminderId;
  final ValueChanged<ReminderAgendaEntry> onOpen;
  final ValueChanged<ReminderAgendaEntry> onSnooze;
  final ValueChanged<ReminderAgendaEntry> onReschedule;
  final Future<void> Function()? onRefresh;
  final bool loading;

  @override
  State<SearchableRemindersAgenda> createState() =>
      _SearchableRemindersAgendaState();
}

class _SearchableRemindersAgendaState extends State<SearchableRemindersAgenda> {
  final _search = TextEditingController();

  void _clearSearch() {
    if (!mounted || ModalRoute.of(context)?.isCurrent == false) return;
    setState(_search.clear);
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final query = _search.text;
    final matches = filterReminderAgenda(widget.entries, query);
    final initiallyLoading = widget.loading && widget.entries.isEmpty;
    return Column(children: [
      Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              key: const ValueKey('reminders-search'),
              controller: _search,
              textInputAction: TextInputAction.search,
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => FocusScope.of(context).unfocus(),
              onTapOutside: (_) => FocusScope.of(context).unfocus(),
              decoration: InputDecoration(
                labelText: l10n.Reminders_Search,
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: query.isEmpty
                    ? null
                    : IconButton(
                        key: const ValueKey('reminders-clear-search'),
                        tooltip: l10n.Clear_Search,
                        onPressed: _clearSearch,
                        icon: const Icon(Icons.close_rounded),
                      ),
              ),
            ),
          ),
        ),
      ),
      if (query.trim().isNotEmpty && !initiallyLoading)
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: SearchResultSummary(
                key: const ValueKey('reminders-search-count'),
                label: l10n.Reminders_Search_Count(
                    matches.length, widget.entries.length),
              ),
            ),
          ),
        ),
      if (initiallyLoading)
        const Expanded(child: Center(child: CircularProgressIndicator()))
      else
        Expanded(
          child: RemindersAgendaList(
            // Each new query starts with its first matching reminder visible.
            key: ValueKey(query.trim()),
            entries: matches,
            searchQuery: query,
            now: widget.now,
            busyReminderId: widget.busyReminderId,
            onRefresh: widget.onRefresh,
            onOpen: widget.onOpen,
            onSnooze: widget.onSnooze,
            onReschedule: widget.onReschedule,
            emptyState: query.trim().isEmpty
                ? null
                : _ReminderSearchEmpty(onClear: _clearSearch),
          ),
        ),
    ]);
  }
}

class _ReminderSearchEmpty extends StatelessWidget {
  const _ReminderSearchEmpty({required this.onClear});

  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final theme = Theme.of(context);
    return Padding(
      key: const ValueKey('reminders-search-empty'),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off_rounded,
              size: 48, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(height: 20),
          Semantics(
            liveRegion: true,
            child: Text(l10n.Reminders_Search_Empty_Title,
                textAlign: TextAlign.center, style: theme.textTheme.titleLarge),
          ),
          const SizedBox(height: 8),
          Text(l10n.Reminders_Search_Empty_Message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 12),
          TextButton.icon(
            key: const ValueKey('reminders-empty-clear-search'),
            onPressed: onClear,
            icon: const Icon(Icons.close_rounded),
            label: Text(l10n.Clear_Search),
          ),
        ],
      ),
    );
  }
}
