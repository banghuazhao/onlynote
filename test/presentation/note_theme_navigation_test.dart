import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:onlynote/Tools/app_appearance_settings.dart';
import 'package:onlynote/Tools/app_card_style_settings.dart';
import 'package:onlynote/Tools/app_layout_settings.dart';
import 'package:onlynote/Tools/app_typography_settings.dart';
import 'package:onlynote/Tools/locator.dart';
import 'package:onlynote/common/constants.dart';
import 'package:onlynote/data/dto/note_dto.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/domain/model/note_card_style.dart';
import 'package:onlynote/domain/model/note_theme.dart';
import 'package:onlynote/domain/repository/note_repository.dart';
import 'package:onlynote/domain/usecase/add_note_usecase.dart';
import 'package:onlynote/domain/usecase/get_note_usecase.dart';
import 'package:onlynote/domain/usecase/update_note_usecase.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/note_theme_surface.dart';
import 'package:onlynote/presentation/components/paper_note.dart';
import 'package:onlynote/presentation/routes/routes.dart';
import 'package:onlynote/presentation/screens/add_update_note/add_update_note_screen.dart';
import 'package:onlynote/presentation/screens/add_update_note/bloc/add_update_bloc.dart';
import 'package:onlynote/presentation/screens/card_appearance/card_appearance_screen.dart';
import 'package:onlynote/presentation/screens/note_detail/bloc/detail/note_detail_bloc.dart';
import 'package:onlynote/presentation/screens/note_detail/note_detail_screen.dart';
import 'package:onlynote/presentation/screens/settings/premium_screen.dart';
import 'package:onlynote/presentation/theme/theme.dart';
import 'package:onlynote/services/note_autosave.dart';
import 'package:onlynote/services/note_position_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/premium_test_fakes.dart';

class _Notes implements NoteRepository {
  _Notes(Note note) : value = NoteDto.fromNote(note);
  NoteDto value;
  int writes = 0;

  @override
  Future<NoteDto> getNote(String id) async => value;
  @override
  List<NoteDto> getAllNotes() => [value];
  @override
  Future<void> addUpdateNote(NoteDto note) async {
    writes++;
    value = note;
  }

  @override
  Future<void> deleteNote(String id) async {}
  @override
  Future<void> deleteMultiNotes(List<String> ids) async {}
}

class _Autosave implements NoteAutosaveStore {
  _Autosave(this.notes);
  final _Notes notes;
  final drafts = <String, Note>{};
  bool failNext = false;
  int attempts = 0;

  @override
  Future<void> writeDraft(Note note) async => drafts[note.id!] = note;
  @override
  Future<void> removeDraft(String id) async => drafts.remove(id);
  @override
  Future<void> saveNote(Note note) async {
    attempts++;
    if (failNext) {
      failNext = false;
      throw StateError('Save temporarily unavailable');
    }
    await notes.addUpdateNote(NoteDto.fromNote(note));
  }
}

class _ThemeRouter extends RootStackRouter {
  _ThemeRouter(this.child);
  final Widget child;

  @override
  List<AutoRoute> get routes => [
        AutoRoute(
          initial: true,
          page: PageInfo('ThemeIntegrationRoute', builder: (_) => child),
        ),
      ];
}

Widget _host(_ThemeRouter router, {bool dark = false}) => MaterialApp.router(
      routerConfig: router.config(),
      theme: dark ? AppTheme.dark : AppTheme.light,
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: S.delegate.supportedLocales,
    );

Note _note({NoteTheme? theme, Color? color}) => Note(
      id: 'theme-source',
      title: 'Keep the source title',
      description: 'The theme changes paper without replacing these words.',
      dateTime: DateTime(2026, 10, 1),
      color: color,
      folderId: 'travel',
      tags: ['Work'],
      todo: [Todo(id: 'keep-task', title: 'Keep this task', completed: true)],
      cardStyle: NoteCardStyle(noteTheme: theme, fontSize: AppFontSize.large),
    );

PaperNote _sheet(WidgetTester tester) => tester
    .widgetList<PaperNote>(find.byType(PaperNote))
    .singleWhere((paper) => paper.kind == PaperNoteKind.sheet);

void _expectContent(Note actual, Note original) {
  expect(actual.id, original.id);
  expect(actual.title, original.title);
  expect(actual.description, original.description);
  expect(actual.todo, original.todo);
  expect(actual.folderId, original.folderId);
  expect(actual.tags, original.tags);
  expect(actual.color, original.color);
  expect(actual.cardStyle.fontSize, original.cardStyle.fontSize);
}

Future<void> _choose(WidgetTester tester, NoteTheme theme) async {
  final target = find.byKey(ValueKey('note-theme-choice-${theme.name}'));
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target.hitTestable());
  await tester.pumpAndSettle();
}

Future<void> _openAppearance(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('editor-more-note')));
  await tester.pumpAndSettle();
  await tester.tap(find.text(S.current.Card_Style));
  await tester.pumpAndSettle();
  expect(find.byType(CardAppearanceScreen), findsOneWidget);
}

void main() {
  final fonts = Map<String, GoogleFontBuilder>.of(kAppFontFamilies);

  setUpAll(() async {
    await initializeDateFormatting();
    if (!locator.isRegistered<S>()) locator.registerSingleton(S());
  });
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
            color: color,
            fontSize: fontSize,
            fontWeight: fontWeight,
            fontStyle: fontStyle,
          );
    }
  });
  tearDown(() => kAppFontFamilies.addAll(fonts));

  for (final theme in NoteTheme.values) {
    testWidgets('reader renders $theme without changing the stored note',
        (tester) async {
      final source = _note(
          theme: theme,
          color: theme == NoteTheme.gridPaper ? const Color(0xFFD3EDE4) : null);
      final notes = _Notes(source);
      final bloc =
          NoteDetailBloc(GetNoteUsecase(notes), UpdateNoteUsecase(notes));
      addTearDown(bloc.close);
      final router = _ThemeRouter(NoteDetailScreen(
        noteId: source.id!,
        positionStore: NotePositionStore(storage: MemoryNotePositionStorage()),
      ));
      try {
        await tester.pumpWidget(BlocProvider.value(
            value: bloc, child: _host(router, dark: theme.isPremium)));
        await tester.pumpAndSettle();
        final paper = _sheet(tester);
        expect(paper.theme, theme);
        expect(
            paper.color, noteThemePaperColor(theme, customColor: source.color));
        expect(find.text(source.title!), findsOneWidget);
        expect(notes.value.toDomain().cardStyle, source.cardStyle);
        _expectContent(notes.value.toDomain(), source);
        expect(notes.writes, 0);
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        router.dispose();
      }
    });
  }

  for (final (reading, override) in [
    (true, null),
    (false, null),
    (true, NoteTheme.classic),
    (false, NoteTheme.classic),
  ]) {
    testWidgets(
        '${reading ? 'reader' : 'editor'} ${override == null ? 'follows changed defaults' : 'keeps its explicit Classic override'}',
        (tester) async {
      final source = _note(theme: override);
      final notes = _Notes(source);
      final editorBloc =
          AddUpdateBloc(AddNoteUsecase(notes), UpdateNoteUsecase(notes));
      final readerBloc =
          NoteDetailBloc(GetNoteUsecase(notes), UpdateNoteUsecase(notes));
      addTearDown(editorBloc.close);
      addTearDown(readerBloc.close);
      final store = _Autosave(notes);
      final positions = NotePositionStore(storage: MemoryNotePositionStorage());
      final router = _ThemeRouter(reading
          ? NoteDetailScreen(noteId: source.id!, positionStore: positions)
          : AddUpdateNoteScreen(
              note: source, autosaveStore: store, positionStore: positions));
      try {
        await tester.pumpWidget(MultiBlocProvider(providers: [
          BlocProvider.value(value: editorBloc),
          BlocProvider.value(value: readerBloc),
        ], child: _host(router)));
        await tester.pumpAndSettle();
        expect(_sheet(tester).theme, NoteTheme.classic);
        final state = tester.state(reading
            ? find.byType(NoteDetailScreen)
            : find.byType(AddUpdateNoteScreen));
        final done = AppCardStyleSettings.instance
            .saveDefaults(const NoteCardStyle(noteTheme: NoteTheme.legalPad));
        await tester.pumpAndSettle();
        await done;
        await tester.pumpAndSettle();
        expect(_sheet(tester).theme, override ?? NoteTheme.legalPad);
        expect(_sheet(tester).color,
            noteThemePaperColor(override ?? NoteTheme.legalPad));
        expect(
            tester.state(reading
                ? find.byType(NoteDetailScreen)
                : find.byType(AddUpdateNoteScreen)),
            same(state));
        expect(notes.value.toDomain().cardStyle.noteTheme, override);
        expect(notes.writes, 0);
        expect(store.drafts, isEmpty);
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        router.dispose();
      }
    });
  }

  for (final fail in [false, true]) {
    testWidgets(
        'editor ${fail ? 'rolls back a failed' : 'saves a free'} theme change and preserves existing premium appearance',
        (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final entitlement = PremiumTestFixture();
      await entitlement.init();
      addTearDown(entitlement.dispose);
      final source =
          _note(theme: NoteTheme.dottedJournal, color: const Color(0xFFF0DAC1));
      final notes = _Notes(source);
      final store = _Autosave(notes)..failNext = fail;
      final bloc =
          AddUpdateBloc(AddNoteUsecase(notes), UpdateNoteUsecase(notes));
      addTearDown(bloc.close);
      final router = _ThemeRouter(AddUpdateNoteScreen(
          note: source,
          autosaveStore: store,
          premiumAccess: entitlement.access,
          positionStore:
              NotePositionStore(storage: MemoryNotePositionStorage())));
      try {
        await tester
            .pumpWidget(BlocProvider.value(value: bloc, child: _host(router)));
        await tester.pumpAndSettle();
        await _openAppearance(tester);
        await _choose(tester, NoteTheme.gridPaper);
        expect(notes.writes, 0);
        await tester.tap(find.byKey(const ValueKey('card-style-save')));
        await tester.pumpAndSettle();
        expect(find.byType(PremiumScreen), findsNothing);
        expect(entitlement.store.buyCalls, 0);
        final saved = notes.value.toDomain();
        _expectContent(saved, source);
        if (fail) {
          expect(find.byType(CardAppearanceScreen), findsOneWidget);
          expect(saved.cardStyle, source.cardStyle);
          final editorPaper = tester
              .widgetList<PaperNote>(
                  find.byType(PaperNote, skipOffstage: false))
              .singleWhere((paper) => paper.kind == PaperNoteKind.sheet);
          expect(editorPaper.theme, NoteTheme.dottedJournal);
          await tester.pump(const Duration(seconds: 5));
          await tester.pumpAndSettle();
        } else {
          expect(find.byType(CardAppearanceScreen), findsNothing);
          expect(_sheet(tester).theme, NoteTheme.gridPaper);
          expect(_sheet(tester).color, source.color);
          expect(saved.cardStyle.noteTheme, NoteTheme.gridPaper);
          expect(store.attempts, 1);
        }
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        router.dispose();
      }
    });
  }

  for (final theme in [
    NoteTheme.classic,
    NoteTheme.sticky,
    NoteTheme.kraftNotebook,
  ]) {
    testWidgets('new notes retain the $theme default while typing',
        (tester) async {
      SharedPreferences.setMockInitialValues({'app_note_theme': theme.name});
      await AppCardStyleSettings.instance.load();
      final notes = _Notes(Note(id: 'unused'));
      final store = _Autosave(notes);
      final bloc =
          AddUpdateBloc(AddNoteUsecase(notes), UpdateNoteUsecase(notes));
      addTearDown(bloc.close);
      final router = _ThemeRouter(AddUpdateNoteScreen(
        autosaveStore: store,
        positionStore: NotePositionStore.memory(),
      ));
      try {
        await tester
            .pumpWidget(BlocProvider.value(value: bloc, child: _host(router)));
        await tester.pumpAndSettle();
        final paper = _sheet(tester);
        expect(paper.theme, theme);
        if (theme == NoteTheme.classic) {
          expect(colors, contains(paper.color));
        } else {
          expect(paper.color, noteThemePaperColor(theme));
        }
        await tester.enterText(find.byType(TextField).first, 'A fresh idea');
        await tester.pump(const Duration(seconds: 2));
        await tester.pumpAndSettle();
        final saved = notes.value.toDomain();
        expect(saved.title, 'A fresh idea');
        expect(saved.cardStyle.noteTheme, isNull);
        expect(saved.color, theme == NoteTheme.classic ? paper.color : isNull);
        expect(_sheet(tester).theme, theme);
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        router.dispose();
      }
    });
  }
}
