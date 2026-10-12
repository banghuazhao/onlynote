import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/Tools/reminder.dart';
import 'package:onlynote/Tools/reminder_data.dart';
import 'package:onlynote/Tools/share_helper.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/domain/model/voice_memo.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/note_share_action_tile.dart';
import 'package:onlynote/presentation/components/note_share_sheet.dart';
import 'package:onlynote/presentation/theme/spacing.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

Widget _host(Widget child) => MaterialApp(
      locale: const Locale('en'),
      theme: ThemeData(extensions: const [AppTokens()]),
      supportedLocales: S.delegate.supportedLocales,
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: true),
        child: child!,
      ),
      home: Scaffold(body: child),
    );

VoiceMemo _memo(String id, {String? transcript}) => VoiceMemo(
      id: id,
      path: 'note_audio/$id.m4a',
      durationMs: 1000,
      createdAt: DateTime(2026, 10, 7),
      transcript: transcript,
    );

Future<BuildContext> _contextFor(WidgetTester tester) async {
  late BuildContext context;
  await tester.pumpWidget(_host(Builder(builder: (value) {
    context = value;
    return const SizedBox(width: 100, height: 100);
  })));
  await tester.pumpAndSettle();
  return context;
}

Future<void> _selectCopy(WidgetTester tester) async {
  await tester.pumpAndSettle();
  final copy = find.byKey(const ValueKey('note-share-copyText'));
  await tester.ensureVisible(copy);
  await tester.tap(copy);
  await tester.pumpAndSettle();
}

/// Drain transient snackbar timers before Flutter verifies the test body.
void _copyTestWidgets(
  String description,
  Future<void> Function(WidgetTester) body,
) {
  testWidgets(description, (tester) async {
    try {
      await body(tester);
    } finally {
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });
}

void main() {
  setUp(() => ReminderData.shared.reminders = []);
  tearDown(() => ReminderData.shared.reminders = []);

  _copyTestWidgets(
      'native clipboard receives exact complete text without reading media',
      (tester) async {
    final context = await _contextFor(tester);
    final calls = <MethodCall>[];
    tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') calls.add(call);
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null));
    final note = Note(
      id: 'copy-note',
      title: '  Project 茶😀\n',
      description: 'Body\nline two  ',
      todo: [
        Todo(id: 'open', title: 'Open\nmultiline'),
        Todo(id: 'done', title: 'Done', completed: true),
        Todo(id: 'placeholder'),
      ],
      voiceMemos: [
        _memo('missing', transcript: 'Transcript 🍵\nnext line'),
        _memo('silent')
      ],
      imagePaths: const ['note_images/missing.jpg'],
    );
    final reminder = Reminder(
        reminderDate: DateTime(2050, 1, 2, 11, 30),
        reminderId: 1,
        noteId: note.id!);
    ReminderData.shared.reminders = [reminder];
    var capturedImages = 0;
    var resolvedAudio = 0;
    var nativeShares = 0;
    final completed = ShareHelper.shareNote(
      context,
      note,
      ScreenshotController(),
      captureImage: () async {
        capturedImages++;
        throw StateError('Must not capture');
      },
      resolveAudioPath: (_) async {
        resolvedAudio++;
        throw StateError('Must not read audio');
      },
      share: (_) async {
        nativeShares++;
        return ShareResult.unavailable;
      },
    );
    await _selectCopy(tester);
    await completed;

    expect(calls, hasLength(1));
    expect(calls.single.arguments, {
      'text':
          '  Project 茶😀\n\n\nBody\nline two  \n\nTranscript 🍵\nnext line\n\n[ ] Open\nmultiline\n[x] Done\n[ ] \n\nReminder: 2050-01-02 11:30',
    });
    expect(find.text(S.current.Share_Text_Copied), findsOneWidget);
    expect(find.text(S.current.Share_Text_Copy_Failed), findsNothing);
    expect(capturedImages, 0);
    expect(resolvedAudio, 0);
    expect(nativeShares, 0);
    expect(note.title, '  Project 茶😀\n');
    expect(note.todo.map((todo) => todo.completed), [false, true, false]);
    expect(note.imagePaths, ['note_images/missing.jpg']);
    expect(ReminderData.shared.reminders, [reminder]);
    expect(tester.takeException(), isNull);
  });

  _copyTestWidgets(
      'copy without a matching reminder preserves whitespace and transcripts',
      (tester) async {
    final context = await _contextFor(tester);
    ReminderData.shared.reminders = [
      Reminder(reminderDate: DateTime(2050), reminderId: 1, noteId: 'other')
    ];
    String? copied;
    final completed = ShareHelper.shareNote(
      context,
      Note(id: 'note', description: '  Body\n', voiceMemos: [
        _memo('one', transcript: '\nTranscript  '),
        _memo('two', transcript: '')
      ]),
      ScreenshotController(),
      clipboardWriter: (text) async {
        copied = text;
      },
    );
    await _selectCopy(tester);
    await completed;
    expect(copied, '  Body\n\n\n\nTranscript  ');
    expect(find.text(S.current.Share_Text_Copied), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final (index, note) in [
    Note(),
    Note(title: ' \n', description: '\t'),
    Note(
        imagePaths: ['note_images/missing.jpg'], voiceMemos: [_memo('missing')])
  ].indexed) {
    _copyTestWidgets(
        'empty text case $index avoids clipboard writes even with unavailable attachments',
        (tester) async {
      final context = await _contextFor(tester);
      var writes = 0;
      var shares = 0;
      final completed = ShareHelper.shareNote(
        context,
        note,
        ScreenshotController(),
        clipboardWriter: (_) async {
          writes++;
        },
        share: (_) async {
          shares++;
          return ShareResult.unavailable;
        },
      );
      await _selectCopy(tester);
      await completed;
      expect(writes, 0);
      expect(shares, 0);
      expect(find.text(S.current.Share_No_Text), findsOneWidget);
      expect(find.text(S.current.Share_Text_Copied), findsNothing);
      expect(find.text(S.current.Share_Text_Copy_Failed), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  _copyTestWidgets(
      'clipboard failure is accurate and releases the busy guard for retry',
      (tester) async {
    final context = await _contextFor(tester);
    final note = Note(description: 'Copy me');
    var writes = 0;
    Future<void> writer(String _) async {
      writes++;
      if (writes == 1) throw PlatformException(code: 'clipboard_unavailable');
    }

    final first = ShareHelper.shareNote(context, note, ScreenshotController(),
        clipboardWriter: writer);
    await _selectCopy(tester);
    await first;
    expect(writes, 1);
    expect(find.text(S.current.Share_Text_Copy_Failed), findsOneWidget);
    expect(find.text(S.current.Share_Note_Failed), findsNothing);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    final retry = ShareHelper.shareNote(context, note, ScreenshotController(),
        clipboardWriter: writer);
    await _selectCopy(tester);
    await retry;
    expect(writes, 2);
    expect(find.text(S.current.Share_Text_Copied), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  _copyTestWidgets(
      'pending clipboard work prevents another menu and releases the guard on completion',
      (tester) async {
    final context = await _contextFor(tester);
    final pending = Completer<void>();
    final note = Note(description: 'Copy me');
    var writes = 0;
    Future<void> writer(String _) {
      writes++;
      return writes == 1 ? pending.future : Future.value();
    }

    final first = ShareHelper.shareNote(context, note, ScreenshotController(),
        clipboardWriter: writer);
    await _selectCopy(tester);
    expect(writes, 1);
    await ShareHelper.shareNote(context, note, ScreenshotController(),
        clipboardWriter: writer);
    await tester.pumpAndSettle();
    expect(find.byType(NoteShareSheet), findsNothing);
    expect(writes, 1);
    pending.complete();
    await tester.pumpAndSettle();
    await first;

    final again = ShareHelper.shareNote(context, note, ScreenshotController(),
        clipboardWriter: writer);
    await _selectCopy(tester);
    await again;
    expect(writes, 2);
    expect(find.text(S.current.Share_Text_Copied), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  _copyTestWidgets('repeated copy selection does not pop the underlying page',
      (tester) async {
    final context = await _contextFor(tester);
    final pending = Completer<void>();
    var writes = 0;
    final completed = ShareHelper.shareNote(
      context,
      Note(description: 'Copy me'),
      ScreenshotController(),
      clipboardWriter: (_) {
        writes++;
        return pending.future;
      },
    );
    await tester.pumpAndSettle();
    final copy = find.byKey(const ValueKey('note-share-copyText'));
    await tester.ensureVisible(copy);
    final action = tester.widget<NoteShareActionTile>(copy).onPressed!;
    action();
    action();
    await tester.pumpAndSettle();
    expect(writes, 1);
    expect(context.mounted, isTrue);
    expect(Navigator.of(context).canPop(), isFalse);
    pending.complete();
    await tester.pumpAndSettle();
    await completed;
    expect(find.text(S.current.Share_Text_Copied), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final fail in [false, true]) {
    _copyTestWidgets(
        'disposal during clipboard ${fail ? 'failure' : 'success'} avoids stale feedback and permits a fresh copy',
        (tester) async {
      final context = await _contextFor(tester);
      final pending = Completer<void>();
      final note = Note(description: 'Copy me');
      final first = ShareHelper.shareNote(context, note, ScreenshotController(),
          clipboardWriter: (_) => pending.future);
      await _selectCopy(tester);
      await tester.pumpWidget(const SizedBox.shrink());
      if (fail) {
        pending.completeError(StateError('Clipboard failed'));
      } else {
        pending.complete();
      }
      await tester.pumpAndSettle();
      await first;
      expect(find.byType(SnackBar), findsNothing);
      expect(tester.takeException(), isNull);

      final freshContext = await _contextFor(tester);
      var writes = 0;
      final fresh =
          ShareHelper.shareNote(freshContext, note, ScreenshotController(),
              clipboardWriter: (_) async {
        writes++;
      });
      await _selectCopy(tester);
      await fresh;
      expect(writes, 1);
      expect(find.text(S.current.Share_Text_Copied), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  _copyTestWidgets(
      'cancelling the picker avoids clipboard work and permits another action',
      (tester) async {
    final context = await _contextFor(tester);
    final note = Note(description: 'Copy me');
    var writes = 0;
    final first = ShareHelper.shareNote(context, note, ScreenshotController(),
        clipboardWriter: (_) async {
      writes++;
    });
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    await first;
    expect(writes, 0);
    expect(find.byType(SnackBar), findsNothing);

    final retry = ShareHelper.shareNote(context, note, ScreenshotController(),
        clipboardWriter: (_) async {
      writes++;
    });
    await _selectCopy(tester);
    await retry;
    expect(writes, 1);
    expect(tester.takeException(), isNull);
  });

  _copyTestWidgets(
      'the existing plain-text action still shares without touching the clipboard',
      (tester) async {
    final context = await _contextFor(tester);
    var writes = 0;
    ShareParams? params;
    final completed = ShareHelper.shareNote(
      context,
      Note(title: 'Tea', description: 'Body'),
      ScreenshotController(),
      clipboardWriter: (_) async {
        writes++;
      },
      share: (value) async {
        params = value;
        return ShareResult.unavailable;
      },
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(S.current.Share_Plain_Text));
    await tester.pumpAndSettle();
    await completed;
    expect(params!.text, 'Tea\n\nBody');
    expect(params!.files, isNull);
    expect(writes, 0);
    expect(find.text(S.current.Share_Text_Copied), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
