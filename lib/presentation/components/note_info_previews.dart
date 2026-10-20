import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/domain/model/note_image_layout.dart';
import 'package:onlynote/domain/model/voice_memo.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/services/note_statistics.dart';

import 'note_info_sheet.dart';

@Preview(name: 'Note info — light', group: 'Note', size: Size(390, 620))
Widget noteInfoLightPreview() => const _NoteInfoPreview();

@Preview(
  name: 'Note info — dark',
  group: 'Note',
  size: Size(390, 620),
  brightness: Brightness.dark,
)
Widget noteInfoDarkPreview() => const _NoteInfoPreview(dark: true);

@Preview(name: 'Note info — 24-hour clock', group: 'Note', size: Size(390, 620))
Widget noteInfo24HourPreview() => const _NoteInfoPreview(use24HourFormat: true);

@Preview(
    name: 'Note info — legacy date missing',
    group: 'Note',
    size: Size(390, 620))
Widget noteInfoMissingDatePreview() =>
    const _NoteInfoPreview(showModified: false);

@Preview(
    name: 'Note info — long folder name', group: 'Note', size: Size(390, 620))
Widget noteInfoLongFolderPreview() => const _NoteInfoPreview(longFolder: true);

@Preview(
  name: 'Note info — Chinese long folder 2×',
  group: 'Note',
  size: Size(280, 700),
)
Widget noteInfoChineseLongFolderPreview() =>
    const _NoteInfoPreview(chinese: true, textScale: 2, longFolder: true);

@Preview(
  name: 'Note info — Chinese 2× narrow',
  group: 'Note',
  size: Size(280, 700),
)
Widget noteInfoChinesePreview() =>
    const _NoteInfoPreview(chinese: true, textScale: 2);

@Preview(name: 'Daily note info — light', group: 'Note', size: Size(390, 620))
Widget dailyNoteInfoLightPreview() => const _NoteInfoPreview(dailyNote: true);

@Preview(
  name: 'Daily note info — dark',
  group: 'Note',
  size: Size(390, 620),
  brightness: Brightness.dark,
)
Widget dailyNoteInfoDarkPreview() =>
    const _NoteInfoPreview(dailyNote: true, dark: true);

@Preview(
  name: 'Daily note info — Chinese 2× narrow',
  group: 'Note',
  size: Size(280, 700),
)
Widget dailyNoteInfoChinesePreview() =>
    const _NoteInfoPreview(dailyNote: true, chinese: true, textScale: 2);

@Preview(name: 'Trash note info — light', group: 'Note', size: Size(390, 620))
Widget trashNoteInfoLightPreview() => const _NoteInfoPreview(trashed: true);

@Preview(
  name: 'Trash note info — dark',
  group: 'Note',
  size: Size(390, 620),
  brightness: Brightness.dark,
)
Widget trashNoteInfoDarkPreview() =>
    const _NoteInfoPreview(trashed: true, dark: true);

@Preview(
  name: 'Trash note info — Chinese 2× narrow',
  group: 'Note',
  size: Size(280, 700),
)
Widget trashNoteInfoChinesePreview() =>
    const _NoteInfoPreview(trashed: true, chinese: true, textScale: 2);

/// Content and themes are local fixtures; no native plugins or saved state.
class _NoteInfoPreview extends StatelessWidget {
  const _NoteInfoPreview({
    this.chinese = false,
    this.dark = false,
    this.textScale = 1,
    this.trashed = false,
    this.use24HourFormat = false,
    this.showModified = true,
    this.longFolder = false,
    this.dailyNote = false,
  });

  final bool chinese;
  final bool dark;
  final double textScale;
  final bool trashed;
  final bool use24HourFormat;
  final bool showModified;
  final bool longFolder;
  final bool dailyNote;

  @override
  Widget build(BuildContext context) {
    final note = Note(
      dateTime: showModified ? DateTime(2026, 10, 7, 14, 15) : null,
      deletedAt: trashed ? DateTime(2026, 10, 11, 14, 30) : null,
      dailyNoteDateKey: dailyNote ? '2024-02-29' : null,
      title: chinese ? '週末散步' : 'Weekend walk',
      description: chinese
          ? '沿海邊散步，看看春天的風景。\n記得留點時間給自己。 🌿'
          : 'Follow the coast and enjoy the spring scenery.\n'
              'Make some time for yourself. 🌿',
      todo: [
        Todo(title: chinese ? '帶水和零食' : 'Bring water and snacks'),
        Todo(
          title: chinese ? '邀請朋友' : 'Invite a friend',
          completed: true,
        ),
        Todo(title: chinese ? '查看天氣' : 'Check the forecast'),
        Todo(title: '  ', completed: true),
        Todo(),
      ],
      imagePaths: const [
        'note_images/preview-coast.jpg',
        'note_images/preview-tea.jpg',
        'note_images/preview-scan-one.jpg',
        'note_images/preview-scan-two.jpg',
      ],
      imageLayouts: const [
        NoteImageLayout(
          path: 'note_images/preview-scan-one.jpg',
          textOffset: 0,
          isDocumentPage: true,
        ),
        NoteImageLayout(
          path: 'note_images/preview-scan-two.jpg',
          textOffset: 0,
          isDocumentPage: true,
        ),
      ],
      voiceMemos: [
        VoiceMemo(
          id: 'preview',
          path: 'note_audio/preview.m4a',
          durationMs: 8000,
          createdAt: DateTime(2026, 10, 7),
          transcript: chinese ? '如果下雨，就改去喝茶。' : 'If it rains, stop for tea.',
        ),
        VoiceMemo(
          id: 'preview-long',
          path: 'note_audio/preview-long.m4a',
          durationMs: 3660000,
          createdAt: DateTime(2026, 10, 7),
        ),
      ],
    );
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: chinese ? const Locale('zh', 'HK') : const Locale('en'),
      supportedLocales: S.delegate.supportedLocales,
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        brightness: dark ? Brightness.dark : Brightness.light,
        colorSchemeSeed: const Color(0xFF685947),
        fontFamilyFallback: const ['DroidSansFallback'],
      ),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(textScale),
          alwaysUse24HourFormat: use24HourFormat,
          disableAnimations: true,
        ),
        child: child!,
      ),
      home: Scaffold(
        body: Align(
          alignment: Alignment.bottomCenter,
          child: NoteInfoSheet(
            statistics: NoteStatistics.fromNote(note),
            folderName: longFolder
                ? (chinese
                    ? '家庭旅行與週末散步的靈感和詳細計劃'
                    : 'Family trips and weekend walks with detailed plans')
                : (chinese ? '旅行計劃' : 'Travel plans'),
            modifiedAt: note.dateTime,
            dailyNoteDateKey: note.dailyNoteDateKey,
            deletedAt: note.deletedAt,
          ),
        ),
      ),
    );
  }
}
