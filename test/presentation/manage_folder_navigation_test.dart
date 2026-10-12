import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
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
import 'package:onlynote/presentation/components/folder_name_dialog.dart';
import 'package:onlynote/presentation/routes/routes.dart';
import 'package:onlynote/presentation/screens/home/bloc/home_bloc.dart';
import 'package:onlynote/presentation/screens/home/bloc/multiple_delete/multiple_delete_bloc.dart';
import 'package:onlynote/presentation/screens/home/home_screen.dart';
import 'package:onlynote/presentation/screens/settings/manage_folders_screen.dart';
import 'package:onlynote/presentation/screens/settings/settings_screen.dart';
import 'package:onlynote/presentation/theme/theme.dart';
import 'package:onlynote/services/note_search.dart';
import 'package:onlynote/services/purchase_service.dart';
import 'package:onlynote/services/saved_note_views.dart';
import 'package:shared_preferences/shared_preferences.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
// ignore: depend_on_referenced_packages
import 'package:visibility_detector/visibility_detector.dart';

final _storedView = SavedNoteView(
  id: 'release-research',
  name: 'Release research',
  query: 'Release',
  filters: {NoteSearchFilter.pinned, NoteSearchFilter.checklists},
  tags: ['Research'],
  folderId: 'personal',
  archiveScope: NoteArchiveScope.all,
);

final class _Preferences extends SharedPreferencesAsyncPlatform {
  final values = <String, String>{
    SavedNoteViewStore.storageKey: jsonEncode({
      'version': 1,
      'views': [_storedView.toJson()],
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
  _Notes(this.box);
  final Box box;
  int writes = 0;

  @override
  List<NoteDto> getAllNotes() => box.values.cast<NoteDto>().toList();
  @override
  Future<NoteDto> getNote(String id) async => box.get(id) as NoteDto;
  @override
  Future<void> addUpdateNote(NoteDto note) async {
    writes++;
    await box.put(note.id, note);
  }

  @override
  Future<void> deleteNote(String id) async {
    writes++;
    await box.delete(id);
  }

  @override
  Future<void> deleteMultiNotes(List<String> ids) async {
    writes++;
    await box.deleteAll(ids);
  }
}

class _Folders implements FolderRepository {
  _Folders(this.box);
  final Box box;
  int writes = 0;

  @override
  List<FolderDto> getAllFolders() => box.values.cast<FolderDto>().toList();
  @override
  Future<void> addUpdateFolder(FolderDto folder) async {
    writes++;
    await box.put(folder.id, folder);
  }

  @override
  Future<void> deleteFolder(String id) async {
    writes++;
    await box.delete(id);
  }
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

class _Observer extends NavigatorObserver {
  final popped = <Route<dynamic>>[];
  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    popped.add(route);
    super.didPop(route, previousRoute);
  }
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

class _Fixture {
  _Fixture(this.notes, this.folders, this.home, this.selection, this.observer);
  final _Notes notes;
  final _Folders folders;
  final HomeBloc home;
  final MultipleDeleteBloc selection;
  final _Observer observer;
}

Finder _key(String key) => find.byKey(ValueKey(key));

Future<void> _tap(WidgetTester tester, String key) async {
  final target = _key(key);
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

Future<void> _send(WidgetTester tester, HomeBloc home, HomeEvent event) async {
  home.add(event);
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

Future<void> _openManagement(WidgetTester tester, String entry) async {
  if (entry == 'settings') {
    await _tap(tester, 'home-settings');
    expect(find.byType(SettingsScreen), findsOneWidget);
    expect(
        tester
            .widget<SettingsScreen>(find.byType(SettingsScreen))
            .returnFolderSelection,
        isTrue);
    await _tap(tester, 'settings-manage-folders');
  } else {
    await _tap(tester, 'home-folder-picker');
    await _tap(tester, 'home-manage-folders');
  }
  expect(find.byType(ManageFoldersScreen), findsOneWidget);
}

Future<void> _selectCriteria(
    WidgetTester tester, HomeBloc home, String scope) async {
  await _send(
      tester,
      home,
      HomeEvent.applySavedView(SavedNoteView(
        id: _storedView.id,
        name: _storedView.name,
        query: _storedView.query,
        filters: _storedView.filters,
        tags: _storedView.tags,
        folderId: _storedView.folderId,
        archiveScope: switch (scope) {
          'archive' => NoteArchiveScope.archived,
          'all' => NoteArchiveScope.all,
          _ => NoteArchiveScope.active,
        },
      )));
  if (scope == 'trash') {
    await _send(tester, home, const HomeEvent.showTrash(true));
  }
}

void _expectCriteria(HomeBloc home, String scope, {String? folderId = 'work'}) {
  home.state.mapOrNull(loaded: (state) {
    expect(state.selectedFolderId, folderId);
    expect(state.searchQuery, _storedView.query);
    expect(state.filters, _storedView.filters);
    expect(state.selectedTags, _storedView.tags.toSet());
    expect(state.showArchive, scope == 'archive');
    expect(state.showTrash, scope == 'trash');
    expect(state.includeArchived, scope == 'all');
  });
}

void main() {
  final fonts = Map<String, GoogleFontBuilder>.of(kAppFontFamilies);
  final originalPlatform = SharedPreferencesAsyncPlatform.instance;
  final preferences = _Preferences();
  final visibilityInterval =
      VisibilityDetectorController.instance.updateInterval;
  late Directory directory;
  late Box notesBox;
  late Box foldersBox;

  setUpAll(() async {
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
    await initializeDateFormatting();
    if (!locator.isRegistered<S>()) locator.registerSingleton(S());
    SharedPreferencesAsyncPlatform.instance = preferences;
    // Parse persisted views before any widget-test fake clock owns the queue.
    await SavedNoteViewStore.instance.load();
    expect(SavedNoteViewStore.instance.views.map((view) => view.toJson()),
        [_storedView.toJson()]);
    directory = await Directory.systemTemp.createTemp('onlynote-folder-nav-');
    Hive.init(directory.path);
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(TodoDtoAdapter());
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(NoteDtoAdapter());
    if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(FolderDtoAdapter());
    notesBox = await Hive.openBox(databaseBox);
    foldersBox = await Hive.openBox(folderDatabaseBox);
    SharedPreferences.setMockInitialValues({'remove_ads_entitlement': true});
    final platform = debugDefaultTargetPlatformOverride;
    try {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      await PurchaseService.instance.init();
    } finally {
      debugDefaultTargetPlatformOverride = platform;
    }
  });

  setUp(() async {
    for (final family in fonts.keys) {
      kAppFontFamilies[family] = (
              {textStyle, color, fontSize, fontWeight, fontStyle}) =>
          (textStyle ?? const TextStyle()).copyWith(
              color: color,
              fontSize: fontSize,
              fontWeight: fontWeight,
              fontStyle: fontStyle);
    }
    await notesBox.clear();
    await foldersBox.clear();
    await foldersBox.putAll({
      'work': FolderDto(id: 'work', name: 'Work'),
      'personal': FolderDto(id: 'personal', name: 'Personal'),
    });
    for (final folder in ['work', 'personal']) {
      for (final scope in ['active', 'archive', 'trash']) {
        final id = '$scope-$folder';
        await notesBox.put(
            id,
            NoteDto.fromNote(Note(
              id: id,
              title: 'Release $scope $folder',
              description: 'Keep the saved note metadata.',
              folderId: folder,
              tags: ['Research'],
              isPinned: true,
              isArchived: scope == 'archive',
              deletedAt: scope == 'trash' ? DateTime.utc(2026, 10, 6) : null,
              todo: [Todo(id: 'task-$id', title: 'Review release')],
            )));
      }
    }
  });
  tearDown(() => kAppFontFamilies.addAll(fonts));
  tearDownAll(() async {
    VisibilityDetectorController.instance.updateInterval = visibilityInterval;
    SharedPreferencesAsyncPlatform.instance = originalPlatform;
    await notesBox.close();
    await foldersBox.close();
    await directory.delete(recursive: true);
  });

  Future<_Fixture> open(WidgetTester tester,
      {Widget? rootScreen,
      double width = 390,
      double textScale = 1,
      Locale locale = const Locale('en')}) async {
    tester.view.physicalSize = Size(width, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final notes = _Notes(notesBox);
    final folders = _Folders(foldersBox);
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
    final observer = _Observer();
    final router = rootScreen == null ? _Router() : null;
    getIt.pushNewScope();
    getIt.registerSingleton<NoteRepository>(notes);
    getIt.registerSingleton<FolderRepository>(folders);
    getIt.registerSingleton<Database>(_Database(notesBox));
    Widget adapt(BuildContext context, Widget? child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
              disableAnimations: true,
              textScaler: TextScaler.linear(textScale)),
          child: child!,
        );
    const delegates = <LocalizationsDelegate<dynamic>>[
      S.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate
    ];
    final app = router != null
        ? MaterialApp.router(
            routerConfig: router.config(navigatorObservers: () => [observer]),
            theme: AppTheme.light,
            locale: locale,
            supportedLocales: S.delegate.supportedLocales,
            localizationsDelegates: delegates,
            builder: adapt)
        : MaterialApp(
            home: rootScreen,
            navigatorObservers: [observer],
            theme: AppTheme.light,
            locale: locale,
            supportedLocales: S.delegate.supportedLocales,
            localizationsDelegates: delegates,
            builder: adapt);
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 3));
      router?.dispose();
      await home.close();
      await selection.close();
      await getIt.popScope();
    });
    await tester.pumpWidget(MultiBlocProvider(
      providers: [
        BlocProvider.value(value: home),
        BlocProvider.value(value: selection)
      ],
      child: app,
    ));
    await _send(tester, home, const HomeEvent.getAllNotes());
    // Seed the navigation fixture through Home's normal store-sync event.
    // The singleton payload was parsed on the real clock in setUpAll; its
    // cached future queue should not be awaited across widget-test clocks.
    await _send(tester, home,
        HomeEvent.savedViewsChanged(SavedNoteViewStore.instance.views));
    if (rootScreen == null) {
      home.state.mapOrNull(loaded: (state) {
        expect(state.savedViews.map((view) => view.toJson()),
            [_storedView.toJson()]);
      });
    }
    return _Fixture(notes, folders, home, selection, observer);
  }

  for (final entry in ['picker', 'settings']) {
    for (final scope in ['active', 'all', 'archive', 'trash']) {
      testWidgets(
          '$entry managed folder preserves $scope criteria without writes',
          (tester) async {
        final fixture = await open(tester);
        final originalNotes =
            fixture.notes.getAllNotes().map((n) => n.toDomain()).toList();
        final originalFolders =
            fixture.folders.getAllFolders().map((f) => f.toDomain()).toList();
        final originalPreferences = Map<String, String>.of(preferences.values);
        await _selectCriteria(tester, fixture.home, scope);
        await _openManagement(tester, entry);
        await _tap(tester, 'managed-folder-work');
        expect(find.byType(ManageFoldersScreen), findsNothing);
        expect(find.byType(SettingsScreen), findsNothing);
        expect(find.byType(HomeScreen), findsOneWidget);
        _expectCriteria(fixture.home, scope);
        final expectedTitle = switch (scope) {
          'archive' => '${S.current.Archive} · Work',
          'trash' => '${S.current.Trash} · Work',
          _ => 'Work',
        };
        expect(
            find.descendant(
                of: _key('home-folder-picker'),
                matching: find.text(expectedTitle)),
            findsOneWidget);
        fixture.home.state.mapOrNull(loaded: (state) {
          expect(state.selectedViewId, isNull);
          expect(
              state.savedViews.map((v) => v.toJson()), [_storedView.toJson()]);
          expect(
              state.notes.map((note) => note.id).toSet(),
              switch (scope) {
                'all' => {'active-work', 'archive-work'},
                'archive' => {'archive-work'},
                'trash' => {'trash-work'},
                _ => {'active-work'},
              });
        });
        expect(fixture.notes.getAllNotes().map((n) => n.toDomain()).toList(),
            originalNotes);
        expect(
            fixture.folders.getAllFolders().map((f) => f.toDomain()).toList(),
            originalFolders);
        expect(preferences.values, originalPreferences);
        expect(fixture.notes.writes, 0);
        expect(fixture.folders.writes, 0);
      });
    }
  }

  testWidgets(
      'rapid row callbacks pop only management and clear note selection',
      (tester) async {
    final fixture = await open(tester);
    await _selectCriteria(tester, fixture.home, 'all');
    await _openManagement(tester, 'picker');
    fixture.selection
        .add(const MultipleDeleteEvent.toggleSelect('active-personal'));
    await tester.pumpAndSettle();
    expect(
        fixture.selection.state
            .maybeMap(selected: (_) => true, orElse: () => false),
        isTrue);
    final callback =
        tester.widget<ListTile>(_key('managed-folder-work')).onTap!;
    final pops = fixture.observer.popped.length;
    callback();
    callback();
    await tester.pumpAndSettle();
    expect(fixture.observer.popped.length, pops + 1);
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(Navigator.of(tester.element(find.byType(HomeScreen))).canPop(),
        isFalse);
    expect(
        fixture.selection.state
            .maybeMap(initial: (_) => true, orElse: () => false),
        isTrue);
    _expectCriteria(fixture.home, 'all');
    expect(fixture.notes.writes, 0);
    expect(fixture.folders.writes, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('edit popup and covered-route callback do not open a folder',
      (tester) async {
    final fixture = await open(tester);
    await _selectCriteria(tester, fixture.home, 'all');
    await _openManagement(tester, 'picker');
    final callback =
        tester.widget<ListTile>(_key('managed-folder-work')).onTap!;
    await _tap(tester, 'managed-folder-work-menu');
    expect(find.byType(ManageFoldersScreen), findsOneWidget);
    await tester.tap(find.text(S.current.Rename_Folder));
    await tester.pumpAndSettle();
    expect(find.byType(FolderNameDialog), findsOneWidget);
    callback();
    await tester.pumpAndSettle();
    expect(find.byType(FolderNameDialog), findsOneWidget);
    await tester.tap(find.text(S.current.Cancel));
    await tester.pumpAndSettle();
    expect(find.byType(ManageFoldersScreen), findsOneWidget);
    _expectCriteria(fixture.home, 'all', folderId: 'personal');
    expect(fixture.folders.box.get('work').name, 'Work');
    expect(fixture.notes.writes, 0);
    expect(fixture.folders.writes, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('deleted folder rejects a captured row callback safely',
      (tester) async {
    final fixture = await open(tester);
    await _selectCriteria(tester, fixture.home, 'all');
    await _openManagement(tester, 'picker');
    final callback =
        tester.widget<ListTile>(_key('managed-folder-work')).onTap!;
    final pops = fixture.observer.popped.length;
    await tester.runAsync(() => foldersBox.delete('work'));
    callback();
    await tester.pumpAndSettle();
    expect(find.byType(ManageFoldersScreen), findsOneWidget);
    expect(fixture.observer.popped.length, pops);
    expect(find.text(S.current.Folder_Unavailable), findsOneWidget);
    _expectCriteria(fixture.home, 'all', folderId: 'personal');
    expect(fixture.notes.writes, 0);
    expect(fixture.folders.writes, 0);
    await tester.pump(const Duration(seconds: 3));
    expect(tester.takeException(), isNull);
  });

  testWidgets('managed selection validates a deleted folder after cached load',
      (tester) async {
    final fixture = await open(tester);
    await _selectCriteria(tester, fixture.home, 'all');
    await tester.runAsync(() => foldersBox.delete('work'));
    fixture.home.state.mapOrNull(loaded: (state) {
      expect(state.folders.any((f) => f.id == 'work'), isTrue);
    });
    await _send(tester, fixture.home,
        const HomeEvent.selectFolder('work', preserveScope: true));
    _expectCriteria(fixture.home, 'all', folderId: 'personal');
    fixture.home.state.mapOrNull(loaded: (state) {
      expect(state.selectedViewId, _storedView.id);
    });
    expect(fixture.notes.writes, 0);
    expect(fixture.folders.writes, 0);
  });

  testWidgets('root management stays open when there is no return route',
      (tester) async {
    final fixture = await open(tester, rootScreen: const ManageFoldersScreen());
    await _selectCriteria(tester, fixture.home, 'all');
    await _tap(tester, 'managed-folder-work');
    expect(find.byType(ManageFoldersScreen), findsOneWidget);
    expect(fixture.observer.popped, isEmpty);
    _expectCriteria(fixture.home, 'all', folderId: 'personal');
    expect(fixture.notes.writes, 0);
    expect(fixture.folders.writes, 0);
  });

  testWidgets(
      'standalone Settings returns from management without leaving Settings',
      (tester) async {
    final fixture = await open(tester, rootScreen: const SettingsScreen());
    await _selectCriteria(tester, fixture.home, 'all');
    await _tap(tester, 'settings-manage-folders');
    await _tap(tester, 'managed-folder-work');
    expect(find.byType(SettingsScreen), findsOneWidget);
    expect(find.byType(ManageFoldersScreen), findsNothing);
    expect(fixture.observer.popped, hasLength(1));
    _expectCriteria(fixture.home, 'all', folderId: 'personal');
    expect(fixture.notes.writes, 0);
    expect(fixture.folders.writes, 0);
  });

  testWidgets('ordinary picker still leaves Archive for active folder notes',
      (tester) async {
    final fixture = await open(tester);
    await _selectCriteria(tester, fixture.home, 'archive');
    await _tap(tester, 'home-folder-picker');
    await tester.tap(find.text('Work'));
    await tester.pumpAndSettle();
    _expectCriteria(fixture.home, 'active');
    fixture.home.state.mapOrNull(loaded: (state) {
      expect(state.notes.map((note) => note.id), ['active-work']);
    });
    expect(fixture.notes.writes, 0);
    expect(fixture.folders.writes, 0);
    expect(tester.takeException(), isNull);
  });

  for (final locale in S.delegate.supportedLocales) {
    testWidgets('managed row navigation fits 320px at 2x in $locale',
        (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        final fixture =
            await open(tester, width: 320, textScale: 2, locale: locale);
        await _selectCriteria(tester, fixture.home, 'all');
        await _openManagement(tester, 'picker');
        final row = _key('managed-folder-work');
        await tester.ensureVisible(row);
        await tester.pumpAndSettle();
        expect(tester.getSize(row).height, greaterThanOrEqualTo(48));
        expect(tester.getSemantics(row).getSemanticsData().hint,
            contains(S.current.Open_Folder_In_Library('Work')));
        await _tap(tester, 'managed-folder-work');
        _expectCriteria(fixture.home, 'all');
        expect(fixture.notes.writes, 0);
        expect(fixture.folders.writes, 0);
        expect(tester.takeException(), isNull);
      } finally {
        semantics.dispose();
      }
    });
  }
}
