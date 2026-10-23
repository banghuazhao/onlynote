import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:onlynote/domain/model/voice_memo.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/voice_memo_composer.dart';
import 'package:onlynote/presentation/components/voice_memo_date_label.dart';
import 'package:onlynote/presentation/components/voice_memo_player.dart';
import 'package:onlynote/presentation/theme/spacing.dart';
import 'package:onlynote/services/voice_memo_service.dart';

class _Platform implements VoiceMemoPlatform {
  final events = StreamController<Object?>.broadcast();
  final calls = <String>[];
  final playedPaths = <String>[];
  bool denied = false;
  bool unsupported = false;
  Completer<Object?>? recognition;
  @override
  Stream<Object?> get states => events.stream;
  @override
  Future<Object?> invoke(String method,
      [Map<String, Object?>? arguments]) async {
    calls.add(method);
    if (method == 'play') playedPaths.add(arguments!['path']! as String);
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
      'path':
          method == 'play' ? arguments!['path'] : '/app/note_audio/memo.m4a',
      'durationMs': method == 'startRecording' ? 0 : 5000
    };
  }
}

Widget _host(Widget child,
        {double scale = 1, Locale? locale, bool use24HourClock = false}) =>
    MaterialApp(
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
              textScaler: TextScaler.linear(scale),
              alwaysUse24HourFormat: use24HourClock,
              disableAnimations: true),
          child: child!),
      home: Scaffold(body: child),
    );

void main() {
  setUpAll(() => initializeDateFormatting());
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
      bool unsupported = false,
      Future<VoiceMemo> Function(VoiceMemo)? saveDraft}) async {
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
                    saveDraft: saveDraft ??
                        (memo) async {
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
  for (final fails in [false, true]) {
    testWidgets(
        'pending recording save freezes the reviewed transcript${fails ? ' and failure unlocks retry' : ''}',
        (tester) async {
      final pending = Completer<VoiceMemo>();
      var attempts = 0;
      await open(tester, saveDraft: (memo) {
        saved.add(memo);
        attempts++;
        return attempts == 1 ? pending.future : Future.value(memo);
      });
      await recordStop(tester);
      final input = find.byKey(const ValueKey('voice-transcript'));
      await tester.enterText(input, 'Reviewed transcript');
      final save = find.byKey(const ValueKey('voice-save'));
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(saved.single.transcript, 'Reviewed transcript');
      expect(tester.widget<TextField>(input).readOnly, isTrue);
      expect(tester.widget<FilledButton>(save).onPressed, isNull);

      // A late platform edit must not diverge from the snapshot being saved.
      final editable = tester.state<EditableTextState>(
          find.descendant(of: input, matching: find.byType(EditableText)));
      editable.updateEditingValue(const TextEditingValue(
        text: 'Unsubmitted edit',
        selection: TextSelection.collapsed(offset: 16),
      ));
      await tester.pump();
      expect(tester.widget<TextField>(input).controller!.text,
          'Reviewed transcript');
      expect(retained.last.transcript, 'Reviewed transcript');

      if (fails) {
        pending.completeError(StateError('Disk full'));
        await tester.pumpAndSettle();
        expect(tester.widget<TextField>(input).readOnly, isFalse);
        expect(find.byKey(const ValueKey('voice-error')), findsOneWidget);
        await tester.enterText(input, 'Corrected after retry');
        await tester.ensureVisible(save);
        await tester.tap(save);
        await tester.pumpAndSettle();
        expect(saved.last.transcript, 'Corrected after retry');
        expect(attempts, 2);
      } else {
        pending.complete(saved.single);
        await tester.pumpAndSettle();
      }
      expect(find.byType(VoiceMemoComposer), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('recognition keeps manual transcript edits available',
      (tester) async {
    await open(tester);
    await recordStop(tester);
    platform.recognition = Completer<Object?>();
    await tester.tap(find.byKey(const ValueKey('voice-transcribe')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(platform.calls, contains('transcribe'));
    final input = find.byKey(const ValueKey('voice-transcript'));
    expect(tester.widget<TextField>(input).readOnly, isFalse);
    await tester.enterText(input, 'Keep these manual corrections');
    platform.recognition!.complete('Late recognized words');
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(input).controller!.text,
        'Keep these manual corrections');
    final save = find.byKey(const ValueKey('voice-save'));
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(saved.single.transcript, 'Keep these manual corrections');
    expect(tester.takeException(), isNull);
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
    var pathResolutions = 0;
    await tester.pumpWidget(_host(VoiceMemoPlayer(
        memo: memo.copyWith(durationMs: 5000),
        service: service,
        resolvePath: (path) async {
          pathResolutions++;
          return '/app/$path';
        })));
    await tester.pumpAndSettle();
    expect(find.byType(VoiceMemoDateLabel), findsOneWidget);
    expect(pathResolutions, 0);
    expect(platform.calls, ['state']);
    await tester.tap(find.byTooltip('Play'));
    await tester.pumpAndSettle();
    expect(platform.calls.last, 'play');
    await tester.tap(find.byTooltip('Pause'));
    await tester.pumpAndSettle();
    expect(platform.calls.last, 'pause');
    expect(pathResolutions, 1);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  for (final transcribe in [false, true]) {
    testWidgets(
        'replacing a memo while resolving never starts old ${transcribe ? 'transcription' : 'playback'}',
        (tester) async {
      createService();
      final oldPath = Completer<String>();
      final changed = memo.copyWith(path: 'note_audio/next.m4a');
      final transcripts = <String?>[];
      Widget player(VoiceMemo value) => VoiceMemoPlayer(
            memo: value,
            service: service,
            resolvePath: (path) async =>
                path == memo.path ? await oldPath.future : '/app/$path',
            onTranscriptChanged: (text) async => transcripts.add(text),
          );
      await tester.pumpWidget(_host(player(memo)));
      await tester.pumpAndSettle();
      if (transcribe) {
        await tester.tap(find.byType(PopupMenuButton<String>));
        await tester.pumpAndSettle();
        await tester.tap(find.text(S.current.Voice_Transcribe));
      } else {
        await tester.tap(find.byTooltip(S.current.Voice_Play));
      }
      await tester.pump();
      await tester.pumpWidget(_host(player(changed)));
      oldPath.complete('/app/${memo.path}');
      await tester.pumpAndSettle();
      expect(
          platform.calls, isNot(contains(transcribe ? 'transcribe' : 'play')));
      expect(find.byType(AlertDialog), findsNothing);
      expect(transcripts, isEmpty);
      await tester.tap(find.byTooltip(S.current.Voice_Play));
      await tester.pumpAndSettle();
      expect(platform.playedPaths, ['/app/note_audio/next.m4a']);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  testWidgets('a memo replacement cannot receive an older transcript draft',
      (tester) async {
    createService();
    final oldWrites = <String?>[];
    final newWrites = <String?>[];
    Widget player(VoiceMemo value, List<String?> writes) => VoiceMemoPlayer(
          memo: value,
          service: service,
          resolvePath: (path) async => '/app/$path',
          onTranscriptChanged: (text) async => writes.add(text),
        );
    await tester.pumpWidget(
        _host(player(memo.copyWith(transcript: 'Original'), oldWrites)));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text(S.current.Voice_Edit_Transcript));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const ValueKey('voice-transcript-editor-input')),
        'Draft for the original recording');
    // The same path under a new identity must also invalidate old callbacks.
    await tester.pumpWidget(_host(player(
        memo.copyWith(id: 'replacement', transcript: 'Keep replacement'),
        newWrites)));
    await tester.pumpAndSettle();
    await tester.tap(find.text(S.current.Voice_Save));
    await tester.pumpAndSettle();
    expect(oldWrites, isEmpty);
    expect(newWrites, isEmpty);
    expect(find.text('Keep replacement'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
      'path changes cancel old recognition without editing the new memo',
      (tester) async {
    createService();
    platform.recognition = Completer<Object?>();
    final writes = <String?>[];
    Widget player(VoiceMemo value) => VoiceMemoPlayer(
          memo: value,
          service: service,
          resolvePath: (path) async => '/app/$path',
          onTranscriptChanged: (text) async => writes.add(text),
        );
    await tester.pumpWidget(_host(player(memo)));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text(S.current.Voice_Transcribe));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
    expect(service.isTranscribingPath('/app/${memo.path}'), isTrue);
    await tester.pumpWidget(
        _host(player(memo.copyWith(path: 'note_audio/replacement.m4a'))));
    await tester.pumpAndSettle();
    expect(platform.calls, contains('cancelTranscription'));
    expect(writes, isEmpty);
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text(S.current.Voice_Transcription_Failed), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('a menu opened for an older memo cannot remove its replacement',
      (tester) async {
    createService();
    var removed = 0;
    Widget player(VoiceMemo value) => VoiceMemoPlayer(
          memo: value,
          service: service,
          resolvePath: (path) async => '/app/$path',
          onRemove: () async => removed++,
        );
    await tester.pumpWidget(_host(player(memo)));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tester.pumpWidget(_host(player(memo.copyWith(id: 'replacement'))));
    await tester.pumpAndSettle();
    await tester.tap(find.text(S.current.Voice_Delete));
    await tester.pumpAndSettle();
    expect(removed, 0);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
      'player shows stored creation time and updates without opening media',
      (tester) async {
    createService();
    var pathResolutions = 0;
    final stored = memo.copyWith(createdAt: DateTime.utc(2026, 10, 11, 23, 45));
    Widget player(VoiceMemo value) => VoiceMemoPlayer(
          memo: value,
          service: service,
          resolvePath: (path) async {
            pathResolutions++;
            return '/app/$path';
          },
        );
    final dateText = find.descendant(
        of: find.byType(VoiceMemoDateLabel), matching: find.byType(Text));
    await tester.pumpWidget(_host(player(stored),
        locale: const Locale('zh', 'HK'), use24HourClock: true));
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<VoiceMemoDateLabel>(find.byType(VoiceMemoDateLabel))
            .createdAt,
        same(stored.createdAt));
    expect(
        tester.widget<Text>(dateText).data,
        S.current.Voice_Recorded_At(DateFormat.yMMMd('zh_HK')
            .add_Hm()
            .format(stored.createdAt.toLocal())));
    final changed = stored.copyWith(createdAt: DateTime(2027, 1, 2, 9, 7));
    await tester.pumpWidget(_host(player(changed)));
    await tester.pumpAndSettle();
    expect(tester.widget<Text>(dateText).data, 'Recorded Jan 2, 2027 9:07 AM');
    expect(pathResolutions, 0);
    expect(platform.calls, ['state']);
    expect(stored.createdAt, DateTime.utc(2026, 10, 11, 23, 45));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('large-text recording timestamp keeps share and remove reachable',
      (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    createService();
    var pathResolutions = 0;
    var shared = 0;
    var removed = 0;
    await tester.pumpWidget(_host(
        SingleChildScrollView(
          child: VoiceMemoPlayer(
            memo: memo.copyWith(
                durationMs: 5000, createdAt: DateTime(2026, 10, 11, 17, 45)),
            service: service,
            resolvePath: (path) async {
              pathResolutions++;
              return '/app/$path';
            },
            onShare: () async => shared++,
            onRemove: () async => removed++,
          ),
        ),
        locale: const Locale('zh', 'HK'),
        scale: 2,
        use24HourClock: true));
    await tester.pumpAndSettle();
    final label = find.byType(VoiceMemoDateLabel);
    expect(label, findsOneWidget);
    final bounds = tester.getRect(label);
    expect(bounds.left, greaterThanOrEqualTo(0));
    expect(bounds.right, lessThanOrEqualTo(320));
    expect(tester.takeException(), isNull);
    final menu = find.byType(PopupMenuButton<String>);
    await tester.ensureVisible(menu);
    await tester.tap(menu);
    await tester.pumpAndSettle();
    await tester.tap(find.text(S.current.Share));
    await tester.pumpAndSettle();
    expect(shared, 1);
    await tester.tap(menu);
    await tester.pumpAndSettle();
    await tester.tap(find.text(S.current.Voice_Delete));
    await tester.pumpAndSettle();
    expect(removed, 1);
    expect(pathResolutions, 0);
    expect(tester.takeException(), isNull);
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
