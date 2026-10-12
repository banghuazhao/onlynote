import 'package:intl/intl.dart';

/// A Trash card labels its stored deletion date. Ordinary card dates retain
/// their existing formatting, and hidden or missing dates stay absent.
String? noteCardDateLabel({
  required String locale,
  required bool showDate,
  required String Function(String date) movedToTrashLabel,
  DateTime? dateTime,
  DateTime? deletedAt,
}) {
  if (!showDate) return null;
  final format = DateFormat.yMMMd(locale);
  if (deletedAt != null) {
    return movedToTrashLabel(format.format(deletedAt.toLocal()));
  }
  return dateTime == null ? null : format.format(dateTime);
}

/// The full stored deletion timestamp for the read-only note summary.
String noteTrashDateTimeLabel(DateTime deletedAt, String locale) =>
    DateFormat.yMMMd(locale).add_jm().format(deletedAt.toLocal());
