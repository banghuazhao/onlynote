import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/voice_memo_player.dart';
import 'package:onlynote/presentation/components/voice_transcript_copy_previews.dart';
import 'package:onlynote/services/voice_memo_service.dart';

class _PreviewPlatform implements VoiceMemoPlatform {
  final calls = <String>[];

  @override
  Stream<Object?> get states => const Stream<Object?>.empty();

  @override
  Future<Object?> invoke(String method,
      [Map<String, Object?>? arguments]) async {
    calls.add(method);
    return const {'phase': 'idle', 'transcriptionSupported': false};
  }
}

Finder _key(String key) => find.byKey(ValueKey(key));

Future<void> _capture(WidgetTester tester, String name) async {
  if (!const bool.fromEnvironment('CAPTURE_UI')) return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    _key('voice-transcript-copy-capture'),
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 2);
    try {
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final directory = Directory('/tmp/onlynote-release-feedback');
      await directory.create(recursive: true);
      await File('${directory.path}/$name.png')
          .writeAsBytes(bytes!.buffer.asUint8List());
    } finally {
      image.dispose();
    }
  });
}

void main() {
  setUpAll(() async {
    if (!const bool.fromEnvironment('CAPTURE_UI')) return;
    for (final (family, asset) in [
      ('Roboto', 'assets/fonts/Roboto-Regular.ttf'),
      ('DroidSansFallback', 'assets/fonts/DroidSansFallback.ttf'),
      ('MaterialIcons', 'fonts/MaterialIcons-Regular.otf'),
    ]) {
      final loader = FontLoader(family)..addFont(rootBundle.load(asset));
      await loader.load();
    }
  });

  for (final (name, preview, size, locale, brightness, copyLabel, copiedLabel)
      in [
    (
      'voice-transcript-copy-light',
      voiceTranscriptCopyLightPreview,
      const Size(390, 760),
      const Locale('en'),
      Brightness.light,
      'Copy transcript',
      'Transcript copied',
    ),
    (
      'voice-transcript-copy-dark',
      voiceTranscriptCopyDarkPreview,
      const Size(390, 760),
      const Locale('en'),
      Brightness.dark,
      'Copy transcript',
      'Transcript copied',
    ),
    (
      'voice-transcript-copy-chinese-large-text',
      voiceTranscriptCopyChinesePreview,
      const Size(280, 900),
      const Locale('zh', 'HK'),
      Brightness.light,
      '複製轉錄文字',
      '轉錄文字已複製',
    ),
  ]) {
    testWidgets('$name copies the full transcript without native work',
        (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final platform = _PreviewPlatform();
      final nativeCalls = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method.startsWith('Clipboard.')) {
            nativeCalls.add(call.method);
          }
          return null;
        },
      );
      const voiceChannel = MethodChannel('com.appsbay.onlynote/voice_memos');
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        voiceChannel,
        (call) async {
          nativeCalls.add('voice:${call.method}');
          return null;
        },
      );
      addTearDown(() {
        tester.binding.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, null);
        tester.binding.defaultBinaryMessenger
            .setMockMethodCallHandler(voiceChannel, null);
      });
      final fixture = preview() as VoiceTranscriptCopyPreview;
      await tester.pumpWidget(RepaintBoundary(
        key: const ValueKey('voice-transcript-copy-capture'),
        child: VoiceTranscriptCopyPreview(
          dark: fixture.dark,
          locale: fixture.locale,
          textScale: fixture.textScale,
          platform: platform,
        ),
      ));
      await tester.pumpAndSettle();
      final player = find.byType(VoiceMemoPlayer);
      final context = tester.element(player);
      final transcript =
          tester.widget<VoiceMemoPlayer>(player).memo.transcript!;
      expect(Localizations.localeOf(context), locale);
      expect(Theme.of(context).brightness, brightness);
      expect(S.of(context).Voice_Copy_Transcript, copyLabel);
      expect(S.of(context).Voice_Transcript_Copied, copiedLabel);
      expect(transcript, startsWith('  '));
      expect(transcript, endsWith('  '));
      expect(transcript, contains('\n'));
      expect(transcript.length, greaterThan(60));
      expect(
        tester.widget<Text>(_key('voice-transcript-copy-text')).data,
        transcript,
      );
      expect(tester.getSize(_key('voice-transcript-copy-text')).height,
          greaterThan(40));
      expect(platform.calls, ['state']);
      expect(nativeCalls, isEmpty);
      expect(_key('voice-transcript-copy-result'), findsNothing);

      final menu = find.descendant(
        of: player,
        matching: find.byType(PopupMenuButton<String>),
      );
      await tester.ensureVisible(menu);
      await tester.tap(menu);
      await tester.pumpAndSettle();
      final copy = find.widgetWithText(PopupMenuItem<String>, copyLabel);
      expect(copy, findsOneWidget);
      expect(find.text(S.of(context).Share), findsOneWidget);
      await _capture(tester, '$name-menu');
      await tester.tap(copy);
      await tester.pumpAndSettle();
      expect(
        tester.widget<Text>(_key('voice-transcript-copy-result')).data,
        transcript,
      );
      expect(
        tester.widget<Text>(_key('voice-transcript-copy-feedback')).data,
        copiedLabel,
      );
      expect(find.widgetWithText(SnackBar, copiedLabel), findsOneWidget);
      expect(platform.calls, ['state']);
      expect(nativeCalls, isEmpty);
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(_key('voice-transcript-copy-feedback'));
      await tester.pumpAndSettle();
      await _capture(tester, '$name-copied');

      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      expect(platform.calls, ['state']);
      expect(nativeCalls, isEmpty);
      expect(tester.takeException(), isNull);
    });
  }
}
