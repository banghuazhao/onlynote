import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/screens/settings/keyboard_shortcuts_previews.dart';
import 'package:onlynote/presentation/screens/settings/keyboard_shortcuts_screen.dart';
import 'package:onlynote/presentation/screens/settings/settings_screen.dart';
import 'package:onlynote/presentation/theme/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/premium_test_fakes.dart';

const _settingsEntry = ValueKey('settings-keyboard-shortcuts');

Widget _host(
  Widget screen, {
  Locale locale = const Locale('en'),
  double scale = 1,
}) =>
    MaterialApp(
      theme: AppTheme.light,
      locale: locale,
      supportedLocales: S.delegate.supportedLocales,
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: screen,
    );

Future<void> _expectReadableShortcut(WidgetTester tester, String id) async {
  final row = find.byKey(ValueKey('keyboard-shortcut-$id'));
  await tester.ensureVisible(row);
  await tester.pumpAndSettle();
  final viewport =
      tester.getRect(find.byKey(const ValueKey('keyboard-shortcuts-list')));
  final rowRect = tester.getRect(row);
  expect(rowRect.overlaps(viewport), isTrue);
  expect(rowRect.left, greaterThanOrEqualTo(viewport.left));
  expect(rowRect.right, lessThanOrEqualTo(viewport.right));
  for (final element
      in find.descendant(of: row, matching: find.byType(Text)).evaluate()) {
    final paragraph = element.renderObject! as RenderParagraph;
    expect(paragraph.didExceedMaxLines, isFalse);
  }
  final keys = find.byKey(ValueKey('keyboard-shortcut-$id-keys'));
  await tester.ensureVisible(keys);
  await tester.pumpAndSettle();
  final keysRect = tester.getRect(keys);
  final visibleKeys = keysRect.intersect(viewport);
  expect(visibleKeys.width, closeTo(keysRect.width, 0.01));
  expect(visibleKeys.height, closeTo(keysRect.height, 0.01));
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('Settings offers shortcut help only on native macOS',
      (tester) async {
    final fixture = PremiumTestFixture(supported: false);
    await fixture.init();
    addTearDown(fixture.dispose);
    await tester
        .pumpWidget(_host(SettingsScreen(purchases: fixture.purchases)));
    await tester.pumpAndSettle();
    expect(
      find.byKey(_settingsEntry),
      !kIsWeb && defaultTargetPlatform == TargetPlatform.macOS
          ? findsOneWidget
          : findsNothing,
    );
    expect(tester.takeException(), isNull);
  }, variant: TargetPlatformVariant.all());

  testWidgets('Mac Settings opens and closes the keyboard shortcuts reference',
      (tester) async {
    final fixture = PremiumTestFixture(supported: false);
    await fixture.init();
    addTearDown(fixture.dispose);
    await tester
        .pumpWidget(_host(SettingsScreen(purchases: fixture.purchases)));
    await tester.pumpAndSettle();
    final entry = find.byKey(_settingsEntry);
    await tester.ensureVisible(entry);
    await tester.pumpAndSettle();
    await tester.tap(entry);
    await tester.pumpAndSettle();
    expect(find.byType(KeyboardShortcutsScreen), findsOneWidget);
    expect(
        find.text(S.current.Keyboard_Shortcuts_Find_Context), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(KeyboardShortcutsScreen), findsNothing);
    expect(find.byKey(_settingsEntry), findsOneWidget);
    expect(fixture.store.buyCalls, 0);
    expect(tester.takeException(), isNull);
  }, variant: TargetPlatformVariant.only(TargetPlatform.macOS), skip: kIsWeb);

  for (final locale in [
    const Locale('en'),
    const Locale('zh'),
    const Locale('zh', 'HK'),
  ]) {
    testWidgets('$locale reference localizes command labels and find context',
        (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        await tester
            .pumpWidget(_host(const KeyboardShortcutsScreen(), locale: locale));
        await tester.pumpAndSettle();
        expect(find.text(S.current.Keyboard_Shortcuts), findsOneWidget);
        expect(find.text(S.current.Keyboard_Shortcuts_Description),
            findsOneWidget);
        expect(find.text(S.current.Keyboard_Shortcuts_Find_Context),
            findsOneWidget);
        expect(find.text(S.current.Desktop_Menu_New_Note), findsOneWidget);
        expect(find.text(S.current.Note_Undo), findsOneWidget);
        expect(find.text(S.current.Note_Redo), findsOneWidget);
        final material = MaterialLocalizations.of(
            tester.element(find.byType(KeyboardShortcutsScreen)));
        expect(find.text(material.copyButtonLabel), findsOneWidget);
        expect(find.text(material.pasteButtonLabel), findsOneWidget);
        final redo = tester
            .getSemantics(find.byKey(const ValueKey('keyboard-shortcut-redo')));
        expect(redo.label, contains(material.keyboardKeyMetaMacOs));
        expect(redo.label, contains(material.keyboardKeyShift));
        expect(tester.takeException(), isNull);
      } finally {
        semantics.dispose();
      }
    });
  }

  testWidgets('reference stays readable and scrollable with narrow large text',
      (tester) async {
    tester.view.physicalSize = const Size(280, 500);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    for (final locale in [const Locale('en'), const Locale('zh', 'HK')]) {
      await tester.pumpWidget(
          _host(const KeyboardShortcutsScreen(), locale: locale, scale: 2));
      await tester.pumpAndSettle();
      final title = find.byKey(const ValueKey('keyboard-shortcuts-title'));
      final titleRect = tester.getRect(title);
      final appBarRect = tester.getRect(find.byType(AppBar));
      expect(titleRect.top, greaterThanOrEqualTo(appBarRect.top));
      expect(titleRect.bottom, lessThanOrEqualTo(appBarRect.bottom));
      expect(tester.renderObject<RenderParagraph>(title).didExceedMaxLines,
          isFalse);
      for (final id in ['new-note', 'find', 'settings', 'redo', 'select-all']) {
        await _expectReadableShortcut(tester, id);
        expect(tester.takeException(), isNull);
      }
    }
  });

  testWidgets('shortcut previews render without platform commands or plugins',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    for (final (preview, size) in [
      (keyboardShortcutsPreview, const Size(1000, 760)),
      (keyboardShortcutsDarkPreview, const Size(1000, 760)),
      (keyboardShortcutsChinesePreview, const Size(280, 600)),
    ]) {
      tester.view.physicalSize = size;
      await tester.pumpWidget(preview());
      await tester.pumpAndSettle();
      await _expectReadableShortcut(tester, 'select-all');
      expect(find.byType(PlatformMenuBar), findsNothing);
      expect(tester.takeException(), isNull);
    }
  });
}
