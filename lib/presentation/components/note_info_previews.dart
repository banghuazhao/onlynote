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

@Preview(
  name: 'Note info — Chinese 2× narrow',
  group: 'Note',
  size: Size(280, 700),
)
Widget noteInfoChinesePreview() =>
    const _NoteInfoPreview(chinese: true, textScale: 2);

/// Content and themes are local fixtures; no native plugins or saved state.
class _NoteInfoPreview extends StatelessWidget {
  const _NoteInfoPreview({
    this.chinese = false,
    this.dark = false,
    this.textScale = 1,
  });

  final bool chinese;
  final bool dark;
  final double textScale;

  @override
  Widget build(BuildContext context) {
    final note = Note(
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
          disableAnimations: true,
        ),
        child: child!,
      ),
      home: Scaffold(
        body: Align(
          alignment: Alignment.bottomCenter,
          child: NoteInfoSheet(statistics: NoteStatistics.fromNote(note)),
        ),
      ),
    );
  }
}
