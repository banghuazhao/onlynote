import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:onlynote/domain/model/daily_note_date.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/services/daily_note_calendar.dart';

import 'app_sheet.dart';

/// Browses saved daily notes. Empty dates are informational; the explicit
/// Today's note action is the only action that can create a note.
class DailyNoteCalendarSheet extends StatefulWidget {
  const DailyNoteCalendarSheet({
    super.key,
    required this.notes,
    required this.onOpenDay,
    required this.onOpenToday,
    this.today,
  });

  final List<Note> notes;
  final ValueChanged<DateTime> onOpenDay;
  final VoidCallback onOpenToday;
  final DateTime? today;

  @override
  State<DailyNoteCalendarSheet> createState() => _DailyNoteCalendarSheetState();
}

class _DailyNoteCalendarSheetState extends State<DailyNoteCalendarSheet> {
  late DateTime _month;
  late DateTime _selectedDay;

  DateTime get _today => _day(widget.today ?? DateTime.now());
  String get _locale => Localizations.localeOf(context).toString();

  @override
  void initState() {
    super.initState();
    _selectedDay = _today;
    _month = DateTime(_selectedDay.year, _selectedDay.month);
  }

  static DateTime _day(DateTime value) {
    final local = value.toLocal();
    return DateTime(local.year, local.month, local.day);
  }

  void _showMonth(int offset) {
    setState(() {
      _month = DateTime(_month.year, _month.month + offset);
      final lastDay = DateTime(_month.year, _month.month + 1, 0).day;
      _selectedDay = DateTime(
          _month.year, _month.month, math.min(_selectedDay.day, lastDay));
    });
  }

  void _showToday() => setState(() {
        _selectedDay = _today;
        _month = DateTime(_selectedDay.year, _selectedDay.month);
      });

  Future<void> _chooseMonth() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _selectedDay,
      currentDate: _today,
      firstDate: DateTime(1),
      lastDate: DateTime(9999, 12, 31),
      helpText: S.of(context).Daily_Note_Calendar_Choose_Month,
    );
    if (selected == null || !mounted) return;
    setState(() {
      _selectedDay = _day(selected);
      _month = DateTime(selected.year, selected.month);
    });
  }

  void _selectDay(DateTime day, DailyNoteCalendarIndex index) {
    setState(() => _selectedDay = day);
    if (index.noteForDay(day) != null) widget.onOpenDay(day);
  }

  void _showSavedDay(DateTime day) => setState(() {
        _selectedDay = day;
        _month = DateTime(day.year, day.month);
      });

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final theme = Theme.of(context);
    final index = DailyNoteCalendarIndex.fromNotes(widget.notes);
    final previousSavedDay = index.previousSavedDay(_selectedDay);
    final nextSavedDay = index.nextSavedDay(_selectedDay);
    return AppSheet(
      title: s.Daily_Note_Calendar,
      footer: FilledButton.icon(
        key: const ValueKey('daily-calendar-open-today'),
        onPressed: widget.onOpenToday,
        icon: const Icon(Icons.edit_calendar_outlined),
        label: Text(s.Today_Note, textAlign: TextAlign.center),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(children: [
              IconButton(
                key: const ValueKey('daily-calendar-previous-month'),
                tooltip: s.Daily_Note_Calendar_Previous_Month,
                onPressed: _month.year == 1 && _month.month == 1
                    ? null
                    : () => _showMonth(-1),
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              Expanded(
                child: Tooltip(
                  message: s.Daily_Note_Calendar_Choose_Month,
                  child: TextButton(
                    key: const ValueKey('daily-calendar-choose-month'),
                    onPressed: _chooseMonth,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: const Size(48, 48),
                    ),
                    child: Row(children: [
                      Expanded(
                        child: Text(
                          DateFormat.yMMMM(_locale).format(_month),
                          key: const ValueKey('daily-calendar-month'),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium,
                        ),
                      ),
                      const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
                    ]),
                  ),
                ),
              ),
              IconButton(
                key: const ValueKey('daily-calendar-next-month'),
                tooltip: s.Daily_Note_Calendar_Next_Month,
                onPressed: _month.year == 9999 && _month.month == 12
                    ? null
                    : () => _showMonth(1),
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ]),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton(
                key: const ValueKey('daily-calendar-show-today'),
                onPressed: _showToday,
                child: Text(s.Daily_Note_Calendar_Today),
              ),
            ),
            _buildMonth(context, index),
            const SizedBox(height: 16),
            LayoutBuilder(builder: (context, constraints) {
              final buttonWidth = constraints.maxWidth >= 520
                  ? (constraints.maxWidth - 8) / 2
                  : constraints.maxWidth;
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  SizedBox(
                    width: buttonWidth,
                    child: OutlinedButton.icon(
                      key: const ValueKey('daily-calendar-previous-saved'),
                      onPressed: previousSavedDay == null
                          ? null
                          : () => _showSavedDay(previousSavedDay),
                      icon: const Icon(Icons.skip_previous_rounded),
                      label: Text(s.Daily_Note_Calendar_Previous_Saved,
                          textAlign: TextAlign.center),
                    ),
                  ),
                  SizedBox(
                    width: buttonWidth,
                    child: OutlinedButton.icon(
                      key: const ValueKey('daily-calendar-next-saved'),
                      onPressed: nextSavedDay == null
                          ? null
                          : () => _showSavedDay(nextSavedDay),
                      icon: const Icon(Icons.skip_next_rounded),
                      label: Text(s.Daily_Note_Calendar_Next_Saved,
                          textAlign: TextAlign.center),
                    ),
                  ),
                ],
              );
            }),
            const SizedBox(height: 8),
            Text(
              s.Daily_Note_Calendar_Saved_Navigation_Hint,
              key: const ValueKey('daily-calendar-saved-navigation-hint'),
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            _SelectedDayPreview(
              date: _selectedDay,
              note: index.noteForDay(_selectedDay),
              onOpen: () => widget.onOpenDay(_selectedDay),
              locale: _locale,
            ),
            if (index.notesByDay.isEmpty) ...[
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  s.Daily_Note_Calendar_Empty,
                  key: const ValueKey('daily-calendar-empty'),
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMonth(BuildContext context, DailyNoteCalendarIndex index) {
    final localizations = MaterialLocalizations.of(context);
    final start = localizations.firstDayOfWeekIndex;
    final leading = (_month.weekday % 7 - start + 7) % 7;
    final days = DateTime(_month.year, _month.month + 1, 0).day;
    final rows = ((leading + days) / 7).ceil();
    final scaler = MediaQuery.textScalerOf(context);
    final rowHeight = math.max(48.0, scaler.scale(16) * 1.3 + 22);
    return LayoutBuilder(builder: (context, constraints) {
      final width = constraints.maxWidth / 7;
      return Column(
        key: const ValueKey('daily-calendar-grid'),
        children: [
          Row(children: [
            for (var weekday = 0; weekday < 7; weekday++)
              SizedBox(
                width: width,
                height: math.max(32, scaler.scale(12) * 1.4 + 8),
                child: Center(
                  child: Text(
                    localizations.narrowWeekdays[(start + weekday) % 7],
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                    maxLines: 1,
                  ),
                ),
              ),
          ]),
          for (var row = 0; row < rows; row++)
            Row(children: [
              for (var column = 0; column < 7; column++)
                SizedBox(
                  width: width,
                  height: rowHeight,
                  child: row * 7 + column - leading + 1 < 1 ||
                          row * 7 + column - leading + 1 > days
                      ? null
                      : _CalendarDay(
                          day: DateTime(_month.year, _month.month,
                              row * 7 + column - leading + 1),
                          today: _today,
                          selectedDay: _selectedDay,
                          hasNote: index.noteForDay(DateTime(
                                  _month.year,
                                  _month.month,
                                  row * 7 + column - leading + 1)) !=
                              null,
                          locale: _locale,
                          onPressed: (day) => _selectDay(day, index),
                        ),
                ),
            ]),
        ],
      );
    });
  }
}

class _CalendarDay extends StatelessWidget {
  const _CalendarDay({
    required this.day,
    required this.today,
    required this.selectedDay,
    required this.hasNote,
    required this.locale,
    required this.onPressed,
  });

  final DateTime day;
  final DateTime today;
  final DateTime selectedDay;
  final bool hasNote;
  final String locale;
  final ValueChanged<DateTime> onPressed;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isToday = day == today;
    final selected = day == selectedDay;
    final foreground = selected ? colors.onPrimaryContainer : colors.onSurface;
    final label = [
      DateFormat.yMMMMEEEEd(locale).format(day),
      if (isToday) s.Daily_Note_Calendar_Today,
      hasNote ? s.Daily_Note_Calendar_Has_Note : s.Daily_Note_Calendar_No_Note,
    ].join(', ');
    return Semantics(
      key: ValueKey('daily-calendar-day-${dailyNoteDateKey(day)}'),
      button: true,
      selected: selected,
      label: label,
      onTap: () => onPressed(day),
      excludeSemantics: true,
      child: InkWell(
        onTap: () => onPressed(day),
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: selected ? colors.primaryContainer : null,
            borderRadius: BorderRadius.circular(12),
            border:
                isToday ? Border.all(color: colors.primary, width: 1.5) : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    MaterialLocalizations.of(context).formatDecimal(day.day),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 16,
                      fontWeight: hasNote || isToday
                          ? FontWeight.w700
                          : FontWeight.w400,
                      color: foreground,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              SizedBox.square(
                dimension: 5,
                child: hasNote
                    ? DecoratedBox(
                        key: ValueKey(
                            'daily-calendar-marker-${dailyNoteDateKey(day)}'),
                        decoration: BoxDecoration(
                            color: foreground, shape: BoxShape.circle),
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectedDayPreview extends StatelessWidget {
  const _SelectedDayPreview({
    required this.date,
    required this.note,
    required this.onOpen,
    required this.locale,
  });

  final DateTime date;
  final Note? note;
  final VoidCallback onOpen;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final theme = Theme.of(context);
    final saved = note;
    final title = saved?.title?.trim();
    final snippet = saved?.description?.trim().isNotEmpty == true
        ? saved!.description!.trim()
        : saved?.todo
                .map((todo) => todo.title?.trim() ?? '')
                .where((title) => title.isNotEmpty)
                .join(', ') ??
            '';
    return Card(
      key: const ValueKey('daily-calendar-selection'),
      child: InkWell(
        key: const ValueKey('daily-calendar-selected-note'),
        onTap: saved == null ? null : onOpen,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateFormat.yMMMMd(locale).format(date),
                key: const ValueKey('daily-calendar-selected-date'),
                style: theme.textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              if (saved == null)
                Text(
                  s.Daily_Note_Calendar_No_Note,
                  key: const ValueKey('daily-calendar-no-note'),
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                )
              else ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        title?.isNotEmpty == true
                            ? title!
                            : DateFormat.yMMMMd(locale).format(date),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.chevron_right_rounded),
                  ],
                ),
                if (snippet.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(snippet,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant)),
                ],
                if (saved.isArchived) ...[
                  const SizedBox(height: 8),
                  Text(s.Archive,
                      key: const ValueKey('daily-calendar-archived'),
                      style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant)),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}
