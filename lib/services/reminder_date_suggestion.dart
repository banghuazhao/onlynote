/// A local, deterministic hint. The editor keeps the source text unchanged and
/// asks the user to confirm this wall-clock date before setting a reminder.
class ReminderDateSuggestion {
  const ReminderDateSuggestion({required this.date, required this.phrase});

  final DateTime date;
  final String phrase;

  /// Relative dates move as time passes; dismissing the phrase should remain
  /// effective while the user continues editing the same sentence.
  String get key => phrase.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
}

/// Recognizes a deliberately small set of English and Chinese date phrases.
/// Multiple different dates, invalid calendar values, and bare numbers are
/// ignored instead of guessing which one represents the user's intention.
ReminderDateSuggestion? suggestReminderDate(String text,
    {required DateTime now}) {
  final localNow = now.toLocal();
  final candidates = <ReminderDateSuggestion>[];
  final occupied = <(int, int)>[];
  // Bound work while typing a long note. Each line is parsed separately so a
  // time on a different checklist item cannot attach to the preceding date.
  final bounded = text.length > 12000 ? text.substring(0, 12000) : text;
  final source = bounded.replaceAllMapped(
      RegExp(r'(?:https?://|www\.)\S+', caseSensitive: false),
      (match) => ' ' * match.group(0)!.length);
  var offset = 0;
  for (final line in source.split('\n')) {
    void add(RegExpMatch match, DateTime? date, {int? end}) {
      final finish = end ?? match.end;
      if (occupied.any((range) =>
          offset + match.start < range.$2 && offset + finish > range.$1)) {
        return;
      }
      occupied.add((offset + match.start, offset + finish));
      if (date != null && date.isAfter(localNow)) {
        candidates.add(ReminderDateSuggestion(
            date: date, phrase: line.substring(match.start, finish)));
      } else {
        // An explicitly invalid/past date makes the whole hint ambiguous.
        candidates.add(ReminderDateSuggestion(
            date: localNow, phrase: line.substring(match.start, finish)));
      }
    }

    final relative = RegExp(
        r'\bin\s+([1-9]\d{0,3})\s+(minutes?|hours?|days?)\b',
        caseSensitive: false);
    for (final match in relative.allMatches(line)) {
      final count = int.parse(match.group(1)!);
      final unit = match.group(2)!.toLowerCase();
      DateTime? date;
      if (unit.startsWith('minute') && count <= 10080) {
        date = localNow.add(Duration(minutes: count));
      } else if (unit.startsWith('hour') && count <= 8760) {
        date = localNow.add(Duration(hours: count));
      } else if (unit.startsWith('day') && count <= 365) {
        date = DateTime(localNow.year, localNow.month, localNow.day + count,
            localNow.hour, localNow.minute);
      }
      add(match, date);
    }
    final chineseRelative =
        RegExp(r'([1-9]\d{0,3})\s*(分钟|分鐘|小时|小時|天)\s*(?:后|後)');
    for (final match in chineseRelative.allMatches(line)) {
      // A count embedded in a longer number is never interpreted partially.
      if (match.start > 0 &&
          RegExp(r'[\d.+-]').hasMatch(line[match.start - 1])) {
        continue;
      }
      final count = int.parse(match.group(1)!);
      final unit = match.group(2)!;
      DateTime? date;
      if ((unit == '分钟' || unit == '分鐘') && count <= 10080) {
        date = localNow.add(Duration(minutes: count));
      } else if ((unit == '小时' || unit == '小時') && count <= 8760) {
        date = localNow.add(Duration(hours: count));
      } else if (unit == '天' && count <= 365) {
        date = DateTime(localNow.year, localNow.month, localNow.day + count,
            localNow.hour, localNow.minute);
      }
      add(match, date);
    }

    // Year-first dates avoid the US/UK ambiguity of 10/11/2026.
    final explicit = RegExp(
        r'(?<!\d)(\d{4})(?:[-/](\d{1,2})[-/](\d{1,2})|年\s*(\d{1,2})月\s*(\d{1,2})(?:日|号|號))(?!\d)');
    for (final match in explicit.allMatches(line)) {
      final year = int.parse(match.group(1)!);
      final month = int.parse(match.group(2) ?? match.group(4)!);
      final day = int.parse(match.group(3) ?? match.group(5)!);
      final time = _readTime(line.substring(match.end));
      final defaultTime = _defaultTime(year, month, day, localNow);
      final date = time.invalid || year > localNow.year + 100
          ? null
          : _checkedDate(year, month, day, time.hour ?? defaultTime.$1,
              time.minute ?? defaultTime.$2);
      add(match, date, end: match.end + time.length);
    }

    final days =
        RegExp(r'\b(today|tomorrow)\b|今天|今日|明天|明日', caseSensitive: false);
    for (final match in days.allMatches(line)) {
      final tomorrow =
          ['tomorrow', '明天', '明日'].contains(match.group(0)!.toLowerCase());
      final day = DateTime(
          localNow.year, localNow.month, localNow.day + (tomorrow ? 1 : 0));
      final time = _readTime(line.substring(match.end));
      final defaultTime = _defaultTime(day.year, day.month, day.day, localNow);
      final date = time.invalid
          ? null
          : _checkedDate(day.year, day.month, day.day,
              time.hour ?? defaultTime.$1, time.minute ?? defaultTime.$2);
      add(match, date, end: match.end + time.length);
    }

    final weekdays = RegExp(
        r'\b(?:(next)\s+)?(monday|tuesday|wednesday|thursday|friday|saturday|sunday)\b|((?:下|本|这|這)?(?:周|週|星期|礼拜|禮拜))([一二三四五六日天])',
        caseSensitive: false);
    const englishDays = [
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday',
      'sunday'
    ];
    for (final match in weekdays.allMatches(line)) {
      final weekday = match.group(2) != null
          ? englishDays.indexOf(match.group(2)!.toLowerCase()) + 1
          : '一二三四五六日'.indexOf(match.group(4) == '天' ? '日' : match.group(4)!) +
              1;
      final nextWeek =
          match.group(1) != null || (match.group(3)?.startsWith('下') ?? false);
      final thisWeek = RegExp(r'^[本这這]').hasMatch(match.group(3) ?? '');
      var offsetDays = nextWeek
          ? 7 - localNow.weekday + weekday
          : thisWeek
              ? weekday - localNow.weekday
              : (weekday - localNow.weekday + 7) % 7;
      final time = _readTime(line.substring(match.end));
      var day =
          DateTime(localNow.year, localNow.month, localNow.day + offsetDays);
      var date = time.invalid
          ? null
          : _checkedDate(
              day.year, day.month, day.day, time.hour ?? 9, time.minute ?? 0);
      if (!nextWeek && !thisWeek && date != null && !date.isAfter(localNow)) {
        offsetDays += 7;
        day =
            DateTime(localNow.year, localNow.month, localNow.day + offsetDays);
        date = _checkedDate(
            day.year, day.month, day.day, time.hour ?? 9, time.minute ?? 0);
      }
      add(match, date, end: match.end + time.length);
    }
    offset += line.length + 1;
  }
  if (candidates.isEmpty ||
      candidates.any((hint) => !hint.date.isAfter(localNow))) {
    return null;
  }
  final first = candidates.first;
  // Repeated mentions of the same minute are safe; competing deadlines are not.
  if (candidates.any((hint) =>
      hint.date.year != first.date.year ||
      hint.date.month != first.date.month ||
      hint.date.day != first.date.day ||
      hint.date.hour != first.date.hour ||
      hint.date.minute != first.date.minute)) {
    return null;
  }
  return first;
}

(int, int) _defaultTime(int year, int month, int day, DateTime now) {
  if (year == now.year &&
      month == now.month &&
      day == now.day &&
      now.hour >= 9) {
    return (now.hour + 1, 0);
  }
  return (9, 0);
}

DateTime? _checkedDate(int year, int month, int day, int hour, int minute) {
  if (year < 1900 || year > 2200 || hour < 0 || hour > 23 || minute > 59) {
    return null;
  }
  final date = DateTime(year, month, day, hour, minute);
  return date.year == year &&
          date.month == month &&
          date.day == day &&
          date.hour == hour &&
          date.minute == minute
      ? date
      : null;
}

class _ParsedTime {
  const _ParsedTime(
      {this.hour, this.minute, this.length = 0, this.invalid = false});
  final int? hour;
  final int? minute;
  final int length;
  final bool invalid;
}

_ParsedTime _readTime(String suffix) {
  // Require adjacency (optional "at"/punctuation); a later number elsewhere
  // in the sentence must never become this date's clock time.
  final english = RegExp(
          r'^\s*(?:[,，]\s*)?(?:at\s+)?(\d{1,2})(?::(\d{1,2}))?\s*(am|pm)?(?![\d:a-z点點时時])',
          caseSensitive: false)
      .firstMatch(suffix);
  if (english != null) {
    final hourValue = int.parse(english.group(1)!);
    final minute = int.parse(english.group(2) ?? '0');
    final period = english.group(3)?.toLowerCase();
    // "tomorrow 9" is ambiguous; 9am and 09:00 carry enough information.
    if (english.group(2) == null && period == null) {
      return _ParsedTime(length: english.end, invalid: true);
    }
    final hasTimeZone = RegExp(
            r'^\s*(?:UTC|GMT|PST|PDT|EST|EDT|CST|CDT|MST|MDT|CET|CEST|Z\b|[+-]\d{2}(?::?\d{2})?)',
            caseSensitive: false)
        .hasMatch(suffix.substring(english.end));
    final valid = !hasTimeZone &&
        minute <= 59 &&
        (period == null ? hourValue <= 23 : hourValue >= 1 && hourValue <= 12);
    final hour =
        period == null ? hourValue : hourValue % 12 + (period == 'pm' ? 12 : 0);
    return _ParsedTime(
        hour: hour, minute: minute, length: english.end, invalid: !valid);
  }
  final chinese = RegExp(
          r'^\s*(?:[,，]\s*)?(?:在\s*)?(凌晨|早上|上午|中午|下午|晚上|晚间|晚間)?\s*(\d{1,2})\s*(?:点|點|时|時)(?:(半)|(\d{1,2})\s*分?)?')
      .firstMatch(suffix);
  if (chinese != null) {
    var hour = int.parse(chinese.group(2)!);
    final minute =
        chinese.group(3) != null ? 30 : int.parse(chinese.group(4) ?? '0');
    final period = chinese.group(1);
    var invalid = hour > 23 || minute > 59;
    if (period != null) {
      invalid = invalid || hour < 1 || hour > 12;
      if (['下午', '晚上', '晚间', '晚間'].contains(period)) {
        hour = hour % 12 + 12;
      } else if (period == '中午') {
        invalid = invalid || hour < 11 || hour > 12;
      } else {
        hour %= 12;
      }
    }
    return _ParsedTime(
        hour: hour, minute: minute, length: chinese.end, invalid: invalid);
  }
  // Reject attempted but incomplete/invalid clock phrases while typing.
  if (RegExp(
          r'^\s*(?:[,，]\s*)?(?:at\b|by\b|afternoon\b|evening\b|night\b|noon\b|T\d|在|上午|下午|晚上|凌晨|早上|中午|\d+\s*[:点點时時])',
          caseSensitive: false)
      .hasMatch(suffix)) {
    return const _ParsedTime(invalid: true);
  }
  return const _ParsedTime();
}
