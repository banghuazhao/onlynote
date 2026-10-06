import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/Tools/share_helper.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/domain/model/voice_memo.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/note_share_sheet.dart';
import 'package:onlynote/presentation/components/voice_memo_player.dart';
import 'package:onlynote/presentation/theme/spacing.dart';
import 'package:onlynote/services/note_export.dart';
import 'package:onlynote/services/voice_memo_service.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

Widget _host(Widget child, {Locale? locale, double scale = 1}) => MaterialApp(
    locale: locale,
    theme: ThemeData(extensions: const [AppTokens()]),
    localizationsDelegates: const [
      S.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate
    ],
    supportedLocales: S.delegate.supportedLocales,
    builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(scale), disableAnimations: true),
        child: child!),
    home: Scaffold(body: child));

class _IdlePlatform implements VoiceMemoPlatform {
  @override
  Stream<Object?> get states => const Stream.empty();
  @override
  Future<Object?> invoke(String method,
          [Map<String, Object?>? arguments]) async =>
      {'phase': 'idle'};
}

void main() {
  late Directory directory;
  late File recording;
  late VoiceMemo memo;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('onlynote-share-audio-');
    recording = File('${directory.path}/memo.m4a');
    await recording.writeAsBytes([1, 2, 3, 4], flush: true);
    memo = VoiceMemo(
        id: 'memo',
        path: 'note_audio/memo.m4a',
        durationMs: 2500,
        createdAt: DateTime.utc(2026, 10, 6, 14, 30),
        transcript: 'Reviewed transcript 茶');
  });
  tearDown(() async => directory.delete(recursive: true));

  Future<BuildContext> contextFor(WidgetTester tester) async {
    late BuildContext context;
    await tester.pumpWidget(_host(Builder(builder: (value) {
      context = value;
      return const SizedBox(width: 100, height: 100);
    })));
    await tester.pumpAndSettle();
    addTearDown(() async {
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpWidget(const SizedBox.shrink());
    });
    return context;
  }

  testWidgets(
      'recording share snapshots original audio, transcript and iPad origin',
      (tester) async {
    final context = await contextFor(tester);
    late ShareParams params;
    const origin = Rect.fromLTWH(10, 20, 40, 40);
    await tester.runAsync(() => ShareHelper.shareVoiceMemo(context, memo,
        resolvePath: (_) async => recording.path,
        sharePositionOrigin: origin,
        share: (value) async {
          params = value;
          return ShareResult.unavailable;
        }));
    expect(params.fileNameOverrides, [
      'voice-memo-2026-10-06T14-30-00.m4a',
      'voice-memo-2026-10-06T14-30-00.txt'
    ]);
    expect(params.files!.first.mimeType, 'audio/mp4');
    expect(await params.files!.first.readAsBytes(), [1, 2, 3, 4]);
    expect(
        utf8.decode(await params.files!.last.readAsBytes()), memo.transcript);
    expect(params.text, memo.transcript);
    expect(params.sharePositionOrigin, origin);
    expect(recording.readAsBytesSync(), [1, 2, 3, 4]);
  });

  testWidgets('missing recording fails visibly without invoking native share',
      (tester) async {
    final context = await contextFor(tester);
    var calls = 0;
    await tester.runAsync(() => ShareHelper.shareVoiceMemo(context, memo,
        resolvePath: (_) async => '${directory.path}/missing.m4a',
        share: (_) async {
          calls++;
          return ShareResult.unavailable;
        }));
    await tester.pumpAndSettle();
    expect(calls, 0);
    expect(find.text(S.current.Share_Audio_Failed), findsOneWidget);
    expect(recording.existsSync(), isTrue);
  });

  testWidgets(
      'share failure preserves original and releases the guard for retry',
      (tester) async {
    final context = await contextFor(tester);
    await tester.runAsync(() => ShareHelper.shareVoiceMemo(context, memo,
        resolvePath: (_) async => recording.path,
        share: (_) async => throw StateError('Share unavailable')));
    var retryCalls = 0;
    await tester.runAsync(() => ShareHelper.shareVoiceMemo(
        context, memo.copyWith(clearTranscript: true),
        resolvePath: (_) async => recording.path,
        share: (params) async {
          retryCalls++;
          expect(params.files, hasLength(1));
          expect(params.text, isNull);
          expect(params.sharePositionOrigin, isNotNull);
          return ShareResult.unavailable;
        }));
    expect(retryCalls, 1);
    expect(recording.existsSync(), isTrue);
  });

  for (final markdown in [false, true]) {
    testWidgets(
        '${markdown ? 'Markdown' : 'Audio'} export includes original recordings',
        (tester) async {
      final context = await contextFor(tester);
      late Future<void> completed;
      late ShareParams params;
      await tester.runAsync(() async {
        completed = ShareHelper.shareNote(
            context,
            Note(
                title: 'Meeting 茶',
                description: 'Existing body',
                voiceMemos: [memo],
                imagePaths:
                    markdown ? [] : ['note_images/unrelated-missing.jpg']),
            ScreenshotController(),
            resolveAudioPath: (_) async => recording.path,
            share: (value) async {
              params = value;
              return ShareResult.unavailable;
            });
        await Future<void>.delayed(Duration.zero);
      });
      await tester.pumpAndSettle();
      final choice = find
          .text(markdown ? S.current.Share_Markdown : S.current.Share_Audio);
      await tester.ensureVisible(choice);
      await tester.tap(choice);
      await tester.runAsync(() => completed);
      await tester.pumpAndSettle();
      final names = params.fileNameOverrides!;
      expect(names, contains('Meeting 茶-recording-1.m4a'));
      final index = names.indexOf('Meeting 茶-recording-1.m4a');
      expect(params.files![index].mimeType, 'audio/mp4');
      expect(await params.files![index].readAsBytes(), [1, 2, 3, 4]);
      if (markdown) {
        final md = utf8.decode(await params.files!.first.readAsBytes());
        expect(md,
            contains('[Voice memo 1](Meeting%20%E8%8C%B6-recording-1.m4a)'));
        expect(md, contains('Reviewed transcript 茶'));
        expect(md, isNot(contains('note_audio/')));
      } else {
        expect(names, contains('Meeting 茶-transcripts.txt'));
        expect(params.text, contains('Reviewed transcript 茶'));
      }
      expect(recording.existsSync(), isTrue);
    });
  }

  testWidgets('audio format is hidden for notes without recordings',
      (tester) async {
    await tester.pumpWidget(_host(const NoteShareSheet()));
    await tester.pumpAndSettle();
    expect(find.text(S.current.Share_Audio), findsNothing);
  });

  testWidgets('large Chinese audio picker scrolls and selects recordings',
      (tester) async {
    tester.view.physicalSize = const Size(320, 820);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    NoteShareFormat? selected;
    await tester.pumpWidget(_host(
        Builder(
            builder: (context) => TextButton(
                onPressed: () async => selected =
                    await showNoteShareSheet(context, hasRecordings: true),
                child: const Text('Open'))),
        locale: const Locale('zh', 'HK'),
        scale: 2));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    final choice = find.text(S.current.Share_Audio);
    await tester.ensureVisible(choice);
    await tester.tap(choice);
    await tester.pumpAndSettle();
    expect(selected, NoteShareFormat.audio);
    expect(tester.takeException(), isNull);
  });

  testWidgets('read-only player exposes a share action', (tester) async {
    var shared = 0;
    final service = VoiceMemoService(platform: _IdlePlatform());
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await service.dispose();
    });
    await tester.pumpWidget(_host(VoiceMemoPlayer(
        memo: memo,
        service: service,
        resolvePath: (_) async => recording.path,
        onShare: () async {
          shared++;
        })));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text(S.current.Share));
    await tester.pumpAndSettle();
    expect(shared, 1);
  });
}
