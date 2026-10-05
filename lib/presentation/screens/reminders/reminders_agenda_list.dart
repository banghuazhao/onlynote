import 'package:flutter/material.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/reminder_labels.dart';
import 'package:onlynote/services/reminder_agenda.dart';

/// Agenda content without storage, notification plugins, or navigation. Used
/// by the live screen, widget previews, and interaction tests.
class RemindersAgendaList extends StatelessWidget {
  const RemindersAgendaList({
    super.key,
    required this.entries,
    required this.now,
    required this.onOpen,
    required this.onSnooze,
    required this.onReschedule,
    this.busyReminderId,
    this.onRefresh,
  });

  final List<ReminderAgendaEntry> entries;
  final DateTime now;
  final int? busyReminderId;
  final ValueChanged<ReminderAgendaEntry> onOpen;
  final ValueChanged<ReminderAgendaEntry> onSnooze;
  final ValueChanged<ReminderAgendaEntry> onReschedule;
  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context) {
    final sections = {
      for (final group in ReminderAgendaGroup.values)
        group: entries.where((entry) => entry.groupAt(now) == group).toList(),
    };
    final rows = <Object>[
      for (final group in ReminderAgendaGroup.values)
        if (sections[group]!.isNotEmpty) ...[group, ...sections[group]!],
    ];
    final list = ListView.builder(
      key: const Key('reminders-agenda-list'),
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      itemCount: rows.isEmpty ? 1 : rows.length,
      itemBuilder: (context, index) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: rows.isEmpty
              ? const _AgendaEmptyState()
              : switch (rows[index]) {
                  final ReminderAgendaGroup group => _AgendaSectionHeader(
                      group: group, count: sections[group]!.length),
                  final ReminderAgendaEntry entry => _ReminderAgendaCard(
                      entry: entry,
                      now: now,
                      busy: busyReminderId == entry.reminder.reminderId,
                      actionsEnabled: busyReminderId == null,
                      onOpen: () => onOpen(entry),
                      onSnooze: () => onSnooze(entry),
                      onReschedule: () => onReschedule(entry),
                    ),
                  _ => const SizedBox.shrink(),
                },
        ),
      ),
    );
    return onRefresh == null
        ? list
        : RefreshIndicator(onRefresh: onRefresh!, child: list);
  }
}

class _AgendaEmptyState extends StatelessWidget {
  const _AgendaEmptyState();

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 72),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.event_available_outlined,
              size: 48, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(height: 20),
          Text(l10n.Reminders_Empty_Title,
              textAlign: TextAlign.center, style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(l10n.Reminders_Empty_Message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _AgendaSectionHeader extends StatelessWidget {
  const _AgendaSectionHeader({required this.group, required this.count});
  final ReminderAgendaGroup group;
  final int count;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final theme = Theme.of(context);
    final label = switch (group) {
      ReminderAgendaGroup.overdue => l10n.Reminders_Overdue,
      ReminderAgendaGroup.today => l10n.Reminders_Today,
      ReminderAgendaGroup.upcoming => l10n.Reminders_Upcoming,
    };
    final foreground = group == ReminderAgendaGroup.overdue
        ? theme.colorScheme.error
        : theme.colorScheme.onSurface;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 20, 4, 10),
      child: Semantics(
        header: true,
        child: Row(children: [
          Expanded(
            child: Text(label,
                style:
                    theme.textTheme.titleMedium?.copyWith(color: foreground)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(20)),
            child: Text('$count',
                style: theme.textTheme.labelMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ),
        ]),
      ),
    );
  }
}

class _ReminderAgendaCard extends StatelessWidget {
  const _ReminderAgendaCard({
    required this.entry,
    required this.now,
    required this.busy,
    required this.actionsEnabled,
    required this.onOpen,
    required this.onSnooze,
    required this.onReschedule,
  });

  final ReminderAgendaEntry entry;
  final DateTime now;
  final bool busy;
  final bool actionsEnabled;
  final VoidCallback onOpen;
  final VoidCallback onSnooze;
  final VoidCallback onReschedule;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = S.of(context);
    final overdue = entry.groupAt(now) == ReminderAgendaGroup.overdue;
    final title = entry.note.title?.trim();
    final description = entry.note.description?.trim();
    final fallback = entry.note.todo
        .map((todo) => todo.title?.trim() ?? '')
        .where((title) => title.isNotEmpty);
    final noteLabel = title?.isNotEmpty == true
        ? title!
        : description?.isNotEmpty == true
            ? description!
            : fallback.isNotEmpty
                ? fallback.first
                : l10n.Reminder;
    final metadataColor =
        overdue ? theme.colorScheme.error : theme.colorScheme.onSurfaceVariant;
    return Card(
      key: ValueKey('reminder-${entry.reminder.reminderId}'),
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            key: ValueKey('open-reminder-${entry.reminder.reminderId}'),
            onTap: actionsEnabled ? onOpen : null,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 12, 12),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color:
                        entry.note.color ?? theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                      entry.note.hasTodo
                          ? Icons.checklist_rounded
                          : Icons.sticky_note_2_outlined,
                      color: entry.note.color == null
                          ? theme.colorScheme.onPrimaryContainer
                          : ThemeData.estimateBrightnessForColor(
                                      entry.note.color!) ==
                                  Brightness.dark
                              ? Colors.white
                              : Colors.black87,
                      size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(noteLabel,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium),
                ),
                const SizedBox(width: 4),
                Icon(Icons.chevron_right_rounded,
                    color: theme.colorScheme.onSurfaceVariant),
              ]),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(formatReminderTime(context, entry.dueDate),
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: metadataColor)),
                if (entry.reminder.isRepeating || entry.snoozed) ...[
                  const SizedBox(height: 6),
                  Wrap(spacing: 12, runSpacing: 6, children: [
                    if (entry.reminder.isRepeating)
                      _ReminderMetadata(
                        icon: Icons.repeat_rounded,
                        label:
                            reminderRepeatLabel(context, entry.reminder.repeat),
                      ),
                    if (entry.snoozed)
                      _ReminderMetadata(
                          icon: Icons.snooze_rounded,
                          label: l10n.Reminders_Snoozed),
                  ]),
                ],
              ],
            ),
          ),
          Divider(height: 1, color: theme.colorScheme.outlineVariant),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
            child: Wrap(spacing: 8, runSpacing: 4, children: [
              if (entry.groupAt(now) != ReminderAgendaGroup.upcoming)
                TextButton.icon(
                  key: ValueKey('snooze-reminder-${entry.reminder.reminderId}'),
                  onPressed: actionsEnabled ? onSnooze : null,
                  icon: const Icon(Icons.snooze_rounded, size: 19),
                  label: Text(l10n.Reminders_Snooze),
                ),
              TextButton.icon(
                key: ValueKey(
                    'reschedule-reminder-${entry.reminder.reminderId}'),
                onPressed: actionsEnabled ? onReschedule : null,
                icon: busy
                    ? Semantics(
                        liveRegion: true,
                        label: l10n.Saving,
                        child: SizedBox.square(
                          dimension: 18,
                          child: MediaQuery.disableAnimationsOf(context)
                              ? const Icon(Icons.hourglass_top_rounded,
                                  size: 18)
                              : const CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : const Icon(Icons.edit_calendar_outlined, size: 19),
                label: Text(l10n.Reminders_Reschedule),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}

class _ReminderMetadata extends StatelessWidget {
  const _ReminderMetadata({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.onSurfaceVariant;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 16, color: color),
      const SizedBox(width: 5),
      Flexible(
        child: Text(label,
            style: theme.textTheme.labelMedium?.copyWith(color: color)),
      ),
    ]);
  }
}
