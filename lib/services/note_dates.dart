import 'package:intl/intl.dart';

/// The reader shows the stored timestamp in the local calendar, using the app's
/// locale and device clock preference. As with Flutter's clock formatting,
/// false retains the locale's default and true requests a 24-hour clock.
/// Missing metadata stays empty.
String noteReaderDateTimeLabel({
  required DateTime? dateTime,
  required String locale,
  required bool use24HourFormat,
}) {
  if (dateTime == null) return '';
  final format = DateFormat.yMMMd(locale);
  if (use24HourFormat) {
    format.add_Hm();
  } else {
    format.add_jm();
  }
  return format.format(dateTime.toLocal());
}

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
