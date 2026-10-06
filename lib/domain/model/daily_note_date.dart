/// A stable association with a local calendar day, independent of note titles.
String dailyNoteDateKey(DateTime date) {
  final local = date.toLocal();
  return '${local.year.toString().padLeft(4, '0')}-'
      '${local.month.toString().padLeft(2, '0')}-'
      '${local.day.toString().padLeft(2, '0')}';
}

bool isValidDailyNoteDateKey(Object? value) {
  if (value is! String || !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) {
    return false;
  }
  final date = DateTime.tryParse(value);
  return date != null && date.year > 0 && dailyNoteDateKey(date) == value;
}
