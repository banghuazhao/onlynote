import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/domain/model/note_image_layout.dart';
import 'package:onlynote/domain/model/voice_memo.dart';
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

@Preview(name: 'Daily note calendar — empty month', size: Size(390, 844))
Widget dailyNoteCalendarEmptyMonthPreview() => _preview(emptyMonth: true);

@Preview(name: 'Daily note calendar — media only', size: Size(390, 844))
Widget dailyNoteCalendarMediaPreview() => _preview(mediaOnly: true);

@Preview(
    name: 'Daily note calendar — media only dark',
    size: Size(390, 844),
    brightness: Brightness.dark)
Widget dailyNoteCalendarMediaDarkPreview() =>
    _preview(mediaOnly: true, dark: true);

@Preview(name: 'Daily note calendar — media Chinese 2×', size: Size(320, 760))
Widget dailyNoteCalendarMediaChinesePreview() =>
    _preview(mediaOnly: true, chinese: true, largeText: true);

@Preview(name: 'Daily note calendar — transcript only', size: Size(390, 844))
Widget dailyNoteCalendarTranscriptPreview() => _preview(transcriptOnly: true);

@Preview(
    name: 'Daily note calendar — dark tablet',
    size: Size(760, 900),
    brightness: Brightness.dark)
Widget dailyNoteCalendarTabletPreview() => _preview(dark: true);

ThemeData _previewTheme(bool dark) {
  final theme = dark ? AppTheme.dark : AppTheme.light;
  return theme.copyWith(
    textTheme:
        theme.textTheme.apply(fontFamilyFallback: const ['DroidSansFallback']),
    primaryTextTheme: theme.primaryTextTheme
        .apply(fontFamilyFallback: const ['DroidSansFallback']),
  );
}

Widget _preview(
        {bool chinese = false,
        bool dark = false,
        bool largeText = false,
        bool emptyMonth = false,
        bool mediaOnly = false,
        bool transcriptOnly = false}) =>
    MaterialApp(
      theme: _previewTheme(dark),
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
                  today: DateTime(2026, emptyMonth ? 11 : 10, 6),
                  notes: [
                    Note(
                      id: 'today',
                      title: chinese ? '安靜的早晨' : 'A quiet morning',
                      description: mediaOnly || transcriptOnly
                          ? ''
                          : chinese
                              ? '沿海岸散步，然後在咖啡店寫了一會兒。'
                              : 'A walk along the coast, then time to write at the café.',
                      dailyNoteDateKey: '2026-10-06',
                      imagePaths: transcriptOnly
                          ? const []
                          : const [
                              'unavailable/photo.jpg',
                              'unavailable/scan.jpg'
                            ],
                      imageLayouts: transcriptOnly
                          ? const []
                          : const [
                              NoteImageLayout(
                                  path: 'unavailable/scan.jpg',
                                  textOffset: 0,
                                  isDocumentPage: true),
                            ],
                      voiceMemos: [
                        VoiceMemo(
                            id: 'first',
                            path: 'note_audio/unavailable-first.m4a',
                            durationMs: 92000,
                            createdAt: DateTime(2026, 10, 6),
                            transcript: mediaOnly
                                ? null
                                : chinese
                                    ? '記下今天散步時想到的事情。'
                                    : 'Ideas from this morning’s walk, saved in a voice note.'),
                        VoiceMemo(
                            id: 'second',
                            path: 'note_audio/unavailable-second.m4a',
                            durationMs: 23000,
                            createdAt: DateTime(2026, 10, 6)),
                      ],
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
