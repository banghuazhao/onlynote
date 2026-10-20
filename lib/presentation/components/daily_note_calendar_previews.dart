import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/theme/theme.dart';

import 'daily_note_calendar_sheet.dart';

void previewOpenDailyCalendarDay(DateTime _) {}
void previewOpenDailyCalendarToday() {}

@Preview(name: 'Daily note calendar — phone', size: Size(390, 844))
Widget dailyNoteCalendarPhonePreview() => _preview();

@Preview(name: 'Daily note calendar — narrow Chinese', size: Size(320, 760))
Widget dailyNoteCalendarChinesePreview() => _preview(chinese: true);

@Preview(name: 'Daily note calendar — narrow large text', size: Size(320, 760))
Widget dailyNoteCalendarLargeTextPreview() => _preview(largeText: true);

@Preview(
    name: 'Daily note calendar — dark tablet',
    size: Size(760, 900),
    brightness: Brightness.dark)
Widget dailyNoteCalendarTabletPreview() => _preview(dark: true);

Widget _preview(
        {bool chinese = false, bool dark = false, bool largeText = false}) =>
    MaterialApp(
      theme: dark ? AppTheme.dark : AppTheme.light,
      locale: chinese ? const Locale('zh', 'HK') : const Locale('en'),
      supportedLocales: S.delegate.supportedLocales,
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(largeText ? 2.2 : (chinese ? 1.5 : 1)),
          disableAnimations: chinese || largeText,
        ),
        child: child!,
      ),
      home: Builder(builder: (context) {
        return Scaffold(
          appBar: AppBar(title: const Text('OnlyNote')),
          backgroundColor:
              Theme.of(context).colorScheme.surfaceContainerHighest,
          body: Align(
            alignment: Alignment.bottomCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Material(
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(28)),
                clipBehavior: Clip.antiAlias,
                child: DailyNoteCalendarSheet(
                  today: DateTime(2026, 10, 6),
                  notes: [
                    Note(
                      id: 'today',
                      title: chinese ? '安靜的早晨' : 'A quiet morning',
                      description: chinese
                          ? '沿海岸散步，然後在咖啡店寫了一會兒。'
                          : 'A walk along the coast, then time to write at the café.',
                      dailyNoteDateKey: '2026-10-06',
                    ),
                    Note(
                      id: 'weekend',
                      title: chinese ? '週末計畫' : 'Weekend plans',
                      description:
                          chinese ? '去市場買花。' : 'Visit the flower market.',
                      dailyNoteDateKey: '2026-10-03',
                    ),
                    Note(
                      id: 'september',
                      title: chinese ? '旅行筆記' : 'Travel notes',
                      description:
                          chinese ? '新發現與值得記住的小事。' : 'Places to revisit.',
                      dailyNoteDateKey: '2026-09-23',
                      isArchived: true,
                    ),
                    Note(
                      id: 'new-year',
                      title: chinese ? '新年心願' : 'New year wishes',
                      dailyNoteDateKey: '2027-01-01',
                    ),
                  ],
                  onOpenDay: previewOpenDailyCalendarDay,
                  onOpenToday: previewOpenDailyCalendarToday,
                ),
              ),
            ),
          ),
        );
      }),
    );
