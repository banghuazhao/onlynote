import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:onlynote/Tools/reminder.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/paper_note.dart';
import 'package:onlynote/presentation/theme/theme.dart';
import 'package:onlynote/services/today_agenda.dart';

import 'today_agenda_content.dart';

@Preview(name: 'Today, 390', group: 'Today', size: Size(390, 844))
Widget todayPreview() => const _TodayPreview();

@Preview(
    name: 'Today, dark 760',
    group: 'Today',
    size: Size(760, 844),
    brightness: Brightness.dark)
Widget todayDarkPreview() => const _TodayPreview(dark: true);

@Preview(name: 'Today, large Chinese 320', group: 'Today', size: Size(320, 640))
Widget todayLargeChinesePreview() =>
    const _TodayPreview(chinese: true, textScale: 2);

@Preview(name: 'Today, empty', group: 'Today', size: Size(390, 740))
Widget todayEmptyPreview() => const _TodayPreview(empty: true);

class _TodayPreview extends StatefulWidget {
  const _TodayPreview(
      {this.dark = false,
      this.chinese = false,
      this.textScale = 1,
      this.empty = false});
  final bool dark;
  final bool chinese;
  final double textScale;
  final bool empty;

  @override
  State<_TodayPreview> createState() => _TodayPreviewState();
}

class _TodayPreviewState extends State<_TodayPreview> {
  final _now = DateTime(2026, 10, 29, 10);
  late List<Note> _notes = widget.empty
      ? []
      : [
          Note(
              id: 'daily',
              title: 'A little room for today',
              dailyNoteDateKey: '2026-10-29',
              description: 'Finish the draft, then take a walk.'),
          Note(id: 'work', title: 'Website refresh', todo: [
            Todo(id: 'draft', title: 'Review the first draft'),
            Todo(id: 'photos', title: 'Choose three photos for the homepage'),
          ]),
          Note(id: 'home', title: 'Things for home', todo: [
            Todo(id: 'plants', title: 'Water the plants'),
          ]),
        ];

  void _complete(TodayTaskEntry entry) => setState(() {
        _notes = [
          for (final note in _notes)
            if (note.id == entry.note.id)
              note.copyWith(todo: [
                for (final todo in note.todo)
                  if (todo.id == entry.todo.id)
                    todo.copyWith(completed: true)
                  else
                    todo,
              ])
            else
              note,
        ];
      });

  void _openDaily() => setState(() {
        if (!_notes.any((note) => note.id == 'daily')) {
          _notes = [
            ..._notes,
            Note(
                id: 'daily',
                title: 'A little room for today',
                dailyNoteDateKey: '2026-10-29')
          ];
        }
      });

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: widget.dark ? AppTheme.dark : AppTheme.light,
        locale: widget.chinese ? const Locale('zh', 'HK') : const Locale('en'),
        supportedLocales: S.delegate.supportedLocales,
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(widget.textScale),
              disableAnimations: true),
          child: child!,
        ),
        home: Builder(
            builder: (context) => Scaffold(
                  backgroundColor: DeskSurface.colorOf(context),
                  appBar: AppBar(title: Text(S.of(context).Today_Title)),
                  body: DeskSurface(
                      child: TodayAgendaContent(
                    agenda: buildTodayAgenda(
                      notes: _notes,
                      reminders: widget.empty
                          ? []
                          : [
                              Reminder(
                                  noteId: 'work',
                                  reminderId: 1,
                                  reminderDate: DateTime(2026, 10, 28, 17)),
                              Reminder(
                                  noteId: 'home',
                                  reminderId: 2,
                                  reminderDate: DateTime(2026, 10, 29, 18)),
                            ],
                      now: _now,
                    ),
                    now: _now,
                    onOpenDailyNote: _openDaily,
                    onOpenNote: (id) => ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(
                            content: Text(_notes
                                    .firstWhere((note) => note.id == id)
                                    .title ??
                                ''))),
                    onOpenReminders: () {},
                    onCompleteTask: _complete,
                  )),
                )),
      );
}
