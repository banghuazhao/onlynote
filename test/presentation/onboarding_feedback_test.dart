import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/routes/routes.dart';
import 'package:onlynote/presentation/screens/onboarding/onboarding_content.dart';
import 'package:onlynote/presentation/screens/onboarding/onboarding_screen.dart';
import 'package:onlynote/presentation/screens/onboarding/onboarding_previews.dart';
import 'package:onlynote/presentation/theme/theme.dart';

import '../support/interaction_feedback_capture.dart';

class _Router extends RootStackRouter {
  _Router(this.complete);
  final Future<void> Function() complete;

  @override
  List<AutoRoute> get routes => [
        AutoRoute(
            initial: true,
            page: PageInfo(OnboardingRoute.name,
                builder: (_) =>
                    OnboardingScreen(completeOnboarding: complete))),
        AutoRoute(
            page: PageInfo(HomeRoute.name,
                builder: (_) => const Scaffold(body: Text('Library')))),
        AutoRoute(
            page: PageInfo(AddUpdateNoteRoute.name, builder: (data) {
          final args = data.argsAs<AddUpdateNoteRouteArgs>();
          return Scaffold(body: Text('Editor ${args.start.name}'));
        })),
      ];
}

Widget _app(_Router router) => MaterialApp.router(
      routerConfig: router.config(),
      theme: AppTheme.light,
      locale: const Locale('en'),
      supportedLocales: S.delegate.supportedLocales,
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate
      ],
      builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: child!),
    );

Future<_Router> _open(
    WidgetTester tester, Future<void> Function() complete) async {
  final router = _Router(complete);
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    router.dispose();
  });
  await tester.pumpWidget(_app(router));
  await tester.pumpAndSettle();
  return router;
}

Finder _key(String name) => find.byKey(ValueKey(name));

void main() {
  setUpAll(loadInteractionFeedbackFonts);
  testWidgets(
      'pending start is announced and duplicate callbacks complete once',
      (tester) async {
    final pending = Completer<void>();
    var attempts = 0;
    final router = await _open(tester, () {
      attempts++;
      return pending.future;
    });
    final callback =
        tester.widget<FilledButton>(_key('onboarding-write-note')).onPressed!;
    callback();
    callback();
    await tester.pumpAndSettle();
    expect(attempts, 1);
    expect(tester.widget<FilledButton>(_key('onboarding-write-note')).onPressed,
        isNull);
    expect(
        tester.widget<OutlinedButton>(_key('onboarding-checklist')).onPressed,
        isNull);
    expect(
        tester.widget<TextButton>(_key('onboarding-skip')).onPressed, isNull);
    final semantics = tester.ensureSemantics();
    try {
      await tester.pump();
      final data =
          tester.getSemantics(_key('onboarding-starting')).getSemanticsData();
      expect(data.label, S.current.Onboarding_Starting);
      expect(data.flagsCollection.isLiveRegion, isTrue);
    } finally {
      semantics.dispose();
    }
    expect(router.current.name, OnboardingRoute.name);
    pending.complete();
    await tester.pumpAndSettle();
    expect(router.stackData.map((route) => route.name),
        [HomeRoute.name, AddUpdateNoteRoute.name]);
    expect(find.text('Editor quickNote'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final (key, editor) in [
    ('onboarding-skip', null),
    ('onboarding-write-note', 'quickNote'),
    ('onboarding-checklist', 'checklist'),
  ]) {
    testWidgets(
        '$key failure recovers and retry preserves the intended destination',
        (tester) async {
      var attempts = 0;
      final router = await _open(tester, () async {
        if (attempts++ == 0) throw StateError('Preferences unavailable');
      });
      await tester.tap(_key(key));
      await tester.pumpAndSettle();
      expect(find.text(S.current.Onboarding_Start_Failed), findsOneWidget);
      expect(_key('onboarding-starting'), findsNothing);
      expect(router.current.name, OnboardingRoute.name);
      expect(
          tester.widget<FilledButton>(_key('onboarding-write-note')).onPressed,
          isNotNull);
      expect(
          tester.widget<OutlinedButton>(_key('onboarding-checklist')).onPressed,
          isNotNull);
      expect(tester.widget<TextButton>(_key('onboarding-skip')).onPressed,
          isNotNull);
      await tester.tap(_key('onboarding-retry'));
      await tester.pumpAndSettle();
      expect(attempts, 2);
      expect(router.stackData.map((route) => route.name),
          [HomeRoute.name, if (editor != null) AddUpdateNoteRoute.name]);
      expect(find.text(editor == null ? 'Library' : 'Editor $editor'),
          findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  for (final fail in [false, true]) {
    testWidgets('late ${fail ? 'failure' : 'success'} after disposal is safe',
        (tester) async {
      final pending = Completer<void>();
      await _open(tester, () => pending.future);
      await tester.tap(_key('onboarding-write-note'));
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox.shrink());
      if (fail) {
        pending.completeError(StateError('Unavailable'));
      } else {
        pending.complete();
      }
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
      'pending completion does not replace a route opened over onboarding',
      (tester) async {
    final pending = Completer<void>();
    final router = await _open(tester, () => pending.future);
    await tester.tap(_key('onboarding-checklist'));
    await tester.pumpAndSettle();
    final context = tester.element(find.byType(OnboardingScreen));
    unawaited(Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: Text('Another route')))));
    await tester.pumpAndSettle();
    pending.complete();
    await tester.pumpAndSettle();
    expect(find.text('Another route'), findsOneWidget);
    expect(router.stackData.map((route) => route.name), [OnboardingRoute.name]);
    Navigator.of(tester.element(find.text('Another route'))).pop();
    await tester.pumpAndSettle();
    expect(
        tester.widget<OutlinedButton>(_key('onboarding-checklist')).onPressed,
        isNotNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'onboarding feedback previews fit narrow, landscape and large text',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    for (final (preview, size, name) in [
      (onboardingReadyPreview, const Size(375, 740), 'onboarding-ready'),
      (onboardingPendingPreview, const Size(375, 740), 'onboarding-pending'),
      (
        onboardingRetryDarkPreview,
        const Size(740, 320),
        'onboarding-retry-dark-landscape'
      ),
      (
        onboardingRetryChinesePreview,
        const Size(280, 640),
        'onboarding-retry-chinese'
      ),
    ]) {
      tester.view.physicalSize = size;
      await tester.pumpWidget(KeyedSubtree(
          key: ValueKey(name),
          child: RepaintBoundary(
              key: interactionFeedbackCaptureKey,
              child: preview(
                  theme:
                      interactionFeedbackTheme(dark: name.contains('dark'))))));
      await tester.pumpAndSettle();
      final content =
          tester.widget<OnboardingContent>(find.byType(OnboardingContent));
      expect(content.starting, name == 'onboarding-pending');
      expect(content.failed, name.contains('retry'));
      await tester.ensureVisible(_key('onboarding-checklist'));
      await tester.pumpAndSettle();
      expect(tester.getSize(_key('onboarding-checklist')).height,
          greaterThanOrEqualTo(48));
      await captureInteractionFeedback(tester, name);
      if (content.failed) {
        final retry = _key('onboarding-retry');
        await tester.ensureVisible(retry);
        await tester.tap(retry);
        await tester.pump();
        expect(_key('onboarding-starting'), findsOneWidget);
        await tester.pump(const Duration(milliseconds: 800));
        await tester.pumpAndSettle();
        expect(_key('onboarding-start-error'), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    }
  });
}
