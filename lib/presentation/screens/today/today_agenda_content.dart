import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/note_link_content_snippet.dart';
import 'package:onlynote/presentation/components/reminder_labels.dart';
import 'package:onlynote/presentation/theme/spacing.dart';
import 'package:onlynote/services/reminder_agenda.dart';
import 'package:onlynote/services/today_agenda.dart';

enum _TodayRow {
  loadFailure,
  date,
  dailyNote,
  reminderHeading,
  noReminders,
  taskHeading,
  taskSearch,
  noTasks
}

/// Storage-free content used by the live screen and isolated widget previews.
/// A single virtualized list keeps long checklists responsive on small devices.
class TodayAgendaContent extends StatefulWidget {
  const TodayAgendaContent({
    super.key,
    required this.agenda,
    required this.now,
    required this.onOpenDailyNote,
    required this.onOpenNote,
    required this.onOpenReminders,
    required this.onCompleteTask,
    this.onRefresh,
    this.loading = false,
    this.loadFailed = false,
    this.navigating = false,
    this.busyTaskKey,
    this.initialTaskQuery = '',
  });

  final TodayAgenda agenda;
  final DateTime now;
  final VoidCallback onOpenDailyNote;
  final ValueChanged<String> onOpenNote;
  final VoidCallback onOpenReminders;
  final ValueChanged<TodayTaskEntry> onCompleteTask;
  final Future<void> Function()? onRefresh;
  final bool loading;
  final bool loadFailed;
  final bool navigating;
  final String? busyTaskKey;
  final String initialTaskQuery;

  @override
  State<TodayAgendaContent> createState() => _TodayAgendaContentState();
}

class _TodayAgendaContentState extends State<TodayAgendaContent> {
  late final _search = TextEditingController(text: widget.initialTaskQuery);

  bool get _canChangeSearch =>
      mounted && ModalRoute.of(context)?.isCurrent != false;

  void _searchChanged(String _) {
    if (_canChangeSearch) setState(() {});
  }

  void _clearSearch() {
    if (_canChangeSearch) setState(_search.clear);
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  bool get _actionsEnabled => !widget.navigating && widget.busyTaskKey == null;

  @override
  Widget build(BuildContext context) {
    final strings = S.of(context);
    final theme = Theme.of(context);
    final query = _search.text.trim();
    final tasks = searchTodayTasks(widget.agenda.tasks, query);
    final rows = <Object>[
      if (widget.loadFailed) _TodayRow.loadFailure,
      _TodayRow.date,
      _TodayRow.dailyNote,
      _TodayRow.reminderHeading,
      for (final group in [
        ReminderAgendaGroup.overdue,
        ReminderAgendaGroup.today
      ])
        if (widget.agenda.reminders
            .any((entry) => entry.groupAt(widget.now) == group)) ...[
          group,
          ...widget.agenda.reminders
              .where((entry) => entry.groupAt(widget.now) == group),
        ],
      if (widget.agenda.reminders.isEmpty) _TodayRow.noReminders,
      _TodayRow.taskHeading,
      _TodayRow.taskSearch,
      if (tasks.isEmpty) _TodayRow.noTasks,
      ...tasks,
    ];
    final rowIds = [for (final row in rows) _rowId(row)];
    final positions = {
      for (var index = 0; index < rowIds.length; index++) rowIds[index]: index
    };
    final list = ListView.builder(
      key: const ValueKey('today-agenda-list'),
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      itemCount: rows.length,
      findChildIndexCallback: (key) =>
          key is ValueKey<String> ? positions[key.value] : null,
      itemBuilder: (context, index) => Center(
        key: ValueKey(rowIds[index]),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: context.tokens.contentMaxWidth),
          child: SizedBox(
            width: double.infinity,
            child: switch (rows[index]) {
              _TodayRow.loadFailure => MaterialBanner(
                  content: Text(strings.Today_Load_Failed),
                  leading: const Icon(Icons.info_outline_rounded),
                  actions: [
                    TextButton(
                        onPressed: widget.loading ? null : widget.onRefresh,
                        child: Text(strings.Retry)),
                  ],
                ),
              _TodayRow.date => Padding(
                  padding: const EdgeInsets.fromLTRB(4, 4, 4, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat.yMMMMEEEEd(
                                Localizations.localeOf(context).toString())
                            .format(widget.now.toLocal()),
                        key: const ValueKey('today-date'),
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(strings.Today_Description,
                          style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant)),
                    ],
                  ),
                ),
              _TodayRow.dailyNote => _DailyNoteCard(
                  note: widget.agenda.dailyNote,
                  enabled: _actionsEnabled,
                  onOpen: widget.onOpenDailyNote,
                ),
              _TodayRow.reminderHeading => _SectionHeading(
                  title: strings.Today_Reminders,
                  count: widget.agenda.reminders.length,
                  action: TextButton.icon(
                    key: const ValueKey('today-all-reminders'),
                    onPressed: _actionsEnabled ? widget.onOpenReminders : null,
                    icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                    label: Text(strings.Today_All_Reminders),
                  ),
                ),
              _TodayRow.noReminders => _EmptySection(
                  icon: Icons.event_available_outlined,
                  text: strings.Today_No_Reminders,
                ),
              _TodayRow.taskHeading => _SectionHeading(
                  title: strings.Today_Tasks,
                  count: widget.agenda.tasks.length,
                  subtitle: strings.Today_Tasks_Hint,
                ),
              _TodayRow.taskSearch => Padding(
                  padding: const EdgeInsets.fromLTRB(0, 0, 0, 12),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextField(
                          key: const ValueKey('today-task-search'),
                          controller: _search,
                          onChanged: _searchChanged,
                          textInputAction: TextInputAction.search,
                          decoration: InputDecoration(
                            labelText: strings.Today_Task_Search,
                            prefixIcon: const Icon(Icons.search_rounded),
                            suffixIcon: _search.text.isEmpty
                                ? null
                                : IconButton(
                                    key: const ValueKey(
                                        'today-task-search-clear'),
                                    tooltip: strings.Clear_Search,
                                    onPressed: _clearSearch,
                                    icon: const Icon(Icons.close_rounded),
                                  ),
                          ),
                        ),
                        if (query.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
                            child: Semantics(
                                liveRegion: true,
                                child: Text(
                                    strings.Today_Task_Search_Count(
                                        tasks.length,
                                        widget.agenda.tasks.length),
                                    key: const ValueKey(
                                        'today-task-search-count'),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                        color: theme
                                            .colorScheme.onSurfaceVariant))),
                          ),
                      ]),
                ),
              _TodayRow.noTasks => _EmptySection(
                  icon: query.isEmpty
                      ? Icons.task_alt_rounded
                      : Icons.search_off_rounded,
                  text: query.isEmpty
                      ? strings.Today_No_Tasks
                      : strings.Today_Task_No_Matches,
                ),
              final ReminderAgendaGroup group => Padding(
                  padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
                  child: Semantics(
                    header: true,
                    child: Text(
                      group == ReminderAgendaGroup.overdue
                          ? strings.Reminders_Overdue
                          : strings.Reminders_Today,
                      style: theme.textTheme.labelLarge?.copyWith(
                          color: group == ReminderAgendaGroup.overdue
                              ? theme.colorScheme.error
                              : theme.colorScheme.onSurfaceVariant),
                    ),
                  ),
                ),
              final ReminderAgendaEntry entry => _ReminderRow(
                  entry: entry,
                  overdue:
                      entry.groupAt(widget.now) == ReminderAgendaGroup.overdue,
                  onOpen: _actionsEnabled
                      ? () => widget.onOpenNote(entry.note.id!)
                      : null,
                ),
              final TodayTaskEntry entry => _TaskRow(
                  entry: entry,
                  busy: widget.busyTaskKey == entry.key,
                  onOpen: _actionsEnabled
                      ? () => widget.onOpenNote(entry.note.id!)
                      : null,
                  onComplete: _actionsEnabled && entry.canComplete
                      ? () => widget.onCompleteTask(entry)
                      : null,
                ),
              _ => const SizedBox.shrink(),
            },
          ),
        ),
      ),
    );
    return Column(
      children: [
        if (widget.loading)
          const LinearProgressIndicator(key: ValueKey('today-loading')),
        Expanded(
          child: widget.onRefresh == null
              ? list
              : RefreshIndicator(onRefresh: widget.onRefresh!, child: list),
        ),
      ],
    );
  }
}

String _rowId(Object row) => switch (row) {
      final _TodayRow kind => 'section:${kind.name}',
      final ReminderAgendaGroup group => 'group:${group.name}',
      final ReminderAgendaEntry entry =>
        'reminder:${entry.reminder.reminderId}',
      final TodayTaskEntry entry => 'task:${entry.key}',
      _ => row.toString(),
    };

class _DailyNoteCard extends StatelessWidget {
  const _DailyNoteCard(
      {required this.note, required this.enabled, required this.onOpen});

  final Note? note;
  final bool enabled;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final strings = S.of(context);
    final theme = Theme.of(context);
    final snippet = note == null ? '' : noteLinkContentSnippet(note!);
    return Card.filled(
      key: const ValueKey('today-daily-note'),
      margin: EdgeInsets.zero,
      color: theme.colorScheme.primaryContainer,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: enabled ? onOpen : null,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(Icons.wb_sunny_outlined,
                    color: theme.colorScheme.onPrimaryContainer),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(strings.Today_Note,
                      style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer)),
                ),
                Icon(Icons.arrow_forward_rounded,
                    color: theme.colorScheme.onPrimaryContainer),
              ]),
              const SizedBox(height: 12),
              if (note != null)
                Text(_noteTitle(context, note!),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleLarge?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer)),
              if (note == null || snippet.isNotEmpty) ...[
                if (note != null) const SizedBox(height: 6),
                Text(note == null ? strings.Today_Daily_Empty : snippet,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer)),
              ],
              if (note?.isArchived == true) ...[
                const SizedBox(height: 8),
                Text(strings.Archive,
                    style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer)),
              ],
              if (note == null) ...[
                const SizedBox(height: 12),
                Text(strings.Today_Create_Note,
                    style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading(
      {required this.title, required this.count, this.subtitle, this.action});

  final String title;
  final int count;
  final String? subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 24, 4, 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          children: [
            Semantics(
              header: true,
              child:
                  Text('$title · $count', style: theme.textTheme.titleMedium),
            ),
            if (action != null) action!,
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(subtitle!,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ],
      ]),
    );
  }
}

class _EmptySection extends StatelessWidget {
  const _EmptySection({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
        child: Row(children: [
          Icon(icon, color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(
              child: Text(text, style: Theme.of(context).textTheme.bodyMedium)),
        ]),
      );
}

class _ReminderRow extends StatelessWidget {
  const _ReminderRow({required this.entry, required this.overdue, this.onOpen});
  final ReminderAgendaEntry entry;
  final bool overdue;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final repeat = entry.reminder.isRepeating
        ? reminderRepeatLabel(context, entry.reminder.repeat)
        : null;
    return Card.outlined(
      key: ValueKey('today-reminder-${entry.reminder.reminderId}'),
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Icon(Icons.alarm_outlined,
            color:
                overdue ? theme.colorScheme.error : theme.colorScheme.primary),
        title: Text(_noteTitle(context, entry.note),
            maxLines: 3, overflow: TextOverflow.ellipsis),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text([
            formatReminderTime(context, entry.dueDate),
            if (repeat != null) repeat,
            if (entry.snoozed) S.of(context).Reminders_Snoozed,
          ].join(' · ')),
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onOpen,
      ),
    );
  }
}

class _TaskRow extends StatelessWidget {
  const _TaskRow(
      {required this.entry, required this.busy, this.onOpen, this.onComplete});
  final TodayTaskEntry entry;
  final bool busy;
  final VoidCallback? onOpen;
  final VoidCallback? onComplete;

  @override
  Widget build(BuildContext context) => Card.outlined(
        key: ValueKey('today-task-${entry.key}'),
        margin: const EdgeInsets.only(bottom: 8),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          contentPadding: const EdgeInsets.fromLTRB(4, 8, 12, 8),
          leading: SizedBox(
            width: 48,
            height: 48,
            child: busy
                ? const Padding(
                    padding: EdgeInsets.all(14),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Checkbox(
                    key: ValueKey('today-complete-${entry.key}'),
                    value: false,
                    semanticLabel: entry.todo.title,
                    onChanged: onComplete == null ? null : (_) => onComplete!(),
                  ),
          ),
          title: Text(entry.todo.title!.trim(),
              maxLines: 4, overflow: TextOverflow.ellipsis),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(_noteTitle(context, entry.note),
                maxLines: 2, overflow: TextOverflow.ellipsis),
          ),
          trailing: Tooltip(
              message: S.of(context).Today_Open_Note,
              child: const Icon(Icons.chevron_right_rounded)),
          onTap: onOpen,
        ),
      );
}

String _noteTitle(BuildContext context, Note note) =>
    note.title?.trim().isNotEmpty == true
        ? note.title!.trim()
        : S.of(context).Note_Untitled;
