import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:onlynote/services/note_dates.dart';

void main() {
  setUpAll(() => initializeDateFormatting());

  test('reader dates respect locale and the device clock preference', () {
    final date = DateTime(2026, 10, 11, 17, 45);
    for (final (locale, localeDefault, twentyFourHour) in [
      ('en', 'Oct 11, 2026 5:45 PM', 'Oct 11, 2026 17:45'),
      ('zh', '2026年10月11日 17:45', '2026年10月11日 17:45'),
      ('zh_HK', '2026年10月11日 下午5:45', '2026年10月11日 17:45'),
    ]) {
      expect(
        noteReaderDateTimeLabel(
            dateTime: date, locale: locale, use24HourFormat: false),
        localeDefault,
      );
      expect(
        noteReaderDateTimeLabel(
            dateTime: date, locale: locale, use24HourFormat: true),
        twentyFourHour,
      );
    }
  });

  test('reader timestamps convert UTC metadata without changing the date', () {
    final date = DateTime.utc(2026, 10, 11, 23, 45);
    for (final locale in ['en', 'zh', 'zh_HK']) {
      for (final use24HourFormat in [false, true]) {
        final expected = DateFormat.yMMMd(locale);
        if (use24HourFormat) {
          expected.add_Hm();
        } else {
          expected.add_jm();
        }
        expect(
          noteReaderDateTimeLabel(
              dateTime: date, locale: locale, use24HourFormat: use24HourFormat),
          expected.format(date.toLocal()),
        );
      }
    }
    expect(date, DateTime.utc(2026, 10, 11, 23, 45));
    expect(date.isUtc, isTrue);
  });

  test('missing reader timestamps stay empty for all supported locales', () {
    for (final locale in ['en', 'zh', 'zh_HK']) {
      for (final use24HourFormat in [false, true]) {
        expect(
          noteReaderDateTimeLabel(
              dateTime: null, locale: locale, use24HourFormat: use24HourFormat),
          isEmpty,
        );
      }
    }
  });

  test('Trash cards label deletion date instead of the ordinary note date', () {
    final ordinary = DateTime(2020, 1, 2);
    final deleted = DateTime(2026, 10, 11, 14, 30);
    expect(
      noteCardDateLabel(
        locale: 'en',
        showDate: true,
        movedToTrashLabel: (date) => 'Moved to Trash on $date',
        dateTime: ordinary,
        deletedAt: deleted,
      ),
      'Moved to Trash on Oct 11, 2026',
    );
    expect(ordinary, DateTime(2020, 1, 2));
    expect(deleted, DateTime(2026, 10, 11, 14, 30));
  });

  test('active and restored notes preserve ordinary date formatting', () {
    final date = DateTime.utc(2026, 10, 11, 23, 30);
    var trashLabels = 0;
    expect(
      noteCardDateLabel(
        locale: 'en',
        showDate: true,
        movedToTrashLabel: (date) {
          trashLabels++;
          return date;
        },
        dateTime: date,
      ),
      'Oct 11, 2026',
    );
    expect(trashLabels, 0);
  });

  test('hidden dates and absent metadata never invent a deletion date', () {
    var trashLabels = 0;
    String label(String date) {
      trashLabels++;
      return date;
    }

    expect(
      noteCardDateLabel(
        locale: 'en',
        showDate: false,
        movedToTrashLabel: label,
        dateTime: DateTime(2020, 1, 2),
        deletedAt: DateTime(2026, 10, 11),
      ),
      isNull,
    );
    expect(
      noteCardDateLabel(
        locale: 'en',
        showDate: true,
        movedToTrashLabel: label,
      ),
      isNull,
    );
    expect(trashLabels, 0);
  });

  test('deleted timestamps are displayed in the local calendar and locale', () {
    final deleted = DateTime.utc(2026, 10, 11, 23, 30);
    for (final locale in ['en', 'zh', 'zh_HK']) {
      final local = deleted.toLocal();
      expect(
        noteCardDateLabel(
          locale: locale,
          showDate: true,
          movedToTrashLabel: (date) => 'Trash: $date',
          deletedAt: deleted,
        ),
        'Trash: ${DateFormat.yMMMd(locale).format(local)}',
      );
      expect(noteTrashDateTimeLabel(deleted, locale),
          DateFormat.yMMMd(locale).add_jm().format(local));
    }
    expect(deleted.isUtc, isTrue);
  });
}
