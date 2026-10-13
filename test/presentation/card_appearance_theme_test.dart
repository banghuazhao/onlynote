import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:onlynote/Tools/app_appearance_settings.dart';
import 'package:onlynote/Tools/app_card_style_settings.dart';
import 'package:onlynote/Tools/app_layout_settings.dart';
import 'package:onlynote/Tools/app_typography_settings.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/domain/model/note_card_style.dart';
import 'package:onlynote/domain/model/note_theme.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/note_theme_choices.dart';
import 'package:onlynote/presentation/components/note_theme_surface.dart';
import 'package:onlynote/presentation/components/paper_note.dart';
import 'package:onlynote/presentation/screens/card_appearance/card_appearance_screen.dart';
import 'package:onlynote/presentation/screens/home/widgets/note_card.dart';
import 'package:onlynote/presentation/screens/settings/premium_screen.dart';
import 'package:onlynote/presentation/theme/theme.dart';
import 'package:onlynote/services/premium_access.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/premium_test_fakes.dart';

Finder get _save => find.byKey(const ValueKey('card-style-save'));
Finder _theme(NoteTheme? theme) =>
    find.byKey(ValueKey('note-theme-choice-${theme?.name ?? "default"}'));
Finder get _controls => find.descendant(
    of: find.byKey(const ValueKey('card-style-controls')),
    matching: find.byType(Scrollable));

Future<void> _selectSection(WidgetTester tester, String section) async {
  final target = find.byKey(ValueKey('card-style-section-$section'));
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target.hitTestable());
  await tester.pumpAndSettle();
}

Note _note({NoteCardStyle style = const NoteCardStyle()}) => Note(
      id: 'theme-note',
      title: 'Planning',
      description: 'Keep the original body and appearance overrides.',
      dateTime: DateTime.utc(2026, 10, 13),
      cardStyle: style,
      color: const Color(0xFFD3EDE4),
    );

Future<void> _open(WidgetTester tester, CardAppearanceScreen screen) async {
  await tester.pumpWidget(MaterialApp(
    theme: AppTheme.light,
    supportedLocales: S.delegate.supportedLocales,
    localizationsDelegates: const [
      S.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: Builder(
      builder: (context) => Scaffold(
        body: TextButton(
          onPressed: () => Navigator.of(context)
              .push(MaterialPageRoute<void>(builder: (_) => screen)),
          child: const Text('Open'),
        ),
      ),
    ),
  ));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
}

Future<void> _tapControl(WidgetTester tester, Finder target) async {
  if (target.evaluate().isEmpty) {
    tester.state<ScrollableState>(_controls).position.jumpTo(0);
    await tester.pump();
  }
  if (target.evaluate().isNotEmpty) {
    await tester.ensureVisible(target);
  } else {
    await tester.scrollUntilVisible(target, 160, scrollable: _controls);
  }
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}

Future<void> _dispose(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(seconds: 6));
  await tester.pumpAndSettle();
}

void main() {
  final fonts = Map<String, GoogleFontBuilder>.of(kAppFontFamilies);
  setUpAll(initializeDateFormatting);
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AppTypographySettings.instance.load();
    await AppLayoutSettings.instance.load();
    await AppAppearanceSettings.instance.load();
    await AppCardStyleSettings.instance.load();
    for (final family in fonts.keys) {
      kAppFontFamilies[family] = (
              {textStyle, color, fontSize, fontWeight, fontStyle}) =>
          (textStyle ?? const TextStyle()).copyWith(
              fontFamily: family,
              color: color,
              fontSize: fontSize,
              fontWeight: fontWeight,
              fontStyle: fontStyle);
    }
  });
  tearDown(() => kAppFontFamilies.addAll(fonts));

  testWidgets(
      'every free theme saves without upgrading and retains custom fields',
      (tester) async {
    final fixture = PremiumTestFixture();
    await fixture.init();
    try {
      const before = NoteCardStyle(
          fontFamily: 'Roboto', fontSize: AppFontSize.small, showDate: false);
      final original = _note(style: before);
      for (final theme in NoteTheme.values.where((theme) => !theme.isPremium)) {
        NoteCardStyle? saved;
        Color? savedColor;
        var calls = 0;
        await _open(
            tester,
            CardAppearanceScreen(
              note: original,
              premiumAccess: fixture.access,
              onSaveAppearance: (style, color) async {
                calls++;
                saved = style;
                savedColor = color;
              },
            ));
        await _tapControl(tester, _theme(theme));
        expect(saved, isNull);
        expect(original.cardStyle, before);
        expect(
            tester.widget<NoteCard>(find.byType(NoteCard)).cardStyle!.noteTheme,
            theme);
        await tester.tap(_save);
        await tester.pumpAndSettle();
        expect(saved, before.copyWith(noteTheme: theme));
        expect(savedColor, original.color);
        expect(calls, 1);
        expect(find.byType(PremiumScreen), findsNothing);
        expect(find.byType(CardAppearanceScreen), findsNothing);
        expect(fixture.store.buyCalls, 0);
        expect(tester.takeException(), isNull);
        await _dispose(tester);
      }
    } finally {
      await _dispose(tester);
      await fixture.dispose();
    }
  });

  testWidgets(
      'per-note inheritance and explicit Classic preserve their distinct values',
      (tester) async {
    final fixture = PremiumTestFixture();
    await fixture.init();
    try {
      await AppCardStyleSettings.instance.saveDefaults(
          const NoteCardStyle(noteTheme: NoteTheme.gridPaper),
          premiumAccess: fixture.access);
      for (final theme in [null, NoteTheme.classic]) {
        NoteCardStyle? saved;
        await _open(
            tester,
            CardAppearanceScreen(
              note: _note(
                  style: const NoteCardStyle(noteTheme: NoteTheme.parchment)),
              premiumAccess: fixture.access,
              onSave: (style) async => saved = style,
            ));
        await _tapControl(tester, _theme(theme));
        expect(
            tester.widget<NoteCard>(find.byType(NoteCard)).cardStyle!.noteTheme,
            theme ?? NoteTheme.gridPaper);
        await tester.tap(_save);
        await tester.pumpAndSettle();
        expect(saved!.noteTheme, theme);
        expect(find.byType(PremiumScreen), findsNothing);
        expect(fixture.store.buyCalls, 0);
        await _dispose(tester);
      }
      expect(tester.takeException(), isNull);
    } finally {
      await _dispose(tester);
      await fixture.dispose();
    }
  });

  testWidgets(
      'default color swatch follows the selected theme without storing a color',
      (tester) async {
    NoteCardStyle? saved;
    Color? savedColor = Colors.black;
    try {
      await _open(
          tester,
          CardAppearanceScreen(
            note: _note(),
            onSaveAppearance: (style, color) async {
              saved = style;
              savedColor = color;
            },
          ));
      final defaultColor =
          find.byKey(const ValueKey('card-style-color-default'));
      for (final theme in [
        NoteTheme.classic,
        NoteTheme.legalPad,
        NoteTheme.gridPaper
      ]) {
        await _selectSection(tester, 'theme');
        await _tapControl(tester, _theme(theme));
        await _selectSection(tester, 'color');
        await _tapControl(tester, defaultColor);
        final swatch = tester.widget<IconButton>(find.descendant(
            of: defaultColor, matching: find.byType(IconButton)));
        expect(swatch.style!.backgroundColor!.resolve({}),
            noteThemePaperColor(theme));
        expect(tester.widget<PaperNote>(find.byType(PaperNote)).color,
            noteThemePaperColor(theme));
        expect(
            tester.widget<NoteCard>(find.byType(NoteCard)).note.color, isNull);
        expect(saved, isNull);
      }
      await tester.tap(_save);
      await tester.pumpAndSettle();
      expect(saved!.noteTheme, NoteTheme.gridPaper);
      expect(savedColor, isNull);
      expect(tester.takeException(), isNull);
    } finally {
      await _dispose(tester);
    }
  });

  testWidgets(
      'global Premium preview cancellation leaves defaults intact and reset uses Classic',
      (tester) async {
    final fixture = PremiumTestFixture();
    await fixture.init();
    try {
      await _open(tester, CardAppearanceScreen(premiumAccess: fixture.access));
      await _tapControl(tester, _theme(NoteTheme.kraftNotebook));
      expect(
          AppCardStyleSettings.instance.defaults.noteTheme, NoteTheme.classic);
      await tester.tap(_save);
      await tester.pumpAndSettle();
      expect(tester.widget<PremiumScreen>(find.byType(PremiumScreen)).feature,
          PremiumFeature.noteThemes);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(
          AppCardStyleSettings.instance.defaults.noteTheme, NoteTheme.classic);
      expect(
          (await SharedPreferences.getInstance()).getString('app_note_theme'),
          isNull);
      expect(
          tester.widget<NoteCard>(find.byType(NoteCard)).cardStyle!.noteTheme,
          NoteTheme.kraftNotebook);
      await _tapControl(tester, _theme(NoteTheme.sticky));
      await tester.tap(_save);
      await tester.pumpAndSettle();
      expect(
          AppCardStyleSettings.instance.defaults.noteTheme, NoteTheme.sticky);
      expect(
          (await SharedPreferences.getInstance()).getString('app_note_theme'),
          NoteTheme.sticky.name);
      expect(fixture.store.buyCalls, 0);
      await _dispose(tester);
      await _open(tester, CardAppearanceScreen(premiumAccess: fixture.access));
      await _tapControl(tester, find.byKey(const ValueKey('card-style-reset')));
      await tester.tap(_save);
      await tester.pumpAndSettle();
      expect(
          AppCardStyleSettings.instance.defaults.noteTheme, NoteTheme.classic);
      expect(tester.takeException(), isNull);
    } finally {
      await _dispose(tester);
      await fixture.dispose();
    }
  });

  testWidgets('buying Premium resumes a staged theme save once',
      (tester) async {
    final fixture = PremiumTestFixture();
    await fixture.init();
    try {
      NoteCardStyle? saved;
      var calls = 0;
      await _open(
          tester,
          CardAppearanceScreen(
            note: _note(),
            premiumAccess: fixture.access,
            onSave: (style) async {
              calls++;
              saved = style;
            },
          ));
      await _tapControl(tester, _theme(NoteTheme.dottedJournal));
      await tester.tap(_save);
      await tester.pumpAndSettle();
      expect(saved, isNull);
      final buy = find.byKey(const ValueKey('premium-buy'));
      await tester.ensureVisible(buy);
      await tester.pumpAndSettle();
      await tester.tap(buy);
      await tester.pumpAndSettle();
      expect(fixture.access.isPremium, isTrue);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(saved!.noteTheme, NoteTheme.dottedJournal);
      expect(calls, 1);
      expect(find.byType(CardAppearanceScreen), findsNothing);
      expect(fixture.store.buyCalls, 1);
      expect(tester.takeException(), isNull);
    } finally {
      await _dispose(tester);
      await fixture.dispose();
    }
  });

  testWidgets(
      'Premium customers save every advanced global theme through settings',
      (tester) async {
    final fixture = PremiumTestFixture(premium: true);
    await fixture.init();
    try {
      for (final theme in NoteTheme.values.where((theme) => theme.isPremium)) {
        await _open(
            tester, CardAppearanceScreen(premiumAccess: fixture.access));
        await _tapControl(tester, _theme(theme));
        await tester.tap(_save);
        await tester.pumpAndSettle();
        expect(AppCardStyleSettings.instance.defaults.noteTheme, theme);
        expect(
            (await SharedPreferences.getInstance()).getString('app_note_theme'),
            theme.name);
        expect(find.byType(PremiumScreen), findsNothing);
        expect(find.byType(CardAppearanceScreen), findsNothing);
        expect(fixture.store.buyCalls, 0);
        expect(tester.takeException(), isNull);
        await _dispose(tester);
      }
    } finally {
      await _dispose(tester);
      await fixture.dispose();
    }
  });

  testWidgets('discarding a locally selected theme never invokes persistence',
      (tester) async {
    var saves = 0;
    await _open(tester,
        CardAppearanceScreen(note: _note(), onSave: (_) async => saves++));
    try {
      await _tapControl(tester, _theme(NoteTheme.legalPad));
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text(S.current.Card_Style_Discard_Title), findsOneWidget);
      await tester.tap(find.text(S.current.Cancel));
      await tester.pumpAndSettle();
      expect(find.byType(CardAppearanceScreen), findsOneWidget);
      expect(
          tester.widget<NoteCard>(find.byType(NoteCard)).cardStyle!.noteTheme,
          NoteTheme.legalPad);
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.text(S.current.Card_Style_Discard));
      await tester.pumpAndSettle();
      expect(find.byType(CardAppearanceScreen), findsNothing);
      expect(saves, 0);
      expect(tester.takeException(), isNull);
    } finally {
      await _dispose(tester);
    }
  });

  testWidgets(
      'failed theme save keeps its preview and allows one successful retry',
      (tester) async {
    final fixture = PremiumTestFixture(premium: true);
    await fixture.init();
    try {
      NoteCardStyle? saved;
      var attempts = 0;
      await _open(
          tester,
          CardAppearanceScreen(
            note: _note(),
            premiumAccess: fixture.access,
            onSave: (style) async {
              attempts++;
              if (attempts == 1) throw StateError('Persistence failed');
              saved = style;
            },
          ));
      await _tapControl(tester, _theme(NoteTheme.parchment));
      await tester.tap(_save);
      await tester.pumpAndSettle();
      expect(attempts, 1);
      expect(saved, isNull);
      expect(find.byType(CardAppearanceScreen), findsOneWidget);
      expect(
          tester
              .widget<NoteThemeChoices>(find.byType(NoteThemeChoices))
              .enabled,
          isTrue);
      expect(
          tester.widget<NoteCard>(find.byType(NoteCard)).cardStyle!.noteTheme,
          NoteTheme.parchment);
      await tester.tap(_save);
      await tester.pumpAndSettle();
      expect(attempts, 2);
      expect(saved!.noteTheme, NoteTheme.parchment);
      expect(find.byType(CardAppearanceScreen), findsNothing);
      expect(tester.takeException(), isNull);
    } finally {
      await _dispose(tester);
      await fixture.dispose();
    }
  });

  testWidgets(
      'pending save blocks duplicate and stale actions through disposal',
      (tester) async {
    final gate = Completer<void>();
    var attempts = 0;
    try {
      await _open(
          tester,
          CardAppearanceScreen(
            note: _note(),
            onSave: (_) async {
              attempts++;
              await gate.future;
            },
          ));
      await _tapControl(tester, _theme(NoteTheme.sticky));
      final saveCallback = tester.widget<TextButton>(_save).onPressed!;
      final themeCallback = tester
          .widget<InkWell>(find.descendant(
              of: _theme(NoteTheme.classic), matching: find.byType(InkWell)))
          .onTap!;
      await tester.tap(_save);
      await tester.pump();
      expect(attempts, 1);
      expect(tester.widget<TextButton>(_save).onPressed, isNull);
      expect(
          tester
              .widget<NoteThemeChoices>(find.byType(NoteThemeChoices))
              .enabled,
          isFalse);
      saveCallback();
      themeCallback();
      await tester.pump();
      expect(attempts, 1);
      expect(
          tester.widget<NoteCard>(find.byType(NoteCard)).cardStyle!.noteTheme,
          NoteTheme.sticky);
      await tester.pumpWidget(const SizedBox.shrink());
      saveCallback();
      themeCallback();
      expect(attempts, 1);
      gate.complete();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    } finally {
      if (!gate.isCompleted) gate.complete();
      await _dispose(tester);
    }
  });

  testWidgets('covered appearance actions cannot save through a discard dialog',
      (tester) async {
    var saves = 0;
    try {
      await _open(tester,
          CardAppearanceScreen(note: _note(), onSave: (_) async => saves++));
      await _tapControl(tester, _theme(NoteTheme.sticky));
      final saveCallback = tester.widget<TextButton>(_save).onPressed!;
      final themeCallback = tester
          .widget<InkWell>(find.descendant(
              of: _theme(NoteTheme.classic), matching: find.byType(InkWell)))
          .onTap!;
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text(S.current.Card_Style_Discard_Title), findsOneWidget);
      saveCallback();
      themeCallback();
      await tester.pump();
      expect(saves, 0);
      await tester.tap(find.text(S.current.Cancel));
      await tester.pumpAndSettle();
      expect(
          tester.widget<NoteCard>(find.byType(NoteCard)).cardStyle!.noteTheme,
          NoteTheme.sticky);
      expect(tester.takeException(), isNull);
    } finally {
      await _dispose(tester);
    }
  });
}
