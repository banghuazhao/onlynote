import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:onlynote/Tools/reminder.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/domain/model/voice_memo.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/paper_note.dart';
import 'package:onlynote/presentation/theme/theme.dart';
import 'package:onlynote/services/reminder_agenda.dart';

import 'reminders_agenda_search.dart';

@Preview(
    name: 'Reminder search counts and snippets — light',
    group: 'Library',
    size: Size(390, 780))
Widget reminderSearchLightPreview({ThemeData? theme}) =>
    _ReminderSearchPreview(theme: theme);

@Preview(
  name: 'Reminder search counts and snippets — dark',
  group: 'Library',
  size: Size(390, 780),
  brightness: Brightness.dark,
)
Widget reminderSearchDarkPreview({ThemeData? theme}) =>
    _ReminderSearchPreview(dark: true, theme: theme);

@Preview(
  name: 'Reminder search counts and snippets — Chinese 2× narrow',
  group: 'Library',
  size: Size(320, 640),
)
Widget reminderSearchChinesePreview({ThemeData? theme}) =>
    _ReminderSearchPreview(chinese: true, textScale: 2, theme: theme);

class _ReminderSearchPreview extends StatelessWidget {
  const _ReminderSearchPreview({
    this.dark = false,
    this.chinese = false,
    this.textScale = 1,
    this.theme,
  });

  final bool dark;
  final bool chinese;
  final double textScale;
  final ThemeData? theme;

  @override
  Widget build(BuildContext context) {
    final now = DateTime(2026, 10, 20, 14);
    ReminderAgendaEntry entry(int id, Note note, DateTime due) =>
        ReminderAgendaEntry(
          note: note,
          reminder:
              Reminder(noteId: note.id!, reminderId: id, reminderDate: due),
          dueDate: due,
        );
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: chinese ? const Locale('zh', 'HK') : const Locale('en'),
      supportedLocales: S.delegate.supportedLocales,
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: theme ?? (dark ? AppTheme.dark : AppTheme.light),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale), disableAnimations: true),
        child: child!,
      ),
      home: Builder(
        builder: (context) => Scaffold(
          backgroundColor: DeskSurface.colorOf(context),
          appBar: AppBar(title: Text(S.of(context).Reminders_Title)),
          body: DeskSurface(
              child: SearchableRemindersAgenda(
            now: now,
            entries: [
              entry(
                  1,
                  Note(
                      id: 'dentist',
                      title: 'Call dentist',
                      description: 'Book a checkup for next month.',
                      tags: ['follow-up [2026]']),
                  now.subtract(const Duration(hours: 1))),
              entry(
                  2,
                  Note(
                      id: 'errands',
                      title: 'Errands',
                      description: 'Collect the receipt.',
                      voiceMemos: [
                        VoiceMemo(
                            id: 'follow-up',
                            path: 'note_audio/follow-up.m4a',
                            durationMs: 12000,
                            createdAt: now,
                            transcript:
                                'Ask about follow-up [2026] before the next appointment.'),
                      ]),
                  now.add(const Duration(hours: 2))),
              entry(3, Note(id: 'cjk', title: '閱讀清單', tags: ['茶😀']),
                  now.add(const Duration(days: 1))),
              entry(
                  4,
                  Note(id: 'checklist', todo: [
                    Todo(id: 'todo', title: 'Review C++ [2026] notes')
                  ], voiceMemos: [
                    VoiceMemo(
                        id: 'reading',
                        path: 'note_audio/reading.m4a',
                        durationMs: 12000,
                        createdAt: now,
                        transcript: '記得閱讀茶😀的筆記。'),
                  ]),
                  now.add(const Duration(days: 2))),
            ],
            onRefresh: reminderSearchPreviewRefresh,
            onOpen: reminderSearchPreviewAction,
            onSnooze: reminderSearchPreviewAction,
            onReschedule: reminderSearchPreviewAction,
          )),
        ),
      ),
    );
  }
}

void reminderSearchPreviewAction(ReminderAgendaEntry _) {}

Future<void> reminderSearchPreviewRefresh() async {}
