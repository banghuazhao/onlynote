import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/domain/model/voice_memo.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/voice_memo_composer.dart';
import 'package:onlynote/presentation/components/voice_memo_player.dart';
import 'package:onlynote/presentation/theme/spacing.dart';
import 'package:onlynote/services/voice_memo_service.dart';

class _Platform implements VoiceMemoPlatform {
  final events = StreamController<Object?>.broadcast();
  final calls = <String>[];
  bool denied = false;
  bool unsupported = false;
  Completer<Object?>? recognition;
  @override
  Stream<Object?> get states => events.stream;
  @override
  Future<Object?> invoke(String method,
      [Map<String, Object?>? arguments]) async {
    calls.add(method);
    if (method == 'startRecording' && denied) {
      throw PlatformException(code: 'permission_denied');
    }
    if (method == 'transcribe') {
      if (unsupported) {
        throw PlatformException(code: 'transcription_unavailable');
      }
      if (recognition != null) return await recognition!.future;
      return 'Recognized words';
    }
    if (method == 'cancelTranscription' &&
        recognition != null &&
        !recognition!.isCompleted) {
      recognition!.completeError(PlatformException(code: 'cancelled'));
    }
    return {
      'phase': method == 'startRecording'
          ? 'recording'
          : method == 'play'
              ? 'playing'
              : 'idle',
      'path': '/app/note_audio/memo.m4a',
      'durationMs': method == 'startRecording' ? 0 : 5000
    };
  }
}

Widget _host(Widget child, {double scale = 1, Locale? locale}) => MaterialApp(
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
      home: Scaffold(body: child),
    );

void main() {
  late _Platform platform;
  late VoiceMemoService service;
  late List<VoiceMemo> retained;
  late List<VoiceMemo> saved;
  late int discarded;
  late int prepared;
  setUp(() {
    retained = [];
    saved = [];
    discarded = 0;
    prepared = 0;
  });
  tearDown(() async {
    await service.dispose();
    await platform.events.close();
  });
  final memo = VoiceMemo(
      id: 'memo',
      path: 'note_audio/memo.m4a',
      durationMs: 0,
      createdAt: DateTime(2026, 10, 6));

  void createService() {
    // Create queued Futures inside WidgetTester's zone, not the outer setUp.
    platform = _Platform();
    service = VoiceMemoService(platform: platform);
  }

  Future<void> open(WidgetTester tester,
      {double scale = 1,
      Locale? locale,
      bool denied = false,
      bool unsupported = false}) async {
    createService();
    platform.denied = denied;
    platform.unsupported = unsupported;
    await tester.pumpWidget(_host(
        Builder(
            builder: (context) => TextButton(
                onPressed: () => showVoiceMemoComposer(context,
                    service: service,
                    createDraft: () async {
                      prepared++;
                      return memo;
                    },
                    resolvePath: (path) async => '/app/$path',
                    retainDraft: (memo) async {
                      retained.add(memo);
                    },
                    saveDraft: (memo) async {
                      saved.add(memo);
                      return memo;
                    },
                    discardDraft: (_) async {
                      discarded++;
                    }),
                child: const Text('Open'))),
        scale: scale,
        locale: locale));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
  }

  Future<void> recordStop(WidgetTester tester) async {
    await tester.tap(find.byKey(const ValueKey('voice-record')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('voice-stop')));
    await tester.pumpAndSettle();
  }

  testWidgets('no recording permission or file preparation before Record tap',
      (tester) async {
    await open(tester);
    expect(prepared, 0);
    expect(platform.calls, ['state']);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(discarded, 0);
    expect(find.text('Open'), findsOneWidget);
  });
  testWidgets('reviewed transcript is journaled before saving the recording',
      (tester) async {
    await open(tester);
    await recordStop(tester);
    expect(retained.last.durationMs, 5000);
    await tester.tap(find.byKey(const ValueKey('voice-transcribe')));
    await tester.pumpAndSettle();
    expect(find.text('Recognized words'), findsOneWidget);
    await tester.enterText(find.byKey(const ValueKey('voice-transcript')),
        'My corrected transcript');
    await tester.ensureVisible(find.byKey(const ValueKey('voice-save')));
    await tester.tap(find.byKey(const ValueKey('voice-save')));
    await tester.pumpAndSettle();
    expect(saved.single.transcript, 'My corrected transcript');
    expect(retained.last, saved.single);
    expect(discarded, 0);
  });
  testWidgets('permission denial cleans the prepared draft and allows retry',
      (tester) async {
    await open(tester, denied: true);
    await tester.tap(find.byKey(const ValueKey('voice-record')));
    await tester.pumpAndSettle();
    expect(discarded, 1);
    expect(find.byKey(const ValueKey('voice-error')), findsOneWidget);
    platform.denied = false;
    await recordStop(tester);
    expect(prepared, 2);
    expect(retained.last.durationMs, 5000);
  });
  testWidgets(
      'unsupported transcription keeps recording saveable at large text',
      (tester) async {
    tester.view.physicalSize = const Size(320, 820);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await open(tester, scale: 2, unsupported: true);
    await recordStop(tester);
    await tester.ensureVisible(find.byKey(const ValueKey('voice-transcribe')));
    await tester.tap(find.byKey(const ValueKey('voice-transcribe')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('voice-save')));
    await tester.tap(find.byKey(const ValueKey('voice-save')));
    await tester.pumpAndSettle();
    expect(saved.single.durationMs, 5000);
    expect(saved.single.transcript, isNull);
    expect(tester.takeException(), isNull);
  });
  testWidgets('player delegates play and pause for its own memo',
      (tester) async {
    createService();
    await tester.pumpWidget(_host(VoiceMemoPlayer(
        memo: memo.copyWith(durationMs: 5000),
        service: service,
        resolvePath: (path) async => '/app/$path')));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Play'));
    await tester.pumpAndSettle();
    expect(platform.calls.last, 'play');
    await tester.tap(find.byTooltip('Pause'));
    await tester.pumpAndSettle();
    expect(platform.calls.last, 'pause');
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets('large Chinese text keeps recording controls usable',
      (tester) async {
    tester.view.physicalSize = const Size(320, 820);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await open(tester, scale: 2, locale: const Locale('zh', 'HK'));
    await recordStop(tester);
    await tester.ensureVisible(find.byKey(const ValueKey('voice-transcribe')));
    await tester.tap(find.byKey(const ValueKey('voice-transcribe')));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const ValueKey('voice-transcript')), '明天買牛奶，保留這段修正後的文字。');
    await tester.ensureVisible(find.byKey(const ValueKey('voice-save')));
    await tester.tap(find.byKey(const ValueKey('voice-save')));
    await tester.pumpAndSettle();
    expect(saved.single.transcript, '明天買牛奶，保留這段修正後的文字。');
    expect(tester.takeException(), isNull);
  });
  testWidgets('disposing a player cancels recognition for its own file',
      (tester) async {
    createService();
    platform.recognition = Completer<Object?>();
    await tester.pumpWidget(_host(VoiceMemoPlayer(
        memo: memo.copyWith(durationMs: 5000),
        service: service,
        resolvePath: (path) async => '/app/$path',
        onTranscriptChanged: (_) async {})));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text(S.current.Voice_Transcribe));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
    expect(platform.calls, contains('transcribe'));
    expect(service.isTranscribingPath('/app/note_audio/memo.m4a'), isTrue);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    expect(platform.calls, contains('cancelTranscription'));
    expect(service.isTranscribingPath('/app/note_audio/memo.m4a'), isFalse);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
      'closing a player while resolving a file never starts recognition',
      (tester) async {
    createService();
    final path = Completer<String>();
    await tester.pumpWidget(_host(VoiceMemoPlayer(
        memo: memo.copyWith(durationMs: 5000),
        service: service,
        resolvePath: (_) async => await path.future,
        onTranscriptChanged: (_) async {})));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text(S.current.Voice_Transcribe));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpWidget(const SizedBox.shrink());
    path.complete('/app/note_audio/memo.m4a');
    await tester.pumpAndSettle();
    expect(platform.calls, isNot(contains('transcribe')));
    expect(tester.takeException(), isNull);
  });
}
