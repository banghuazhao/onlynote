import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/app_sheet.dart';
import 'package:onlynote/presentation/components/shortcut_append_review_sheet.dart';
import 'package:onlynote/presentation/theme/theme.dart';
import 'package:onlynote/services/shortcuts_append.dart';

const _id = '00000000-0000-4000-8000-000000000001';
const _otherId = '00000000-0000-4000-8000-000000000002';
ShortcutAppendRequest _request(
        {String id = _id,
        String text = 'Keep this exact text\n第二行 👩🏽‍💻',
        ShortcutAppendDestination destination =
            ShortcutAppendDestination.note}) =>
    ShortcutAppendRequest(
        id: id,
        text: text,
        destination: destination,
        createdAt: 1793221200000,
        noteId: destination == ShortcutAppendDestination.note ? 'note' : null);

class _SheetHost {
  var closed = 0;
  var retries = 0;
}

Future<_SheetHost> _open(
    WidgetTester tester, ValueNotifier<List<ShortcutAppendRequest>> pending,
    {Future<void> Function(String)? copy,
    Future<void> Function(String)? discard,
    Size size = const Size(390, 844),
    double scale = 1,
    bool dark = false,
    Locale locale = const Locale('en')}) async {
  final host = _SheetHost();
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(MaterialApp(
    theme: dark ? AppTheme.dark : AppTheme.light,
    locale: locale,
    supportedLocales: S.delegate.supportedLocales,
    localizationsDelegates: const [
      S.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate
    ],
    builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(scale), disableAnimations: true),
        child: child!),
    home: Scaffold(
        body: Builder(
            builder: (context) => TextButton(
                child: const Text('Open review'),
                onPressed: () async {
                  await showAppSheet<void>(
                      context: context,
                      builder: (_) => ShortcutAppendReviewSheet(
                          pending: pending,
                          onDiscard: discard ?? (_) async {},
                          onRetry: () => host.retries++,
                          noteTitle: (_) => 'Shopping note',
                          copyText: copy));
                  host.closed++;
                }))),
  ));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Open review'));
  await tester.pumpAndSettle();
  return host;
}

Future<VoidCallback> _button(WidgetTester tester, String key) async {
  final finder = find.byKey(ValueKey(key));
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  final widget = tester.widget<ButtonStyleButton>(finder);
  return widget.onPressed!;
}

Future<void> _finishFeedback(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 5));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
      'Copy preserves full pending payload and duplicate copies write once',
      (tester) async {
    final payload =
        '  A full paragraph\r\n${'Preserve every line.\n' * 20}结尾 👩🏽‍💻  ';
    final request = _request(text: payload);
    final pending = ValueNotifier([request]);
    addTearDown(pending.dispose);
    final copied = <String>[];
    final gate = Completer<void>();
    var discards = 0;
    final host = await _open(tester, pending, copy: (text) async {
      copied.add(text);
      await gate.future;
    }, discard: (_) async {
      discards++;
    });
    expect(find.text('Shopping note'), findsOneWidget);
    final before = request.toMap();
    final copy = await _button(tester, 'copy-shortcut-$_id');
    copy();
    copy();
    await tester.pump();
    expect(copied, [payload]);
    expect(
        tester
            .widget<OutlinedButton>(
                find.byKey(const ValueKey('copy-shortcut-$_id')))
            .onPressed,
        isNull);
    gate.complete();
    await tester.pumpAndSettle();
    expect(pending.value.single, same(request));
    expect(pending.value.single.toMap(), before);
    expect(discards, 0);
    expect(host.closed, 0);
    await _finishFeedback(tester);
    await tester.pumpWidget(const SizedBox.shrink());
    copy();
    await tester.pump();
    expect(copied, [payload]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('failed Copy retains request and can copy again', (tester) async {
    final request = _request();
    final pending = ValueNotifier([request]);
    addTearDown(pending.dispose);
    var fail = true;
    final copies = <String>[];
    await _open(tester, pending, copy: (text) async {
      if (fail) throw StateError('Clipboard unavailable');
      copies.add(text);
    });
    (await _button(tester, 'copy-shortcut-$_id'))();
    await tester.pumpAndSettle();
    expect(find.text(S.current.Share_Text_Copy_Failed), findsOneWidget);
    expect(pending.value.single, same(request));
    await _finishFeedback(tester);
    fail = false;
    (await _button(tester, 'copy-shortcut-$_id'))();
    await tester.pumpAndSettle();
    expect(copies, [request.text]);
    expect(pending.value.single, same(request));
    await _finishFeedback(tester);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
      'Discard failure keeps pending text and retry removes only intended request',
      (tester) async {
    final first = _request();
    final other =
        _request(id: _otherId, destination: ShortcutAppendDestination.today);
    final pending = ValueNotifier([first, other]);
    addTearDown(pending.dispose);
    var failed = true;
    final gate = Completer<void>();
    final discarded = <String>[];
    final host = await _open(tester, pending, discard: (id) async {
      discarded.add(id);
      await gate.future;
      if (failed) throw StateError('Storage unavailable');
      pending.value = pending.value.where((value) => value.id != id).toList();
    });
    final discard = await _button(tester, 'discard-shortcut-$_id');
    discard();
    discard();
    await tester.pump();
    expect(discarded, [_id]);
    gate.complete();
    await tester.pumpAndSettle();
    expect(
        find.text(S.current.Shortcuts_Request_Discard_Failed), findsOneWidget);
    expect(pending.value, [first, other]);
    expect(host.closed, 0);
    await _finishFeedback(tester);
    failed = false;
    discard();
    await tester.pumpAndSettle();
    expect(discarded, [_id, _id]);
    expect(pending.value, [other]);
    discard();
    await tester.pump();
    expect(discarded, [_id, _id]);
    await tester.pumpWidget(const SizedBox.shrink());
    discard();
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'covered and removed requests reject copy, discard and Retry callbacks',
      (tester) async {
    final request = _request();
    final pending = ValueNotifier([request]);
    addTearDown(pending.dispose);
    var copies = 0;
    var discards = 0;
    final host = await _open(tester, pending, copy: (_) async {
      copies++;
    }, discard: (_) async {
      discards++;
    });
    final copy = await _button(tester, 'copy-shortcut-$_id');
    final discard = await _button(tester, 'discard-shortcut-$_id');
    final retry = await _button(tester, 'retry-shortcut-requests');
    unawaited(showDialog<void>(
        context: tester.element(find.byType(ShortcutAppendReviewSheet)),
        builder: (_) => const AlertDialog(title: Text('Covered'))));
    await tester.pumpAndSettle();
    copy();
    discard();
    retry();
    await tester.pumpAndSettle();
    expect(copies, 0);
    expect(discards, 0);
    expect(host.closed, 0);
    expect(host.retries, 0);
    Navigator.pop(tester.element(find.byType(AlertDialog)));
    await tester.pumpAndSettle();
    pending.value = [];
    await tester.pumpAndSettle();
    copy();
    discard();
    retry();
    await tester.pump();
    expect(host.closed, 0);
    expect(host.retries, 0);
    expect(find.text(S.current.Shortcuts_Request_Empty), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    copy();
    discard();
    retry();
    await tester.pump();
    expect(copies, 0);
    expect(discards, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Retry closes review once and retries once after dismissal',
      (tester) async {
    final pending = ValueNotifier([_request()]);
    addTearDown(pending.dispose);
    final host = await _open(tester, pending);
    final retry = await _button(tester, 'retry-shortcut-requests');
    retry();
    retry();
    await tester.pumpAndSettle();
    retry();
    await tester.pump();
    expect(host.closed, 1);
    expect(host.retries, 1);
    expect(find.text('Open review'), findsOneWidget);
    expect(pending.value, hasLength(1));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'pending Copy completion after disposal has no sheet side effects',
      (tester) async {
    final pending = ValueNotifier([_request()]);
    addTearDown(pending.dispose);
    final gate = Completer<void>();
    final copied = <String>[];
    final host = await _open(tester, pending, copy: (text) async {
      copied.add(text);
      await gate.future;
    });
    final copy = await _button(tester, 'copy-shortcut-$_id');
    copy();
    await tester.pump();
    await tester.pumpWidget(const SizedBox.shrink());
    gate.complete();
    copy();
    await tester.pump();
    expect(copied, [pending.value.single.text]);
    expect(host.retries, 0);
    expect(tester.takeException(), isNull);
  });

  for (final dark in [false, true]) {
    testWidgets(
        'review scrolls full Chinese payload and actions at3.2x dark=$dark',
        (tester) async {
      final request = _request(text: '${'这是保留的完整文字。\n' * 12}最后一行');
      final pending = ValueNotifier([request]);
      addTearDown(pending.dispose);
      final copied = <String>[];
      await _open(tester, pending, copy: (text) async {
        copied.add(text);
      },
          size: const Size(320, 390),
          scale: 3.2,
          dark: dark,
          locale: const Locale('zh', 'HK'));
      final copy = await _button(tester, 'copy-shortcut-$_id');
      expect(find.byKey(const ValueKey('copy-shortcut-$_id')).hitTestable(),
          findsOneWidget);
      copy();
      await tester.pumpAndSettle();
      expect(copied, [request.text]);
      expect(tester.takeException(), isNull);
      await _finishFeedback(tester);
      final retry = await _button(tester, 'retry-shortcut-requests');
      retry();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
