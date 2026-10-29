import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/Tools/shortcuts_append_launch.dart';
import 'package:onlynote/presentation/screens/settings/settings_screen.dart';
import 'package:onlynote/presentation/screens/settings/siri_shortcuts_screen.dart';
import 'package:onlynote/presentation/screens/settings/siri_shortcuts_previews.dart';
import 'package:onlynote/services/backup/backup_export_status.dart';
import 'package:onlynote/services/purchase_service.dart';
import '../support/interaction_feedback_capture.dart';

class _Status extends BackupExportStatusStore {
  @override
  Future<BackupExportRecord?> read() async => null;
}

class _Observer extends NavigatorObserver {
  var pushes = 0;
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pushes++;
    super.didPush(route, previousRoute);
  }
}

Future<void> _pump(WidgetTester tester, Widget home,
    {_Observer? observer, double scale = 1}) async {
  await tester.pumpWidget(RepaintBoundary(
      key: interactionFeedbackCaptureKey,
      child: MaterialApp(
        theme: interactionFeedbackTheme(dark: false),
        locale: const Locale('en'),
        supportedLocales: S.delegate.supportedLocales,
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate
        ],
        navigatorObservers: [if (observer != null) observer],
        builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
                disableAnimations: true, textScaler: TextScaler.linear(scale)),
            child: child!),
        home: home,
      )));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(loadInteractionFeedbackFonts);
  testWidgets('Siri guide pending notice and actions scroll at largest text',
      (tester) async {
    tester.view.physicalSize = const Size(320, 240);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final pending = ShortcutsAppendLaunch.instance.pending;
    final before = pending.value;
    addTearDown(() => pending.value = before);
    pending.value = [
      const ShortcutAppendRequest(
          id: '12345678-1234-1234-1234-000000000001',
          text: 'Retain this capture',
          destination: ShortcutAppendDestination.inbox,
          createdAt: 1793221200000)
    ];
    await _pump(tester, SiriShortcutsScreen(openShortcuts: () async => true),
        scale: 3.2);
    expect(tester.takeException(), isNull);
    await captureInteractionFeedback(tester, 'siri-pending-large-text');
    final open = find.byKey(const ValueKey('open-siri-shortcuts'));
    await tester.ensureVisible(open);
    await tester.pumpAndSettle();
    expect(open.hitTestable(), findsOneWidget);
    final review = find.byKey(const ValueKey('review-pending-shortcuts'));
    await tester.ensureVisible(review);
    await tester.pumpAndSettle();
    expect(review.hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  for (final action in ['import', 'shortcuts']) {
    testWidgets(
        'Settings $action route rejects duplicate, covered and disposed callbacks',
        (tester) async {
      final observer = _Observer();
      var built = 0;
      Widget marker(BuildContext context) {
        built++;
        return Scaffold(appBar: AppBar(), body: Text('$action destination'));
      }

      await _pump(
          tester,
          SettingsScreen(
              purchases: PurchaseService(isIOS: false),
              backupStatusStore: _Status(),
              markdownImportBuilder: marker,
              shortcutsBuilder: marker),
          observer: observer);
      final tile = find.byKey(ValueKey(action == 'import'
          ? 'settings-import-markdown'
          : 'settings-siri-shortcuts'));
      await tester.ensureVisible(tile);
      await tester.pumpAndSettle();
      final open = tester.widget<ListTile>(tile).onTap!;
      final context = tester.element(find.byType(SettingsScreen));
      unawaited(showDialog<void>(
          context: context,
          builder: (_) => const AlertDialog(title: Text('Covered'))));
      await tester.pumpAndSettle();
      final coveredPushes = observer.pushes;
      open();
      open();
      await tester.pumpAndSettle();
      expect(observer.pushes, coveredPushes);
      expect(built, 0);
      Navigator.pop(tester.element(find.byType(AlertDialog)));
      await tester.pumpAndSettle();
      final before = observer.pushes;
      open();
      open();
      await tester.pumpAndSettle();
      expect(observer.pushes, before + 1);
      expect(find.text('$action destination'), findsOneWidget);
      open();
      await tester.pumpAndSettle();
      expect(observer.pushes, before + 1);
      Navigator.pop(tester.element(find.text('$action destination')));
      await tester.pumpAndSettle();
      expect(find.byType(SettingsScreen), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      open();
      await tester.pump();
      expect(observer.pushes, before + 1);
      expect(tester.takeException(), isNull);
    }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));
  }

  testWidgets(
      'Siri guide rejects duplicate and covered launches and reports failed opens',
      (tester) async {
    var calls = 0;
    var pending = Completer<bool>();
    await _pump(tester, SiriShortcutsScreen(openShortcuts: () {
      calls++;
      return pending.future;
    }));
    final button = find.byKey(const ValueKey('open-siri-shortcuts'));
    await tester.ensureVisible(button);
    final open = tester.widget<FilledButton>(button).onPressed!;
    open();
    open();
    await tester.pump();
    expect(calls, 1);
    expect(tester.widget<FilledButton>(button).onPressed, isNull);
    final context = tester.element(find.byType(SiriShortcutsScreen));
    unawaited(showDialog<void>(
        context: context,
        builder: (_) => const AlertDialog(title: Text('Covered'))));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    pending.complete(false);
    await tester.pumpAndSettle();
    open();
    await tester.pump();
    expect(calls, 1);
    expect(find.text(S.current.Siri_Shortcuts_Open_Failed), findsNothing);
    Navigator.pop(tester.element(find.byType(AlertDialog)));
    await tester.pumpAndSettle();
    pending = Completer<bool>();
    open();
    open();
    await tester.pump();
    expect(calls, 2);
    pending.completeError(StateError('Unavailable'));
    await tester.pumpAndSettle();
    expect(find.text(S.current.Siri_Shortcuts_Open_Failed), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    pending = Completer<bool>();
    open();
    await tester.pump();
    expect(calls, 3);
    await tester.pumpWidget(const SizedBox.shrink());
    pending.complete(false);
    open();
    await tester.pump();
    expect(calls, 3);
    expect(tester.takeException(), isNull);
  });

  for (final (name, preview) in [
    ('light', siriShortcutsPreview),
    ('dark', siriShortcutsDarkPreview),
    ('large Chinese', siriShortcutsChinesePreview),
    ('pending accessibility', siriShortcutsPendingPreview),
  ]) {
    for (final size in [const Size(320, 390), const Size(390, 844)]) {
      testWidgets('Siri guide $name preview remains scrollable at $size',
          (tester) async {
        await tester.binding.setSurfaceSize(size);
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.pumpWidget(preview());
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester
            .ensureVisible(find.byKey(const ValueKey('open-siri-shortcuts')));
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('open-siri-shortcuts')).hitTestable(),
            findsOneWidget);
        await tester.tap(find.byKey(const ValueKey('open-siri-shortcuts')));
        await tester.pumpAndSettle();
        for (var index = 0; index < 8; index++) {
          await tester.drag(find.byKey(const ValueKey('siri-shortcuts-guide')),
              const Offset(0, -250));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        }
        expect(
            find.text(S.current.Siri_Shortcuts_Requirements), findsOneWidget);
        await tester.pumpWidget(const SizedBox.shrink());
      });
    }
  }
}
