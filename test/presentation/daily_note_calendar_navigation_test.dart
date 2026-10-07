import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:onlynote/Tools/app_typography_settings.dart';
import 'package:onlynote/Tools/locator.dart';
import 'package:onlynote/common/constants.dart';
import 'package:onlynote/data/dto/folder_dto.dart';
import 'package:onlynote/data/dto/note_dto.dart';
import 'package:onlynote/di/di.dart';
import 'package:onlynote/domain/database/database.dart';
import 'package:onlynote/domain/model/daily_note_date.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/domain/repository/folder_repository.dart';
import 'package:onlynote/domain/repository/note_repository.dart';
import 'package:onlynote/domain/usecase/usecase.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/daily_note_calendar_sheet.dart';
import 'package:onlynote/presentation/components/library_filters_sheet.dart';
import 'package:onlynote/presentation/routes/routes.dart';
import 'package:onlynote/presentation/screens/home/bloc/home_bloc.dart';
import 'package:onlynote/presentation/screens/home/bloc/multiple_delete/multiple_delete_bloc.dart';
import 'package:onlynote/presentation/screens/home/home_screen.dart';
import 'package:onlynote/presentation/screens/home/widgets/note_card.dart';
import 'package:onlynote/presentation/theme/theme.dart';
import 'package:onlynote/services/note_search.dart';
import 'package:onlynote/services/purchase_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
// The production preference plugin exposes its test platform separately.
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
// Home's FocusDetector uses VisibilityDetector internally.
// ignore: depend_on_referenced_packages
import 'package:visibility_detector/visibility_detector.dart';

final class _PreferencesPlatform extends SharedPreferencesAsyncPlatform {
  @override
  Future<String?> getString(
          String key, SharedPreferencesOptions options) async =>
      null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Notes implements NoteRepository {
  final values = <String, NoteDto>{};
  int writes = 0;

  @override
  List<NoteDto> getAllNotes() => values.values.toList();
  @override
  Future<NoteDto> getNote(String id) async => values[id]!;
  @override
  Future<void> addUpdateNote(NoteDto note) async {
    writes++;
    values[note.id!] = note;
  }

  @override
  Future<void> deleteNote(String id) async => values.remove(id);
  @override
  Future<void> deleteMultiNotes(List<String> ids) async {
    ids.forEach(values.remove);
  }
}

class _Folders implements FolderRepository {
  @override
  List<FolderDto> getAllFolders() => [
        FolderDto(id: 'work', name: 'Work'),
        FolderDto(id: 'personal', name: 'Personal'),
      ];
  @override
  Future<void> addUpdateFolder(FolderDto folder) async {}
  @override
  Future<void> deleteFolder(String id) async {}
}

/// Home listens to the database box; the repository independently supplies
/// calendar content so tests can also simulate edits while its sheet is open.
class _Database implements Database {
  _Database(this.box);
  @override
  final Box box;
  @override
  T get<T>(String id) => box.get(id) as T;
  @override
  List<T> getAll<T>() => box.values.cast<T>().toList();
  @override
  Future<void> delete(String id) => box.delete(id);
  @override
  Future<void> deleteAll(List<String> keys) => box.deleteAll(keys);
  @override
  Future<void> addUpdate<T>(String id, T item) => box.put(id, item);
}

class _Router extends RootStackRouter {
  Note? openedNote;

  @override
  List<AutoRoute> get routes => [
        AutoRoute(
          initial: true,
          page: PageInfo(HomeRoute.name, builder: (_) => const HomeScreen()),
        ),
        AutoRoute(
          page: PageInfo(AddUpdateNoteRoute.name, builder: (data) {
            openedNote = data.argsAs<AddUpdateNoteRouteArgs>().note;
            return Scaffold(body: Text('Editing ${openedNote?.id}'));
          }),
        ),
        AutoRoute(
          page: PageInfo(RemindersRoute.name,
              builder: (_) =>
                  const Scaffold(body: Text('Reminder list test page'))),
        ),
      ];
}

Future<(_Notes, HomeBloc, _Router)> _openHome(
    WidgetTester tester, Iterable<Note> initial,
    {double width = 390,
    bool disableAnimations = true,
    TargetPlatform? platform}) async {
  if (tester.binding is AutomatedTestWidgetsFlutterBinding) {
    tester.view.physicalSize = Size(width, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }
  final notes = _Notes();
  for (final note in initial) {
    notes.values[note.id!] = NoteDto.fromNote(note);
  }
  final folders = _Folders();
  final home = HomeBloc(
    ShowAllNotesUsecase(notes, folders),
    AddNoteUsecase(notes),
    ReorderNotesUsecase(notes),
    TogglePinUsecase(notes),
    RestoreNotesUsecase(notes),
    PermanentDeleteNotesUsecase(notes),
    CreateFolderUsecase(folders),
    RenameFolderUsecase(folders),
    DeleteFolderUsecase(folders, notes),
    MoveNoteToFolderUsecase(notes),
    GetNoteUsecase(notes),
    UpdateNoteUsecase(notes),
  );
  final selection = MultipleDeleteBloc(DeleteMultipleNotesUsecase(notes));
  final router = _Router();
  getIt.pushNewScope();
  getIt.registerSingleton<NoteRepository>(notes);
  getIt.registerSingleton<Database>(_Database(Hive.box(databaseBox)));
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    router.dispose();
    await home.close();
    await selection.close();
    await getIt.popScope();
  });
  await tester.pumpWidget(MultiBlocProvider(
    providers: [
      BlocProvider.value(value: home),
      BlocProvider.value(value: selection),
    ],
    child: MaterialApp.router(
      routerConfig: router.config(),
      theme: AppTheme.light.copyWith(platform: platform),
      supportedLocales: S.delegate.supportedLocales,
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(disableAnimations: disableAnimations),
        child: child!,
      ),
    ),
  ));
  await tester.pumpAndSettle();
  expect(find.byKey(const ValueKey('daily-note-shortcut')), findsNothing);
  expect(
      find.byKey(const ValueKey('daily-note-calendar-shortcut')), findsNothing);
  expect(find.byKey(const ValueKey('unfinished-quick-filter')), findsNothing);
  expect(find.byKey(const ValueKey('today-reminders-shortcut')), findsNothing);
  expect(find.byKey(const ValueKey('library-filters-shortcut')), findsNothing);
  return (notes, home, router);
}

Future<void> _tap(WidgetTester tester, String key) async {
  final target = find.byKey(ValueKey(key));
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}

Future<void> _openCalendar(WidgetTester tester) async {
  await _tap(tester, 'home-more');
  expect(
      find.byKey(const ValueKey('daily-note-calendar-menu')), findsOneWidget);
  await _tap(tester, 'daily-note-calendar-menu');
  expect(find.byType(DailyNoteCalendarSheet), findsOneWidget);
}

Future<void> _pumpAnimationFrames(WidgetTester tester) async {
  await tester.pump();
  expect(tester.takeException(), isNull, reason: 'First transition frame');
  for (var frame = 0; frame < 24; frame++) {
    await tester.pump(const Duration(milliseconds: 16));
    expect(tester.takeException(), isNull,
        reason: 'Animation frame $frame while updating accessible note cards');
  }
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull, reason: 'Settled transition');
}

Future<void> _tapWithHeldPointer(WidgetTester tester, Finder target) async {
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  final gesture = await tester.startGesture(tester.getCenter(target));
  try {
    await tester.pump(const Duration(milliseconds: 48));
    expect(tester.takeException(), isNull,
        reason: 'Pressed control with semantics enabled');
  } finally {
    await gesture.up();
  }
  await _pumpAnimationFrames(tester);
}

Future<void> _applyFiltersAfterSheetDismisses(
    WidgetTester tester, HomeBloc home) async {
  final sheet = find.byType(LibraryFiltersSheet);
  final route = ModalRoute.of<LibraryFilterResult>(tester.element(sheet))!;
  final previousFilters = Set<NoteSearchFilter>.of(
      home.state.mapOrNull(loaded: (state) => state.filters)!);
  final previousIds = home.state
      .mapOrNull(loaded: (state) => state.notes.map((note) => note.id).toSet());
  final previousCards = tester
      .widgetList<NoteCard>(find.byType(NoteCard))
      .map((card) => card.note.id)
      .toSet();
  final done = find.byKey(const ValueKey('library-apply-filters'));
  await tester.ensureVisible(done);
  await tester.tap(done);
  await tester.pump();
  expect(tester.takeException(), isNull);
  await tester.pump(const Duration(milliseconds: 16));
  expect(tester.takeException(), isNull);

  final stillExiting = route.animation!.value > 0;
  if (tester.binding is AutomatedTestWidgetsFlutterBinding) {
    expect(stillExiting, isTrue,
        reason: 'The animated filter sheet is still dismissing');
  }
  // Native frames may arrive late; use the route's actual animation rather
  // than assume a wall-clock deadline when verifying the intermediate state.
  if (stillExiting) {
    expect(sheet, findsOneWidget);
    expect(
        home.state.mapOrNull(loaded: (state) => state.filters), previousFilters,
        reason: 'Filtering must wait for the modal to finish dismissing');
    expect(
        home.state.mapOrNull(
            loaded: (state) => state.notes.map((note) => note.id).toSet()),
        previousIds);
    expect(
        tester
            .widgetList<NoteCard>(find.byType(NoteCard))
            .map((card) => card.note.id)
            .toSet(),
        previousCards);
  }
  await _pumpAnimationFrames(tester);
}

void main() {
  final fonts = Map<String, GoogleFontBuilder>.of(kAppFontFamilies);
  late Directory directory;
  late Box noteBox;
  late Box folderBox;
  final preferencesPlatform = SharedPreferencesAsyncPlatform.instance;
  final visibilityInterval =
      VisibilityDetectorController.instance.updateInterval;

  setUpAll(() async {
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
    await initializeDateFormatting();
    if (!locator.isRegistered<S>()) locator.registerSingleton(S());
    SharedPreferencesAsyncPlatform.instance = _PreferencesPlatform();
    directory = await Directory.systemTemp.createTemp('onlynote-calendar-');
    Hive.init(directory.path);
    noteBox = await Hive.openBox(databaseBox);
    folderBox = await Hive.openBox(folderDatabaseBox);
    // The actual Home screen may load ads. A cached purchase disables that
    // unrelated native dependency without changing the screen under test.
    SharedPreferences.setMockInitialValues({'remove_ads_entitlement': true});
    final platform = debugDefaultTargetPlatformOverride;
    try {
      // Ads are already removed; this fixture does not exercise StoreKit.
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      await PurchaseService.instance.init();
    } finally {
      debugDefaultTargetPlatformOverride = platform;
    }
  });
  tearDownAll(() async {
    VisibilityDetectorController.instance.updateInterval = visibilityInterval;
    SharedPreferencesAsyncPlatform.instance = preferencesPlatform;
    await noteBox.close();
    await folderBox.close();
    await directory.delete(recursive: true);
  });
  setUp(() {
    for (final family in fonts.keys) {
      kAppFontFamilies[family] = (
              {textStyle, color, fontSize, fontWeight, fontStyle}) =>
          (textStyle ?? const TextStyle()).copyWith(
              color: color,
              fontSize: fontSize,
              fontWeight: fontWeight,
              fontStyle: fontStyle);
    }
  });
  tearDown(() => kAppFontFamilies.addAll(fonts));

  testWidgets(
      'accessible Home repeats checklist filtering and keeps nav actions at 320/390px',
      (tester) async {
    final originalPlatform = debugDefaultTargetPlatformOverride;
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    SemanticsHandle? semantics;
    try {
      semantics = tester.ensureSemantics();
      final initial = [
        Note(id: 'ordinary', title: 'An ordinary note'),
        Note(id: 'unfinished', title: 'Open tasks', todo: [
          Todo(id: 'task', title: 'Finish the release'),
        ]),
        for (var index = 0; index < 32; index++)
          Note(
            id: 'mixed-$index',
            title: index % 3 == 0
                ? 'Mixed note $index with a longer title wrapping across lines'
                : 'Mixed note $index',
            description: List.generate(index % 5 + 1,
                    (line) => 'Line $line of this varied height note $index.')
                .join('\n'),
            todo: index.isEven
                ? [
                    for (var item = 0; item < index % 4 + 1; item++)
                      Todo(
                        id: 'mixed-$index-task-$item',
                        title: 'Completed checklist item $item for note $index',
                        completed: true,
                      ),
                  ]
                : [],
            dateTime: DateTime(2026, 10, index % 20 + 1),
            sortOrder: index + 2,
          ),
      ];
      final (notes, home, router) = await _openHome(tester, initial,
          width: 320, disableAnimations: false, platform: TargetPlatform.iOS);
      final allIds = initial.map((note) => note.id).toSet();
      final checklistIds = initial
          .where((note) => note.todo.isNotEmpty)
          .map((note) => note.id)
          .toSet();

      // Match the reported repeated workflow with real sheet transitions and
      // semantics updates while the masonry grid retains a nonzero offset.
      for (var cycle = 0; cycle < 4; cycle++) {
        final grid =
            Scrollable.of(tester.element(find.byType(SliverMasonryGrid)))
                .position;
        expect(grid.maxScrollExtent, greaterThan(0));
        grid.jumpTo(cycle == 0 ? 0 : grid.maxScrollExtent * .55);
        await _pumpAnimationFrames(tester);
        expect(grid.pixels, cycle == 0 ? equals(0) : greaterThan(0));
        for (final enabled in [true, false]) {
          await _tap(tester, 'home-library-filters');
          expect(find.byType(LibraryFiltersSheet), findsOneWidget);
          final checklists =
              find.byKey(const ValueKey('library-filter-checklists'));
          await tester.ensureVisible(checklists);
          await tester.tap(checklists);
          await _pumpAnimationFrames(tester);
          expect(tester.widget<FilterChip>(checklists).selected, enabled);
          await _applyFiltersAfterSheetDismisses(tester, home);
          expect(find.byType(LibraryFiltersSheet), findsNothing);
          expect(home.state.mapOrNull(loaded: (state) => state.filters),
              enabled ? {NoteSearchFilter.checklists} : <NoteSearchFilter>{});
          final expectedIds = enabled ? checklistIds : allIds;
          expect(
              home.state.mapOrNull(
                  loaded: (state) =>
                      state.notes.map((note) => note.id).toSet()),
              expectedIds);
          final cards = tester.widgetList<NoteCard>(find.byType(NoteCard));
          expect(cards, isNotEmpty);
          expect(cards.every((card) => expectedIds.contains(card.note.id)),
              isTrue);
          expect(tester.takeException(), isNull,
              reason: 'Checklist filtering cycle $cycle, enabled=$enabled');
        }
      }

      // No seeded note has a photo, so these cycles remove and recreate the
      // masonry viewport while the filter sheet's dismiss animation runs.
      for (var cycle = 0; cycle < 2; cycle++) {
        for (final enabled in [true, false]) {
          await _tap(tester, 'home-library-filters');
          expect(find.byType(LibraryFiltersSheet), findsOneWidget);
          final photos = find.byKey(const ValueKey('library-filter-photos'));
          await _tapWithHeldPointer(tester, photos);
          expect(tester.widget<FilterChip>(photos).selected, enabled);
          await _tapWithHeldPointer(
              tester, find.byKey(const ValueKey('library-apply-filters')));
          expect(find.byType(LibraryFiltersSheet), findsNothing);
          expect(home.state.mapOrNull(loaded: (state) => state.filters),
              enabled ? {NoteSearchFilter.photos} : <NoteSearchFilter>{});
          expect(
              home.state.mapOrNull(
                  loaded: (state) =>
                      state.notes.map((note) => note.id).toSet()),
              enabled ? <String?>{} : allIds);
          expect(find.byType(NoteCard), enabled ? findsNothing : findsWidgets);
          expect(tester.takeException(), isNull,
              reason: 'Empty photo filtering cycle $cycle, enabled=$enabled');
        }
      }

      // Accessibility may become active while a modal route already exists.
      // Rebuild that semantics tree before repeating a real press/release.
      semantics.dispose();
      semantics = null;
      await tester.pump();
      expect(tester.takeException(), isNull);
      await _tap(tester, 'home-library-filters');
      expect(find.byType(LibraryFiltersSheet), findsOneWidget);
      semantics = tester.ensureSemantics();
      await _pumpAnimationFrames(tester);
      for (final enabled in [true, false]) {
        if (!enabled) {
          await _tap(tester, 'home-library-filters');
          expect(find.byType(LibraryFiltersSheet), findsOneWidget);
        }
        final checklists =
            find.byKey(const ValueKey('library-filter-checklists'));
        await _tapWithHeldPointer(tester, checklists);
        expect(tester.widget<FilterChip>(checklists).selected, enabled);
        await _tapWithHeldPointer(
            tester, find.byKey(const ValueKey('library-apply-filters')));
        expect(find.byType(LibraryFiltersSheet), findsNothing);
        expect(home.state.mapOrNull(loaded: (state) => state.filters),
            enabled ? {NoteSearchFilter.checklists} : <NoteSearchFilter>{});
        expect(
            home.state.mapOrNull(
                loaded: (state) => state.notes.map((note) => note.id).toSet()),
            enabled ? checklistIds : allIds);
        expect(tester.takeException(), isNull,
            reason: 'Late semantics activation, checklists enabled=$enabled');
      }

      // Two invocations before the saved-view read resolves should represent
      // one filter request and create one modal route.
      final filterButton = tester.widget<IconButton>(find.descendant(
          of: find.byKey(const ValueKey('home-library-filters')),
          matching: find.byType(IconButton)));
      filterButton.onPressed!();
      filterButton.onPressed!();
      await _pumpAnimationFrames(tester);
      expect(find.byType(LibraryFiltersSheet, skipOffstage: false),
          findsOneWidget);
      await _tapWithHeldPointer(tester, find.byTooltip('Close'));
      expect(
          find.byType(LibraryFiltersSheet, skipOffstage: false), findsNothing);

      // Exercise both widths within the shared saved-view store's fake clock.
      for (final width in [320.0, 390.0]) {
        if (tester.binding is AutomatedTestWidgetsFlutterBinding) {
          tester.view.physicalSize = Size(width, 844);
        }
        home.add(const HomeEvent.filtersChanged({}));
        await tester.pumpAndSettle();
        final filters = find.byKey(const ValueKey('home-library-filters'));
        expect(find.descendant(of: find.byType(AppBar), matching: filters),
            findsOneWidget);
        await _tap(tester, 'home-library-filters');
        expect(find.byType(LibraryFiltersSheet), findsOneWidget);
        await _tap(tester, 'library-filter-unfinished');
        expect(
            tester
                .widget<FilterChip>(
                    find.byKey(const ValueKey('library-filter-unfinished')))
                .selected,
            isTrue);
        await _tap(tester, 'library-apply-filters');
        expect(find.byType(LibraryFiltersSheet), findsNothing);
        expect(home.state.mapOrNull(loaded: (state) => state.filters),
            {NoteSearchFilter.unfinished});
        expect(
            home.state
                .mapOrNull(loaded: (state) => state.notes.map((n) => n.id)),
            ['unfinished']);

        await _tap(tester, 'home-more');
        await _tap(tester, 'home-reminders-menu');
        expect(find.text('Reminder list test page'), findsOneWidget);
        expect(router.stackData.map((route) => route.name),
            [HomeRoute.name, RemindersRoute.name]);
        await router.maybePop();
        await tester.pumpAndSettle();
        expect(find.byType(HomeScreen), findsOneWidget);
        expect(router.stackData.map((route) => route.name), [HomeRoute.name]);

        await _openCalendar(tester);
        expect(notes.writes, 0);
        expect(router.openedNote, isNull);
        await tester.tap(find.byTooltip('Close'));
        await tester.pumpAndSettle();
        expect(find.byType(DailyNoteCalendarSheet), findsNothing);
        expect(router.stackData.map((route) => route.name), [HomeRoute.name]);
        expect(find.byKey(const ValueKey('daily-note-shortcut')), findsNothing);
        expect(find.byKey(const ValueKey('daily-note-calendar-shortcut')),
            findsNothing);
        expect(find.byKey(const ValueKey('unfinished-quick-filter')),
            findsNothing);
        expect(find.byKey(const ValueKey('today-reminders-shortcut')),
            findsNothing);
        expect(tester.takeException(), isNull);
      }
    } finally {
      semantics?.dispose();
      debugDefaultTargetPlatformOverride = originalPlatform;
    }
  });

  testWidgets(
      'calendar ignores library filters and opens fresh archived content',
      (tester) async {
    final now = DateTime.now();
    final key = dailyNoteDateKey(DateTime(now.year, now.month, 1));
    final original = Note(
      id: 'daily',
      title: 'Renamed daily note',
      description: 'Original body',
      folderId: 'personal',
      isArchived: true,
      dailyNoteDateKey: key,
    );
    final (notes, home, router) = await _openHome(tester, [original]);
    home.add(const HomeEvent.selectFolder('work'));
    home.add(const HomeEvent.filtersChanged({NoteSearchFilter.unfinished}));
    home.add(const HomeEvent.searchChanged('No matching content'));
    await tester.pumpAndSettle();
    expect(home.state.mapOrNull(loaded: (state) => state.notes), isEmpty);
    await _openCalendar(tester);
    expect(find.byKey(ValueKey('daily-calendar-marker-$key')), findsOneWidget);
    // Editing elsewhere after the calendar snapshot must not supply stale
    // content to the editor route or remove the archive/folder association.
    final fresh = original.copyWith(description: 'Body edited elsewhere');
    notes.values['daily'] = NoteDto.fromNote(fresh);
    await _tap(tester, 'daily-calendar-day-$key');
    expect(router.openedNote, fresh);
    expect(router.stackData.map((route) => route.name),
        [HomeRoute.name, AddUpdateNoteRoute.name]);
    expect(find.byType(DailyNoteCalendarSheet), findsNothing);
    expect(notes.writes, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('browsing and deleted dates never create or resurrect a note',
      (tester) async {
    final now = DateTime.now();
    final key = dailyNoteDateKey(DateTime(now.year, now.month, 1));
    final original = Note(
      id: 'daily',
      title: 'Daily note',
      dailyNoteDateKey: key,
      isArchived: true,
    );
    final (notes, _, router) = await _openHome(tester, [original]);
    await _openCalendar(tester);
    await _tap(tester, 'daily-calendar-previous-month');
    final emptyDay = dailyNoteDateKey(DateTime(now.year, now.month - 1, 1));
    await _tap(tester, 'daily-calendar-day-$emptyDay');
    expect(find.byType(DailyNoteCalendarSheet), findsOneWidget);
    expect(notes.writes, 0);
    await _tap(tester, 'daily-calendar-next-month');
    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    expect(notes.writes, 0);
    expect(router.openedNote, isNull);
    await _openCalendar(tester);
    final deleted = original.copyWith(deletedAt: now);
    notes.values['daily'] = NoteDto.fromNote(deleted);
    await _tap(tester, 'daily-calendar-day-$key');
    expect(router.openedNote, isNull);
    expect(router.stackData.map((route) => route.name), [HomeRoute.name]);
    expect(notes.values['daily']!.toDomain(), deleted);
    expect(notes.writes, 0);
    expect(find.text(S.current.Daily_Note_Calendar_Note_Unavailable),
        findsOneWidget);
    // Missing-date feedback uses the shared transient snackbar. Let both its
    // dismissal and fallback timer finish while the Home screen is mounted.
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(find.byType(SnackBar), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('explicit calendar Today action creates once and then reuses',
      (tester) async {
    final (notes, _, router) = await _openHome(tester, []);
    await _openCalendar(tester);
    expect(notes.writes, 0);
    await _tap(tester, 'daily-calendar-open-today');
    final daily = router.openedNote!;
    expect(daily.dailyNoteDateKey, dailyNoteDateKey(DateTime.now()));
    expect(notes.values.keys, [daily.id]);
    expect(notes.writes, 1);
    await router.maybePop();
    await tester.pumpAndSettle();
    await _openCalendar(tester);
    await _tap(tester, 'daily-calendar-open-today');
    expect(router.openedNote, daily);
    expect(notes.writes, 1);
    expect(tester.takeException(), isNull);
  });
}
