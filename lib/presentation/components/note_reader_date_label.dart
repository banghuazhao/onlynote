import 'package:flutter/material.dart';
import 'package:onlynote/services/note_dates.dart';

/// A reader timestamp that updates with the app locale and device clock.
class NoteReaderDateLabel extends StatelessWidget {
  const NoteReaderDateLabel({super.key, required this.dateTime, this.style});

  final DateTime? dateTime;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) => SelectableText(
        noteReaderDateTimeLabel(
          dateTime: dateTime,
          locale: Localizations.localeOf(context).toString(),
          use24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
        ),
        style: style,
      );
}
