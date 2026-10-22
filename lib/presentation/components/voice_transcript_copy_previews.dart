import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:onlynote/domain/model/voice_memo.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/theme/theme.dart';
import 'package:onlynote/services/voice_memo_service.dart';

import 'voice_memo_player.dart';

@Preview(name: 'Copy transcript — light', group: 'Note', size: Size(390, 760))
Widget voiceTranscriptCopyLightPreview() => const VoiceTranscriptCopyPreview();

@Preview(
  name: 'Copy transcript — dark',
  group: 'Note',
  size: Size(390, 760),
  brightness: Brightness.dark,
)
Widget voiceTranscriptCopyDarkPreview() =>
    const VoiceTranscriptCopyPreview(dark: true);

@Preview(
  name: 'Copy transcript — Chinese 2× narrow',
  group: 'Note',
  size: Size(280, 900),
)
Widget voiceTranscriptCopyChinesePreview() => const VoiceTranscriptCopyPreview(
      locale: Locale('zh', 'HK'),
      textScale: 2,
    );

/// The actual player menu writes to an in-memory clipboard and an idle service.
/// No recording, file, sharing, or system-clipboard plugin is used here.
class VoiceTranscriptCopyPreview extends StatefulWidget {
  const VoiceTranscriptCopyPreview({
    super.key,
    this.dark = false,
    this.locale = const Locale('en'),
    this.textScale = 1,
    this.platform,
  });

  final bool dark;
  final Locale locale;
  final double textScale;
  final VoiceMemoPlatform? platform;

  @override
  State<VoiceTranscriptCopyPreview> createState() =>
      _VoiceTranscriptCopyPreviewState();
}

class _VoiceTranscriptCopyPreviewState
    extends State<VoiceTranscriptCopyPreview> {
  late final VoiceMemoService _service;
  String? _copiedText;

  @override
  void initState() {
    super.initState();
    _service = VoiceMemoService(
      platform: widget.platform ?? _IdlePreviewVoicePlatform(),
    );
  }

  @override
  void dispose() {
    unawaited(_service.dispose());
    super.dispose();
  }

  Future<void> _copyText(String text) async {
    if (mounted) setState(() => _copiedText = text);
  }

  @override
  Widget build(BuildContext context) {
    final chinese = widget.locale.languageCode == 'zh';
    final transcript = chinese
        ? '  記住這個靈感，留待下次回顧。\n'
            '完整複製轉錄文字，保留換行和前後空白。\n'
            '  下午到茶室，帶上計劃與 café 筆記。  '
        : '  Keep this thought for the release review.\n'
            'Copy the complete transcript, including line breaks, '
            'checklist ideas and café notes.\n'
            '  First: confirm the plan. Second: share the reviewed wording.  ';
    final baseTheme = widget.dark ? AppTheme.dark : AppTheme.light;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: widget.locale,
      supportedLocales: S.delegate.supportedLocales,
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: baseTheme.copyWith(
        textTheme: baseTheme.textTheme.apply(
          fontFamilyFallback: const ['DroidSansFallback'],
        ),
        snackBarTheme: baseTheme.snackBarTheme.copyWith(
          contentTextStyle: baseTheme.snackBarTheme.contentTextStyle?.copyWith(
            fontFamilyFallback: const ['DroidSansFallback'],
          ),
        ),
      ),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(widget.textScale),
          alwaysUse24HourFormat: true,
          disableAnimations: true,
        ),
        child: child!,
      ),
      home: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Builder(builder: (context) {
              final strings = S.of(context);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  VoiceMemoPlayer(
                    key: const ValueKey('voice-transcript-copy-player'),
                    memo: VoiceMemo(
                      id: 'copy-preview',
                      path: 'note_audio/copy-preview.m4a',
                      durationMs: 42000,
                      createdAt: DateTime(2026, 10, 23, 14, 30),
                      transcript: transcript,
                    ),
                    resolvePath: (path) async => '/preview/$path',
                    onShare: () async {},
                    clipboardWriter: _copyText,
                    // SelectableText checks the system clipboard on mount.
                    // Plain display keeps this isolated preview fully local.
                    transcriptBuilder: (text) => Text(
                      text,
                      key: const ValueKey('voice-transcript-copy-text'),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    service: _service,
                  ),
                  if (_copiedText != null) ...[
                    const SizedBox(height: 20),
                    Text(
                      strings.Voice_Transcript_Copied,
                      key: const ValueKey('voice-transcript-copy-feedback'),
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _copiedText!,
                      key: const ValueKey('voice-transcript-copy-result'),
                      maxLines: 4,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _IdlePreviewVoicePlatform implements VoiceMemoPlatform {
  @override
  Stream<Object?> get states => const Stream<Object?>.empty();

  @override
  Future<Object?> invoke(String method,
          [Map<String, Object?>? arguments]) async =>
      const {'phase': 'idle', 'transcriptionSupported': false};
}
