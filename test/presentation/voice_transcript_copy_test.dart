import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/domain/model/voice_memo.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/voice_memo_player.dart';
import 'package:onlynote/presentation/theme/spacing.dart';
import 'package:onlynote/services/voice_memo_service.dart';

const _text = '  Full reviewed transcript\n茶與計劃 👩🏽‍💻 e\u0301\n  ';
final _memo = VoiceMemo(
  id: 'memo',
  path: 'note_audio/memo.m4a',
  durationMs: 42000,
  createdAt: DateTime(2026, 10, 23, 9),
  transcript: _text,
);

class _AudioPlatform implements VoiceMemoPlatform {
  final calls = <String>[];

  @override
  Stream<Object?> get states => const Stream.empty();

  @override
  Future<Object?> invoke(String method,
      [Map<String, Object?>? arguments]) async {
    calls.add(method);
    return {
      'phase': method == 'play' ? 'playing' : 'idle',
      if (method == 'play') 'path': arguments!['path'],
      'durationMs': 42000,
    };
  }
}

class _Fixture {
  final audio = _AudioPlatform();
  late final service = VoiceMemoService(platform: audio);
  int pathReads = 0;

  Widget app(VoiceMemo memo,
          {Future<void> Function(String)? writer,
          Locale locale = const Locale('en'),
          double textScale = 1}) =>
      MaterialApp(
        theme: ThemeData(extensions: const [AppTokens()]),
        locale: locale,
        supportedLocales: S.delegate.supportedLocales,
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
            disableAnimations: true,
          ),
          child: child!,
        ),
        home: Scaffold(
          body: SingleChildScrollView(
            child: VoiceMemoPlayer(
              memo: memo,
              service: service,
              clipboardWriter: writer,
              resolvePath: (path) async {
                pathReads++;
                return '/app/$path';
              },
            ),
          ),
        ),
      );
}

Future<_Fixture> _open(WidgetTester tester,
    {VoiceMemo? memo,
    Future<void> Function(String)? writer,
    Locale locale = const Locale('en'),
    double textScale = 1}) async {
  final fixture = _Fixture();
  await tester.pumpWidget(fixture.app(memo ?? _memo,
      writer: writer, locale: locale, textScale: textScale));
  await tester.pumpAndSettle();
  addTearDown(() async {
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpWidget(const SizedBox.shrink());
    await fixture.service.dispose();
  });
  return fixture;
}

Future<void> _menu(WidgetTester tester) async {
  final button = find.byType(PopupMenuButton<String>);
  await tester.ensureVisible(button);
  await tester.tap(button);
  await tester.pumpAndSettle();
}

Future<void> _copy(WidgetTester tester) async {
  await _menu(tester);
  final action = find.text(S.current.Voice_Copy_Transcript);
  expect(action, findsOneWidget);
  await tester.ensureVisible(action);
  await tester.tap(action);
  await tester.pumpAndSettle();
}

Future<void> _drainFeedback(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 3));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
      'read-only recording copies the exact saved text without media I/O',
      (tester) async {
    final copied = <String>[];
    final fixture =
        await _open(tester, writer: (text) async => copied.add(text));
    final original = _memo.toMap();
    await _copy(tester);
    expect(copied, [_text]);
    expect(find.text(S.current.Voice_Transcript_Copied), findsOneWidget);
    expect(fixture.pathReads, 0);
    expect(fixture.audio.calls, ['state']);
    expect(_memo.toMap(), original);
    expect(tester.takeException(), isNull);
    await _drainFeedback(tester);
  });

  testWidgets('default action writes only Clipboard.setData with the full text',
      (tester) async {
    final writes = <Object?>[];
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') writes.add(call.arguments);
      return null;
    });
    addTearDown(() =>
        messenger.setMockMethodCallHandler(SystemChannels.platform, null));
    final fixture = await _open(tester);
    await _copy(tester);
    expect(writes, [
      {'text': _text}
    ]);
    expect(fixture.audio.calls, ['state']);
    expect(fixture.pathReads, 0);
    expect(tester.takeException(), isNull);
    await _drainFeedback(tester);
  });

  for (final blank in <String?>[null, '', ' \n\t\u3000 ']) {
    testWidgets('copy action is absent for blank transcript: $blank',
        (tester) async {
      var writes = 0;
      final fixture = await _open(tester,
          memo:
              _memo.copyWith(transcript: blank, clearTranscript: blank == null),
          writer: (_) async => writes++);
      await _menu(tester);
      expect(find.text(S.current.Voice_Copy_Transcript), findsNothing);
      expect(find.text(S.current.Share), findsOneWidget);
      expect(writes, 0);
      expect(fixture.pathReads, 0);
      Navigator.of(tester.element(find.byType(VoiceMemoPlayer))).pop();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
      'clipboard failure reports an error and allows a successful retry',
      (tester) async {
    var attempts = 0;
    final copied = <String>[];
    final fixture = await _open(tester, writer: (text) async {
      attempts++;
      if (attempts == 1) throw PlatformException(code: 'clipboard_unavailable');
      copied.add(text);
    });
    await _copy(tester);
    expect(find.text(S.current.Voice_Transcript_Copy_Failed), findsOneWidget);
    expect(find.text(S.current.Voice_Transcript_Copied), findsNothing);
    await _drainFeedback(tester);
    await _copy(tester);
    expect(attempts, 2);
    expect(copied, [_text]);
    expect(find.text(S.current.Voice_Transcript_Copied), findsOneWidget);
    expect(fixture.audio.calls, ['state']);
    expect(fixture.pathReads, 0);
    expect(tester.takeException(), isNull);
    await _drainFeedback(tester);
  });

  testWidgets('repeated callbacks while clipboard is pending copy once',
      (tester) async {
    final pending = Completer<void>();
    final copied = <String>[];
    final fixture = await _open(tester, writer: (text) {
      copied.add(text);
      return pending.future;
    });
    await _menu(tester);
    final callback = tester
        .widget<PopupMenuButton<String>>(find.byType(PopupMenuButton<String>))
        .onSelected!;
    Navigator.of(tester.element(find.byType(VoiceMemoPlayer))).pop();
    await tester.pumpAndSettle();
    callback('copyTranscript');
    callback('copyTranscript');
    await tester.pump();
    expect(copied, [_text]);
    expect(
        tester
            .widget<PopupMenuButton<String>>(
                find.byType(PopupMenuButton<String>))
            .enabled,
        isFalse);
    expect(fixture.audio.calls, ['state']);
    pending.complete();
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<PopupMenuButton<String>>(
                find.byType(PopupMenuButton<String>))
            .enabled,
        isTrue);
    expect(find.text(S.current.Voice_Transcript_Copied), findsOneWidget);
    expect(tester.takeException(), isNull);
    await _drainFeedback(tester);
  });

  for (final replaceRecording in [false, true]) {
    testWidgets(
        'stale menu cannot copy changed ${replaceRecording ? 'recording' : 'transcript'}',
        (tester) async {
      final copied = <String>[];
      Future<void> writer(String text) async => copied.add(text);
      final fixture = await _open(tester, writer: writer);
      await _menu(tester);
      final replacement = _memo.copyWith(
        id: replaceRecording ? 'replacement' : null,
        path: replaceRecording ? 'note_audio/replacement.m4a' : null,
        transcript: 'Updated stored words',
      );
      await tester.pumpWidget(fixture.app(replacement, writer: writer));
      await tester.pumpAndSettle();
      await tester.tap(find.text(S.current.Voice_Copy_Transcript));
      await tester.pumpAndSettle();
      expect(copied, isEmpty);
      expect(find.text(S.current.Voice_Transcript_Copied), findsNothing);
      expect(fixture.audio.calls, ['state']);
      expect(tester.takeException(), isNull);
    });
  }

  for (final fail in [false, true]) {
    testWidgets(
        'late clipboard ${fail ? 'failure' : 'success'} does not affect a replacement memo',
        (tester) async {
      final pending = Completer<void>();
      Future<void> writer(String _) => pending.future;
      final fixture = await _open(tester, writer: writer);
      await _copy(tester);
      await tester.pumpWidget(fixture.app(
          _memo.copyWith(transcript: 'Replacement transcript'),
          writer: writer));
      await tester.pumpAndSettle();
      if (fail) {
        pending.completeError(StateError('Clipboard failed'));
      } else {
        pending.complete();
      }
      await tester.pumpAndSettle();
      expect(find.text(S.current.Voice_Transcript_Copied), findsNothing);
      expect(find.text(S.current.Voice_Transcript_Copy_Failed), findsNothing);
      expect(
          tester
              .widget<PopupMenuButton<String>>(
                  find.byType(PopupMenuButton<String>))
              .enabled,
          isTrue);
      expect(find.text('Replacement transcript'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'clipboard ${fail ? 'failure' : 'success'} after disposal is harmless',
        (tester) async {
      final pending = Completer<void>();
      await _open(tester, writer: (_) => pending.future);
      await _copy(tester);
      await tester.pumpWidget(const SizedBox.shrink());
      if (fail) {
        pending.completeError(StateError('Clipboard failed'));
      } else {
        pending.complete();
      }
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('copying a playing recording does not pause or reload its audio',
      (tester) async {
    final copied = <String>[];
    final fixture =
        await _open(tester, writer: (text) async => copied.add(text));
    await tester.tap(find.byTooltip(S.current.Voice_Play));
    await tester.pumpAndSettle();
    expect(fixture.service.state.value.playing, isTrue);
    expect(fixture.audio.calls, ['state', 'play']);
    await _copy(tester);
    expect(copied, [_text]);
    expect(fixture.pathReads, 1);
    expect(fixture.audio.calls, ['state', 'play']);
    expect(fixture.service.state.value.playing, isTrue);
    expect(tester.takeException(), isNull);
    await _drainFeedback(tester);
  });

  testWidgets('audio controls remain usable while a clipboard write is pending',
      (tester) async {
    final pending = Completer<void>();
    final fixture = await _open(tester, writer: (_) => pending.future);
    await _copy(tester);
    final play = find.byTooltip(S.current.Voice_Play);
    await tester.tap(play);
    await tester.pumpAndSettle();
    expect(fixture.service.state.value.playing, isTrue);
    pending.complete();
    await tester.pumpAndSettle();
    expect(fixture.audio.calls, ['state', 'play']);
    expect(fixture.service.state.value.playing, isTrue);
    expect(find.text(S.current.Voice_Transcript_Copied), findsOneWidget);
    expect(tester.takeException(), isNull);
    await _drainFeedback(tester);
  });

  testWidgets('an older copy cannot finish a newer transcript copy',
      (tester) async {
    final oldCopy = Completer<void>();
    final newCopy = Completer<void>();
    final writes = <String>[];
    Future<void> writer(String text) {
      writes.add(text);
      return text == _text ? oldCopy.future : newCopy.future;
    }

    final fixture = await _open(tester, writer: writer);
    await _copy(tester);
    await tester.pumpWidget(fixture
        .app(_memo.copyWith(transcript: 'Updated words'), writer: writer));
    await tester.pumpAndSettle();
    await _copy(tester);
    expect(writes, [_text, 'Updated words']);
    oldCopy.complete();
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<PopupMenuButton<String>>(
                find.byType(PopupMenuButton<String>))
            .enabled,
        isFalse);
    expect(find.text(S.current.Voice_Transcript_Copied), findsNothing);
    newCopy.complete();
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<PopupMenuButton<String>>(
                find.byType(PopupMenuButton<String>))
            .enabled,
        isTrue);
    expect(find.text(S.current.Voice_Transcript_Copied), findsOneWidget);
    expect(fixture.pathReads, 0);
    expect(fixture.audio.calls, ['state']);
    expect(tester.takeException(), isNull);
    await _drainFeedback(tester);
  });

  for (final fail in [false, true]) {
    testWidgets('late clipboard feedback stays off a newly opened page: $fail',
        (tester) async {
      final pending = Completer<void>();
      await _open(tester, writer: (_) => pending.future);
      await _copy(tester);
      final navigator =
          Navigator.of(tester.element(find.byType(VoiceMemoPlayer)));
      unawaited(navigator.push<void>(MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: Text('Destination page')),
      )));
      await tester.pumpAndSettle();
      if (fail) {
        pending.completeError(StateError('Clipboard failed'));
      } else {
        pending.complete();
      }
      await tester.pumpAndSettle();
      expect(find.text('Destination page'), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);
      navigator.pop();
      await tester.pumpAndSettle();
      expect(
          tester
              .widget<PopupMenuButton<String>>(
                  find.byType(PopupMenuButton<String>))
              .enabled,
          isTrue);
      expect(find.byType(SnackBar), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  for (final locale in [
    const Locale('en'),
    const Locale('zh'),
    const Locale('zh', 'HK')
  ]) {
    testWidgets(
        '$locale transcript menu fits narrow large text and copies fully',
        (tester) async {
      tester.view.physicalSize = const Size(320, 740);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final copied = <String>[];
      final fixture = await _open(tester,
          memo: _memo.copyWith(transcript: _text * 20),
          writer: (text) async => copied.add(text),
          locale: locale,
          textScale: 2);
      await _copy(tester);
      expect(copied, [_text * 20]);
      expect(find.text(S.current.Voice_Transcript_Copied), findsOneWidget);
      expect(fixture.audio.calls, ['state']);
      expect(fixture.pathReads, 0);
      expect(tester.takeException(), isNull);
      await _drainFeedback(tester);
    });
  }
}
