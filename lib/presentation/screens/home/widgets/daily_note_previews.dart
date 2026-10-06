import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/note_search_filters.dart';
import 'package:onlynote/presentation/theme/theme.dart';

import 'daily_note_shortcut.dart';

void previewOpenDailyNote() {}
void previewOpenDailyCalendar() {}
void previewFilterDailyNotes(bool _) {}
void previewDailyNoteAction() {}

@Preview(name: 'Today and library shortcuts', size: Size(320, 110))
@Preview(
    name: 'Today and library shortcuts, dark',
    size: Size(390, 110),
    brightness: Brightness.dark)
Widget dailyNoteShortcutsPreview() => MaterialApp(
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      localizationsDelegates: const [S.delegate],
      home: Scaffold(
        body: UnfinishedNotesFilter(
          leadingAction: const DailyNoteShortcut(
              onPressed: previewOpenDailyNote,
              onOpenCalendar: previewOpenDailyCalendar),
          selected: false,
          onChanged: previewFilterDailyNotes,
          onOpenReminders: previewDailyNoteAction,
          onOpenLibrary: previewDailyNoteAction,
        ),
      ),
    );
