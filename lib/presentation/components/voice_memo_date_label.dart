import 'package:flutter/material.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/services/note_dates.dart';

/// Stored recording metadata, formatted without opening or resolving media.
class VoiceMemoDateLabel extends StatelessWidget {
  const VoiceMemoDateLabel({super.key, required this.createdAt, this.style});

  final DateTime createdAt;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) => Text(
        S.of(context).Voice_Recorded_At(noteReaderDateTimeLabel(
              dateTime: createdAt,
              locale: Localizations.localeOf(context).toString(),
              use24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
            )),
        style: style,
      );
}
