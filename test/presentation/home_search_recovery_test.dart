import 'dart:convert';
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
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/domain/repository/folder_repository.dart';
import 'package:onlynote/domain/repository/note_repository.dart';
import 'package:onlynote/domain/usecase/usecase.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/library_filters_sheet.dart';
import 'package:onlynote/presentation/routes/routes.dart';
import 'package:onlynote/presentation/screens/home/bloc/home_bloc.dart';
import 'package:onlynote/presentation/screens/home/bloc/multiple_delete/multiple_delete_bloc.dart';
import 'package:onlynote/presentation/screens/home/home_screen.dart';
import 'package:onlynote/presentation/theme/theme.dart';
import 'package:onlynote/services/note_search.dart';
import 'package:onlynote/services/note_tags.dart';
import 'package:onlynote/services/purchase_service.dart';
import 'package:onlynote/services/saved_note_views.dart';
import 'package:shared_preferences/shared_preferences.dart';
// The production preference plugin exposes its test platform separately.
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
// Home's FocusDetector uses VisibilityDetector internally.
// ignore: depend_on_referenced_packages
import 'package:visibility_detector/visibility_detector.dart';

final _savedView = SavedNoteView(
  id: 'missing-release',
  name: 'Release research',
  query: 'missing',
  filters: {NoteSearchFilter.pinned, NoteSearchFilter.recordings},
  tags: ['Unavailable', 'Research'],
  folderId: 'work',
  archiveScope: NoteArchiveScope.all,
);

final class _PreferencesPlatform extends SharedPreferencesAsyncPlatform {
  final values = <String, String>{
    SavedNoteViewStore.storageKey: jsonEncode({
      'version': 1,
      'views': [_savedView.toJson()],
    }),
  };

  @override
  Future<String?> getString(
          String key, SharedPreferencesOptions options) async =>
      values[key];

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
  @override
  List<AutoRoute> get routes => [
        AutoRoute(
          initial: true,
          page: PageInfo(HomeRoute.name, builder: (_) => const HomeScreen()),
        ),
      ];
}

List<Note> _libraryNotes() => [
      Note(
        id: 'active-alpha',
        title: 'Release alpha',
        folderId: 'work',
        tags: ['Research'],
        todo: [Todo(id: 'task', title: 'Review the release')],
      ),
      Note(
        id: 'active-beta',
        title: 'Release beta',
        folderId: 'work',
        tags: ['Research'],
        isPinned: true,
      ),
      Note(
        id: 'active-personal',
        title: 'Personal planning',
        folderId: 'personal',
        tags: ['Personal'],
        isPinned: true,
      ),
      Note(
        id: 'archive-work',
        title: 'Release archive',
        folderId: 'work',
        tags: ['Research'],
        isArchived: true,
      ),
      Note(
        id: 'archive-personal',
        title: 'Personal archive',
        folderId: 'personal',
        isArchived: true,
      ),
      Note(
        id: 'trash-work',
        title: 'Release removed',
        folderId: 'work',
        deletedAt: DateTime.utc(2026, 10, 6),
      ),
      Note(
        id: 'trash-personal',
        title: 'Personal removed',
        folderId: 'personal',
        deletedAt: DateTime.utc(2026, 10, 6),
      ),
    ];

Future<(_Notes, HomeBloc)> _openHome(
  WidgetTester tester, {
  Iterable<Note>? initial,
  double width = 390,
  double height = 844,
  double textScale = 1,
  Locale locale = const Locale('en'),
  bool disableAnimations = true,
  TargetPlatform platform = TargetPlatform.iOS,
}) async {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final notes = _Notes();
  for (final note in initial ?? _libraryNotes()) {
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
          disableAnimations: disableAnimations,
          textScaler: TextScaler.linear(textScale),
        ),
        child: child!,
      ),
    ),
  ));
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
  return (notes, home);
}

Future<void> _tap(WidgetTester tester, String key) async {
  final target = find.byKey(ValueKey(key));
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

Future<void> _removeCriterion(
    WidgetTester tester, String key, String label) async {
  final chip = find.byKey(ValueKey(key));
  await tester.ensureVisible(chip);
  await tester.pumpAndSettle();
  final tooltip = S.current.Remove_Library_Criterion(label);
  await tester
      .tap(find.descendant(of: chip, matching: find.byTooltip(tooltip)));
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

Future<void> _send(WidgetTester tester, HomeBloc home, HomeEvent event) async {
  home.add(event);
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

Future<void> _showSearch(WidgetTester tester) async {
  await _tap(tester, 'home-more');
  await _tap(tester, 'home-search-menu');
  expect(find.byType(TextField), findsOneWidget);
}

Future<void> _applyStoredView(WidgetTester tester, HomeBloc home) async {
  await _tap(tester, 'home-library-filters');
  final sheet = find.byType(LibraryFiltersSheet);
  // Opening awaits the serialized preference store. That continuation may
  // need another frame even when pumpAndSettle sees no animation pending.
  for (var frame = 0; frame < 30 && sheet.evaluate().isEmpty; frame++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
  expect(sheet, findsOneWidget);
  final route = ModalRoute.of<LibraryFilterResult>(tester.element(sheet))!;
  await _tap(tester, 'saved-view-${_savedView.id}');
  await route.completed;
  await tester.pump();
  expect(sheet, findsNothing);
  expect(
    tester.widget<TextField>(find.byType(TextField)).controller!.text,
    _savedView.query,
  );
  home.state.mapOrNull(loaded: (state) {
    expect(state.selectedViewId, _savedView.id);
    expect(state.notes, isEmpty);
  });
}

Set<String?> _visibleIds(HomeBloc home) => home.state.maybeMap(
    loaded: (state) => state.notes.map((note) => note.id).toSet(),
    orElse: () => throw StateError('Home did not load'));

void _expectCount(WidgetTester tester, HomeBloc home, int count) {
  final counter = find.byKey(const ValueKey('home-search-result-count'));
  expect(counter, findsOneWidget);
  expect(
      tester.widget<Text>(counter).data, S.current.Search_Results_Count(count));
  expect(home.state.mapOrNull(loaded: (state) => state.notes.length), count);
}

void _expectScope(HomeBloc home,
    {String? folderId,
    bool archive = false,
    bool trash = false,
    bool includeArchived = false}) {
  home.state.mapOrNull(loaded: (state) {
    expect(state.selectedFolderId, folderId);
    expect(state.showArchive, archive);
    expect(state.showTrash, trash);
    expect(state.includeArchived, includeArchived);
  });
}

void main() {
  final fonts = Map<String, GoogleFontBuilder>.of(kAppFontFamilies);
  final originalPreferencesPlatform = SharedPreferencesAsyncPlatform.instance;
  final preferences = _PreferencesPlatform();
  final visibilityInterval =
      VisibilityDetectorController.instance.updateInterval;
  late Directory directory;
  late Box noteBox;
  late Box folderBox;

  setUpAll(() async {
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
    await initializeDateFormatting();
    if (!locator.isRegistered<S>()) locator.registerSingleton(S());
    SharedPreferencesAsyncPlatform.instance = preferences;
    directory =
        await Directory.systemTemp.createTemp('onlynote-search-recovery-');
    Hive.init(directory.path);
    noteBox = await Hive.openBox(databaseBox);
    folderBox = await Hive.openBox(folderDatabaseBox);
    SharedPreferences.setMockInitialValues({'remove_ads_entitlement': true});
    final platform = debugDefaultTargetPlatformOverride;
    try {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      await PurchaseService.instance.init();
    } finally {
      debugDefaultTargetPlatformOverride = platform;
    }
  });

  tearDownAll(() async {
    VisibilityDetectorController.instance.updateInterval = visibilityInterval;
    SharedPreferencesAsyncPlatform.instance = originalPreferencesPlatform;
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
      'both recovery orders preserve scope and keep saved views reusable',
      (tester) async {
    final (notes, home) = await _openHome(tester);
    final savedPreferences = Map<String, String>.of(preferences.values);
    final originalNotes =
        notes.getAllNotes().map((note) => note.toDomain()).toList();
    await _applyStoredView(tester, home);
    _expectCount(tester, home, 0);
    expect(find.byKey(const ValueKey('home-clear-search')), findsOneWidget);
    expect(find.byKey(const ValueKey('home-clear-filters')), findsOneWidget);

    await _tap(tester, 'home-clear-search');
    home.state.mapOrNull(loaded: (state) {
      expect(state.searchQuery, isEmpty);
      expect(state.filters, _savedView.filters);
      expect(state.selectedTags, _savedView.tags.toSet());
      expect(state.selectedViewId, isNull);
      expect(
          state.savedViews.map((view) => view.toJson()), [_savedView.toJson()]);
    });
    _expectScope(home, folderId: 'work', includeArchived: true);
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text,
        isEmpty);
    expect(find.byKey(const ValueKey('home-clear-search')), findsNothing);
    expect(find.byKey(const ValueKey('home-clear-filters')), findsOneWidget);
    _expectCount(tester, home, 0);

    await _tap(tester, 'home-clear-filters');
    _expectScope(home, folderId: 'work', includeArchived: true);
    expect(_visibleIds(home), {'active-alpha', 'active-beta', 'archive-work'});
    expect(
        find.byKey(const ValueKey('home-search-result-count')), findsNothing);
    expect(SavedNoteViewStore.instance.views.map((view) => view.toJson()),
        [_savedView.toJson()]);
    expect(preferences.values, savedPreferences);
    expect(notes.getAllNotes().map((note) => note.toDomain()).toList(),
        originalNotes);
    expect(notes.writes, 0);
    // Keep repeated store operations in one widget-test clock. The singleton
    // store serializes work with Futures created in the initiating zone.
    // A subsequent test's clock cannot drain that previous clock's queue.
    await _applyStoredView(tester, home);

    await _tap(tester, 'home-clear-filters');
    home.state.mapOrNull(loaded: (state) {
      expect(state.searchQuery, 'missing');
      expect(state.filters, isEmpty);
      expect(state.selectedTags, isEmpty);
      expect(state.selectedViewId, isNull);
      expect(
          state.savedViews.map((view) => view.toJson()), [_savedView.toJson()]);
    });
    _expectScope(home, folderId: 'work', includeArchived: true);
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'missing');
    expect(find.byKey(const ValueKey('home-clear-filters')), findsNothing);
    expect(find.byKey(const ValueKey('home-clear-search')), findsOneWidget);
    _expectCount(tester, home, 0);

    await _tap(tester, 'home-clear-search');
    expect(_visibleIds(home), {'active-alpha', 'active-beta', 'archive-work'});
    await _applyStoredView(tester, home);
    home.state.mapOrNull(loaded: (state) {
      expect(state.filters, _savedView.filters);
      expect(state.selectedTags, _savedView.tags.toSet());
    });
    // Per-criterion actions detach the live selection while leaving the saved
    // view reusable. Keep these serialized store operations in this clock.
    await _removeCriterion(
        tester, 'active-filter-pinned', S.current.Filter_Pinned);
    home.state.mapOrNull(loaded: (state) {
      expect(state.filters, {NoteSearchFilter.recordings});
      expect(state.selectedTags, _savedView.tags.toSet());
      expect(state.searchQuery, _savedView.query);
      expect(state.selectedViewId, isNull);
    });
    _expectScope(home, folderId: 'work', includeArchived: true);
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text,
        _savedView.query);
    await _applyStoredView(tester, home);
    await _removeCriterion(
        tester, 'active-tag-unavailable', '${S.current.Tags}: Unavailable');
    home.state.mapOrNull(loaded: (state) {
      expect(state.filters, _savedView.filters);
      expect(state.selectedTags, {'Research'});
      expect(state.searchQuery, _savedView.query);
      expect(state.selectedViewId, isNull);
    });
    _expectScope(home, folderId: 'work', includeArchived: true);
    await _applyStoredView(tester, home);
    await _removeCriterion(
        tester, 'active-scope-include-archived', S.current.Include_Archived);
    home.state.mapOrNull(loaded: (state) {
      expect(state.filters, _savedView.filters);
      expect(state.selectedTags, _savedView.tags.toSet());
      expect(state.searchQuery, _savedView.query);
      expect(state.selectedViewId, isNull);
    });
    _expectScope(home, folderId: 'work');
    await _applyStoredView(tester, home);
    // Invoke both callbacks in the same frame, before queued bloc events can
    // publish a new state. Each removal must apply to the preceding removal.
    tester
        .widget<InputChip>(find.byKey(const ValueKey('active-filter-pinned')))
        .onDeleted!();
    tester
        .widget<InputChip>(
            find.byKey(const ValueKey('active-filter-recordings')))
        .onDeleted!();
    await tester.pumpAndSettle();
    home.state.mapOrNull(loaded: (state) {
      expect(state.filters, isEmpty);
      expect(state.selectedTags, _savedView.tags.toSet());
      expect(state.searchQuery, _savedView.query);
      expect(state.selectedViewId, isNull);
    });
    _expectScope(home, folderId: 'work', includeArchived: true);
    tester
        .widget<InputChip>(find.byKey(const ValueKey('active-tag-unavailable')))
        .onDeleted!();
    tester
        .widget<InputChip>(find.byKey(const ValueKey('active-tag-research')))
        .onDeleted!();
    await tester.pumpAndSettle();
    home.state.mapOrNull(loaded: (state) {
      expect(state.filters, isEmpty);
      expect(state.selectedTags, isEmpty);
      expect(state.searchQuery, _savedView.query);
      expect(state.selectedViewId, isNull);
      expect(
          state.savedViews.map((view) => view.toJson()), [_savedView.toJson()]);
    });
    _expectScope(home, folderId: 'work', includeArchived: true);
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text,
        _savedView.query);
    expect(preferences.values, savedPreferences);
    await _applyStoredView(tester, home);
    home.state.mapOrNull(loaded: (state) {
      expect(state.filters, _savedView.filters);
      expect(state.selectedTags, _savedView.tags.toSet());
    });
    expect(SavedNoteViewStore.instance.views.map((view) => view.toJson()),
        [_savedView.toJson()]);
    expect(preferences.values, savedPreferences);
    expect(notes.getAllNotes().map((note) => note.toDomain()).toList(),
        originalNotes);
    expect(notes.writes, 0);
  });

  for (final scope in ['folder', 'all', 'archive', 'trash']) {
    testWidgets('recovery preserves $scope scope and isolates other notes',
        (tester) async {
      final (notes, home) = await _openHome(tester);
      if (scope == 'trash') {
        await _send(tester, home, const HomeEvent.showTrash(true));
      } else {
        await _send(
            tester,
            home,
            HomeEvent.applySavedView(SavedNoteView(
              id: 'scope-test',
              name: 'Scope test',
              folderId: 'work',
              archiveScope: switch (scope) {
                'all' => NoteArchiveScope.all,
                'archive' => NoteArchiveScope.archived,
                _ => NoteArchiveScope.active,
              },
            )));
      }
      await _send(tester, home, const HomeEvent.searchChanged('missing'));
      await _send(
          tester,
          home,
          const HomeEvent.filtersChanged({
            NoteSearchFilter.pinned,
            NoteSearchFilter.checklists,
          }));
      await _send(tester, home,
          const HomeEvent.tagsChanged({'Unavailable', 'Research'}));
      _expectCount(tester, home, 0);

      expect(find.byKey(const ValueKey('home-active-criteria-summary')),
          findsOneWidget);
      expect(find.byKey(const ValueKey('active-scope-include-archived')),
          scope == 'all' ? findsOneWidget : findsNothing);
      await _removeCriterion(
          tester, 'active-filter-pinned', S.current.Filter_Pinned);
      home.state.mapOrNull(loaded: (state) {
        expect(state.filters, {NoteSearchFilter.checklists});
        expect(state.selectedTags, {'Unavailable', 'Research'});
        expect(state.searchQuery, 'missing');
      });
      await _removeCriterion(
          tester, 'active-tag-unavailable', '${S.current.Tags}: Unavailable');
      home.state.mapOrNull(loaded: (state) {
        expect(state.filters, {NoteSearchFilter.checklists});
        expect(state.selectedTags, {'Research'});
        expect(state.searchQuery, 'missing');
      });
      _expectScope(home,
          folderId: scope == 'trash' ? null : 'work',
          archive: scope == 'archive',
          trash: scope == 'trash',
          includeArchived: scope == 'all');

      // Keep the original empty-results recovery actions visible after the
      // independent tag-removal assertion above.
      await _send(tester, home,
          const HomeEvent.tagsChanged({'Unavailable', 'Research'}));

      for (final action in ['home-clear-search', 'home-clear-filters']) {
        await _tap(tester, action);
        _expectScope(home,
            folderId: scope == 'trash' ? null : 'work',
            archive: scope == 'archive',
            trash: scope == 'trash',
            includeArchived: scope == 'all');
      }
      expect(
          _visibleIds(home),
          switch (scope) {
            'all' => {'active-alpha', 'active-beta', 'archive-work'},
            'archive' => {'archive-work'},
            'trash' => {'trash-work', 'trash-personal'},
            _ => {'active-alpha', 'active-beta'},
          });
      expect(find.byKey(const ValueKey('home-clear-search')), findsNothing);
      expect(find.byKey(const ValueKey('home-clear-filters')), findsNothing);
      expect(
          find.byKey(const ValueKey('home-search-result-count')), findsNothing);
      expect(notes.writes, 0);
    });
  }

  testWidgets('selected summary remains visible after closing search',
      (tester) async {
    final (notes, home) = await _openHome(tester);
    final originalNotes =
        notes.getAllNotes().map((note) => note.toDomain()).toList();
    await _send(tester, home, const HomeEvent.selectFolder('work'));
    await _showSearch(tester);
    await tester.enterText(find.byType(TextField), 'Release');
    await tester.pumpAndSettle();
    await _send(
        tester,
        home,
        const HomeEvent.filtersChanged({
          NoteSearchFilter.recordings,
          NoteSearchFilter.scans,
          NoteSearchFilter.pinned,
        }));
    await _send(
        tester, home, const HomeEvent.tagsChanged({'  rEsEaRcH\t ', 'Unused'}));
    await _send(tester, home, const HomeEvent.includeArchived(true));
    await _tap(tester, 'home-more');
    await _tap(tester, 'home-search-menu');
    expect(find.byType(TextField), findsNothing);
    expect(find.byKey(const ValueKey('home-active-criteria-summary')),
        findsOneWidget);
    await _removeCriterion(
        tester, 'active-filter-scans', S.current.Filter_Scans);
    home.state.mapOrNull(loaded: (state) {
      expect(state.filters,
          {NoteSearchFilter.recordings, NoteSearchFilter.pinned});
      expect(state.selectedTags, {'rEsEaRcH', 'Unused'});
      expect(state.searchQuery, isEmpty);
    });
    await _removeCriterion(tester, 'active-tag-${tagKey('  RESEARCH ')}',
        '${S.current.Tags}: rEsEaRcH');
    home.state.mapOrNull(loaded: (state) {
      expect(state.filters,
          {NoteSearchFilter.recordings, NoteSearchFilter.pinned});
      expect(state.selectedTags, {'Unused'});
      expect(state.searchQuery, isEmpty);
    });
    _expectScope(home, folderId: 'work', includeArchived: true);
    await _removeCriterion(
        tester, 'active-scope-include-archived', S.current.Include_Archived);
    _expectScope(home, folderId: 'work');
    home.state.mapOrNull(loaded: (state) {
      expect(state.filters,
          {NoteSearchFilter.recordings, NoteSearchFilter.pinned});
      expect(state.selectedTags, {'Unused'});
    });
    expect(find.byType(TextField), findsNothing);
    expect(notes.getAllNotes().map((note) => note.toDomain()).toList(),
        originalNotes);
    expect(notes.writes, 0);
  });

  testWidgets(
      'stale include-archived removal preserves queued Archive and Trash',
      (tester) async {
    final (notes, home) = await _openHome(tester);
    final originalNotes =
        notes.getAllNotes().map((note) => note.toDomain()).toList();
    final savedPreferences = Map<String, String>.of(preferences.values);
    final savedViews = home.state.mapOrNull(
        loaded: (state) =>
            state.savedViews.map((view) => view.toJson()).toList());
    const filters = {NoteSearchFilter.pinned, NoteSearchFilter.recordings};
    const tags = {'Research', 'Unavailable'};
    await _send(tester, home, const HomeEvent.searchChanged('missing'));
    await _send(tester, home, const HomeEvent.filtersChanged(filters));
    await _send(tester, home, const HomeEvent.tagsChanged(tags));

    for (final scope in ['archive', 'trash']) {
      await _send(tester, home, const HomeEvent.selectFolder('work'));
      await _send(tester, home, const HomeEvent.includeArchived(true));
      _expectScope(home, folderId: 'work', includeArchived: true);
      final staleRemoval = tester
          .widget<InputChip>(
              find.byKey(const ValueKey('active-scope-include-archived')))
          .onDeleted!;

      // Capture the old UI action, queue a scope switch, then invoke the action
      // before that switch publishes state or removes its chip from the tree.
      home.add(scope == 'archive'
          ? const HomeEvent.showArchive(true)
          : const HomeEvent.showTrash(true));
      staleRemoval();
      await tester.pumpAndSettle();

      _expectScope(home, archive: scope == 'archive', trash: scope == 'trash');
      home.state.mapOrNull(loaded: (state) {
        expect(state.searchQuery, 'missing');
        expect(state.filters, filters);
        expect(state.selectedTags, tags);
        expect(
            state.savedViews.map((view) => view.toJson()).toList(), savedViews);
      });
      expect(find.byKey(const ValueKey('active-scope-include-archived')),
          findsNothing);
      expect(notes.getAllNotes().map((note) => note.toDomain()).toList(),
          originalNotes);
      expect(preferences.values, savedPreferences);
      expect(notes.writes, 0);
      expect(tester.takeException(), isNull);
    }
  });

  for (final (width, height, locale) in [
    (180.0, 844.0, const Locale('zh')),
    (568.0, 180.0, const Locale('zh', 'HK')),
  ]) {
    testWidgets(
        'closed-search criteria removals fit ${width}x$height at 2x in $locale',
        (tester) async {
      final (notes, home) = await _openHome(tester,
          width: width, height: height, textScale: 2, locale: locale);
      final originalNotes =
          notes.getAllNotes().map((note) => note.toDomain()).toList();
      await _send(tester, home, const HomeEvent.selectFolder('work'));
      await _send(tester, home, const HomeEvent.includeArchived(true));
      await _send(
          tester,
          home,
          const HomeEvent.filtersChanged({
            NoteSearchFilter.pinned,
            NoteSearchFilter.recordings,
          }));
      await _send(tester, home,
          const HomeEvent.tagsChanged({'Unavailable', 'Research'}));
      expect(find.byType(TextField), findsNothing);
      expect(find.byKey(const ValueKey('home-active-criteria-summary')),
          findsOneWidget);

      await _removeCriterion(
          tester, 'active-filter-recordings', S.current.Filter_Recordings);
      home.state.mapOrNull(loaded: (state) {
        expect(state.filters, {NoteSearchFilter.pinned});
        expect(state.selectedTags, {'Unavailable', 'Research'});
        expect(state.searchQuery, isEmpty);
      });
      _expectScope(home, folderId: 'work', includeArchived: true);
      await _removeCriterion(
          tester, 'active-tag-unavailable', '${S.current.Tags}: Unavailable');
      home.state.mapOrNull(loaded: (state) {
        expect(state.filters, {NoteSearchFilter.pinned});
        expect(state.selectedTags, {'Research'});
        expect(state.searchQuery, isEmpty);
      });
      _expectScope(home, folderId: 'work', includeArchived: true);
      expect(_visibleIds(home), {'active-beta'});
      expect(find.byType(TextField), findsNothing);
      expect(
          find.byKey(const ValueKey('active-filter-pinned')), findsOneWidget);
      expect(find.byKey(const ValueKey('active-tag-research')), findsOneWidget);
      expect(notes.getAllNotes().map((note) => note.toDomain()).toList(),
          originalNotes);
      expect(notes.writes, 0);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
      'result count follows query filters tags while folder totals stay stable',
      (tester) async {
    final (_, home) = await _openHome(tester);
    await _send(tester, home, const HomeEvent.selectFolder('work'));
    await _showSearch(tester);
    expect(
        find.byKey(const ValueKey('home-search-result-count')), findsNothing);
    await tester.enterText(find.byType(TextField), '   ');
    await tester.pumpAndSettle();
    expect(
        find.byKey(const ValueKey('home-search-result-count')), findsNothing);
    expect(find.byKey(const ValueKey('home-clear-search')), findsNothing);

    for (final (query, count) in [
      ('Release', 2),
      ('alpha', 1),
      ('missing', 0)
    ]) {
      await tester.enterText(find.byType(TextField), query);
      await tester.pumpAndSettle();
      _expectCount(tester, home, count);
      home.state.mapOrNull(loaded: (state) {
        expect(state.folderCounts, {'work': 2, 'personal': 1});
        expect(state.allNotesCount, 3);
      });
      expect(find.byKey(const ValueKey('home-clear-search')),
          count == 0 ? findsOneWidget : findsNothing);
      expect(find.byKey(const ValueKey('home-clear-filters')), findsNothing);
      expect(tester.takeException(), isNull);
    }

    await _tap(tester, 'home-clear-search');
    await _send(tester, home,
        const HomeEvent.filtersChanged({NoteSearchFilter.checklists}));
    _expectCount(tester, home, 1);
    await _send(tester, home, const HomeEvent.filtersChanged({}));
    await _send(tester, home, const HomeEvent.tagsChanged({'Research'}));
    _expectCount(tester, home, 2);
    await _send(tester, home, const HomeEvent.tagsChanged({'Unavailable'}));
    _expectCount(tester, home, 0);
    expect(find.byKey(const ValueKey('home-clear-search')), findsNothing);
    expect(find.byKey(const ValueKey('home-clear-filters')), findsOneWidget);
    await _tap(tester, 'home-clear-filters');
    expect(
        find.byKey(const ValueKey('home-search-result-count')), findsNothing);
    expect(_visibleIds(home), {'active-alpha', 'active-beta'});
  });

  testWidgets('scrolled grid survives repeated search recovery with semantics',
      (tester) async {
    final semantics = tester.ensureSemantics();
    try {
      final (_, home) =
          await _openHome(tester, disableAnimations: false, initial: [
        for (var index = 0; index < 30; index++)
          Note(
            id: 'note-$index',
            title: 'Release note $index',
            description:
                List.filled(index % 5 + 1, 'A varied height note.').join('\n'),
          ),
      ]);
      for (var cycle = 0; cycle < 3; cycle++) {
        final grid =
            Scrollable.of(tester.element(find.byType(SliverMasonryGrid)))
                .position;
        expect(grid.maxScrollExtent, greaterThan(0));
        grid.jumpTo(grid.maxScrollExtent * .6);
        await tester.pumpAndSettle();
        await _send(tester, home, const HomeEvent.searchChanged('missing'));
        _expectCount(tester, home, 0);
        await _tap(tester, 'home-clear-search');
        expect(_visibleIds(home).length, 30);
        expect(find.byType(SliverMasonryGrid), findsOneWidget);
        expect(tester.takeException(), isNull, reason: 'Recovery cycle $cycle');
      }
    } finally {
      semantics.dispose();
    }
  });

  for (final locale in S.delegate.supportedLocales) {
    testWidgets(
        'recovery and localized counts fit 320px at large text in $locale',
        (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        final (_, home) =
            await _openHome(tester, width: 320, textScale: 2, locale: locale);
        await _send(tester, home, const HomeEvent.selectFolder('work'));
        for (final (query, count) in [
          ('Release', 2),
          ('alpha', 1),
          ('missing', 0)
        ]) {
          await _send(tester, home, HomeEvent.searchChanged(query));
          _expectCount(tester, home, count);
        }
        await _send(tester, home,
            const HomeEvent.filtersChanged({NoteSearchFilter.pinned}));
        await _send(tester, home, const HomeEvent.tagsChanged({'Unavailable'}));
        expect(find.byKey(const ValueKey('home-active-criteria-summary')),
            findsOneWidget);
        await _removeCriterion(
            tester, 'active-filter-pinned', S.current.Filter_Pinned);
        home.state.mapOrNull(loaded: (state) {
          expect(state.searchQuery, 'missing');
          expect(state.selectedTags, {'Unavailable'});
          expect(state.filters, isEmpty);
        });
        await _send(tester, home,
            const HomeEvent.filtersChanged({NoteSearchFilter.pinned}));
        expect(find.byKey(const ValueKey('home-clear-search')), findsOneWidget);
        expect(
            find.byKey(const ValueKey('home-clear-filters')), findsOneWidget);
        await _tap(tester, 'home-clear-search');
        _expectCount(tester, home, 0);
        await _tap(tester, 'home-clear-filters');
        expect(_visibleIds(home), {'active-alpha', 'active-beta'});
        expect(tester.takeException(), isNull);
      } finally {
        semantics.dispose();
      }
    });
  }

  testWidgets('Android recovery fits narrow screens and preserves folder scope',
      (tester) async {
    final (_, home) = await _openHome(tester,
        width: 360, textScale: 1.5, platform: TargetPlatform.android);
    await _send(tester, home, const HomeEvent.selectFolder('work'));
    await _send(tester, home, const HomeEvent.searchChanged('missing'));
    await _send(tester, home,
        const HomeEvent.filtersChanged({NoteSearchFilter.pinned}));
    await _send(tester, home, const HomeEvent.tagsChanged({'Unavailable'}));
    _expectCount(tester, home, 0);
    await _tap(tester, 'home-clear-filters');
    _expectScope(home, folderId: 'work');
    _expectCount(tester, home, 0);
    await _tap(tester, 'home-clear-search');
    _expectScope(home, folderId: 'work');
    expect(_visibleIds(home), {'active-alpha', 'active-beta'});
    expect(tester.takeException(), isNull);
  });
}
