import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/services/reminder_date_suggestion.dart';

void main() {
  final now = DateTime(2026, 10, 6, 14, 25); // Tuesday.
  final patterns = <String, DateTime>{
    'Call Mum tomorrow at 9am': DateTime(2026, 10, 7, 9),
    'Meeting tomorrow at 2:30pm': DateTime(2026, 10, 7, 14, 30),
    'Submit today at 17:45': DateTime(2026, 10, 6, 17, 45),
    'Take medicine in 30 minutes': DateTime(2026, 10, 6, 14, 55),
    'Check the oven in 2 hours': DateTime(2026, 10, 6, 16, 25),
    'Follow up in 3 days': DateTime(2026, 10, 9, 14, 25),
    'Friday at 10am': DateTime(2026, 10, 9, 10),
    'next Friday at 10am': DateTime(2026, 10, 16, 10),
    'Tuesday at 10am': DateTime(2026, 10, 13, 10),
    '2026-10-20 at 14:30': DateTime(2026, 10, 20, 14, 30),
    '2026/10/20 9am': DateTime(2026, 10, 20, 9),
    '明天上午9点给妈妈打电话': DateTime(2026, 10, 7, 9),
    '明日下午2點30分開會': DateTime(2026, 10, 7, 14, 30),
    '今天下午5点完成': DateTime(2026, 10, 6, 17),
    '今日晚上8點半回家': DateTime(2026, 10, 6, 20, 30),
    '30分钟后检查': DateTime(2026, 10, 6, 14, 55),
    '2小時後覆查': DateTime(2026, 10, 6, 16, 25),
    '3天后跟进': DateTime(2026, 10, 9, 14, 25),
    '星期五上午10点': DateTime(2026, 10, 9, 10),
    '下週五下午2點': DateTime(2026, 10, 16, 14),
    '本周五下午2点': DateTime(2026, 10, 9, 14),
    '2026年10月20日下午2点30分': DateTime(2026, 10, 20, 14, 30),
    '2026年10月20號上午9點': DateTime(2026, 10, 20, 9),
    'tomorrow': DateTime(2026, 10, 7, 9),
    'today': DateTime(2026, 10, 6, 15),
  };
  for (final entry in patterns.entries) {
    test('recognizes ${entry.key}', () {
      final suggestion = suggestReminderDate(entry.key, now: now);
      expect(suggestion?.date, entry.value);
      expect(suggestion?.phrase, isNotEmpty);
    });
  }

  for (final text in [
    'Buy 9 apples and 20 bananas',
    'Version 2026.10.20 build 9',
    '10/11/2026 at 9am',
    'today at 9am',
    '2026-02-30 at 9am',
    '2026-13-01 at 9am',
    '2025-10-20 at 9am',
    'tomorrow at 25:00',
    'tomorrow at 9:99am',
    'tomorrow at 0am',
    'tomorrow at 9',
    'tomorrow at',
    'tomorrow by 5pm',
    'tomorrow afternoon',
    'tomorrow at 9am PST',
    '2026-10-20T09:00Z',
    '2026-10-20 14:30+10:00',
    '明天上午',
    '明天下午15点',
    '明天9点99分',
    '1.5小时后',
    '-2小时后',
    'in 0 minutes',
    'in 9000 days',
    'tomorrow at 9am and Friday at 5pm',
    '2026-10-20 to 2026-10-22',
    '本周一上午9点',
    'Read https://example.com/2026-10-20',
    'Download www.example.com/2026-10-20',
  ]) {
    test('ignores ambiguous or invalid text: $text', () {
      expect(suggestReminderDate(text, now: now), isNull);
    });
  }

  test('times do not cross checklist lines', () {
    final hint = suggestReminderDate('Tomorrow\nCollect 9 apples', now: now);
    expect(hint?.date, DateTime(2026, 10, 7, 9));
  });
  test('repeated identical dates produce one suggestion', () {
    final hint =
        suggestReminderDate('Tomorrow at 9am\n2026-10-07 at 09:00', now: now);
    expect(hint?.date, DateTime(2026, 10, 7, 9));
  });
  test('relative days preserve calendar time across month/year boundaries', () {
    final hint =
        suggestReminderDate('in 2 days', now: DateTime(2026, 12, 31, 10, 20));
    expect(hint?.date, DateTime(2027, 1, 2, 10, 20));
  });
  test('dismissal identity does not change when the relative clock advances',
      () {
    expect(
        suggestReminderDate('in 30 minutes', now: now)?.key,
        suggestReminderDate('in 30 minutes',
                now: now.add(const Duration(minutes: 1)))
            ?.key);
  });
}
