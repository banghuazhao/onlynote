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
import 'package:onlynote/presentation/components/app_sheet.dart';
import 'package:onlynote/presentation/components/search_highlight.dart';
import 'package:onlynote/presentation/screens/home/widgets/note_card.dart';
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
  _Notes(Box box)
      : values = {
          for (final note in box.values.cast<NoteDto>()) note.id!: note,
        };
  final Map<String, NoteDto> values;
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
  Future<void> deleteNote(String id) async {
    writes++;
    values.remove(id);
  }

  @override
  Future<void> deleteMultiNotes(List<String> ids) async {
    writes++;
    ids.forEach(values.remove);
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

class _Router extends AppRouter {
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

Future<void> _openFolderPicker(WidgetTester tester) async {
  if (_key('home-folder-picker').evaluate().isNotEmpty) {
    await _tap(tester, 'home-folder-picker');
  } else {
    await _tap(tester, 'home-more');
    final folders = find.byWidgetPredicate((widget) =>
        widget is PopupMenuItem<String> && widget.value == 'folders');
    expect(folders, findsOneWidget);
    await tester.ensureVisible(folders);
    await tester.tap(folders);
    await tester.pumpAndSettle();
  }
  expect(_key('folder-picker-search'), findsOneWidget);
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
    await _openFolderPicker(tester);
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

Future<void> _search(WidgetTester tester, String prefix, String query) async {
  final field = _key('$prefix-search');
  await tester.ensureVisible(field);
  await tester.enterText(field, query);
  await tester.pumpAndSettle();
  expect(tester.widget<TextField>(field).controller!.text, query);
  expect(tester.takeException(), isNull);
}

ListTile _rowTile(WidgetTester tester, String key) {
  final row = _key(key);
  if (tester.widget(row) is ListTile) return tester.widget<ListTile>(row);
  return tester.widget<ListTile>(
      find.descendant(of: row, matching: find.byType(ListTile)));
}

void _expectUnchanged(
    _Fixture fixture, HomeState state, List<Note> notes, List<Object> folders) {
  expect(fixture.home.state, state);
  expect(fixture.notes.getAllNotes().map((note) => note.toDomain()).toList(),
      notes);
  expect(
      fixture.folders
          .getAllFolders()
          .map((folder) => folder.toDomain())
          .toList(),
      folders);
  expect(fixture.notes.writes, 0);
  expect(fixture.folders.writes, 0);
}

Future<void> _openMoveSheet(WidgetTester tester, String noteId) async {
  final card = find.byWidgetPredicate(
      (widget) => widget is NoteCard && widget.note.id == noteId);
  await tester.ensureVisible(card);
  await tester.pumpAndSettle();
  await tester.longPress(card);
  await tester.pumpAndSettle();
  final action = find.descendant(
      of: find.byType(AppSheet), matching: find.text(S.current.Move_To_Folder));
  await tester.ensureVisible(action);
  await tester.tap(action);
  await tester.pumpAndSettle();
  expect(_key('move-to-folder-search'), findsOneWidget);
  expect(tester.takeException(), isNull);
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
    directory =
        await Directory.systemTemp.createTemp('onlynote-folder-search-');
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
      'work': FolderDto(id: 'work', name: 'Work [draft]', sortOrder: 3),
      'personal': FolderDto(id: 'personal', name: 'Personal', sortOrder: 2),
      'unicode': FolderDto(id: 'unicode', name: '工作💡', sortOrder: 1),
      'workshop': FolderDto(id: 'workshop', name: 'Workshop', sortOrder: 4),
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
    if (router != null) getIt.registerSingleton<AppRouter>(router);
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

  testWidgets(
      'folder picker accepts one selection and ignores disposed callbacks',
      (tester) async {
    final fixture = await open(tester);
    await _openFolderPicker(tester);
    final choose = _rowTile(tester, 'folder-picker-folder-work').onTap!;
    final pops = fixture.observer.popped.length;
    choose();
    choose();
    await tester.pumpAndSettle();
    choose();
    expect(fixture.observer.popped.length, pops + 1);
    expect(find.byType(HomeScreen), findsOneWidget);
    fixture.home.state.mapOrNull(loaded: (state) {
      expect(state.selectedFolderId, 'work');
    });
    expect(fixture.notes.writes, 0);
    expect(fixture.folders.writes, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('covered or cancelled folder picker cannot dismiss another route',
      (tester) async {
    final fixture = await open(tester);
    await _openFolderPicker(tester);
    final choose = _rowTile(tester, 'folder-picker-folder-work').onTap!;
    final sheetContext = tester.element(find.byType(AppSheet));
    showDialog<void>(
      context: sheetContext,
      builder: (_) => const AlertDialog(title: Text('Another action')),
    );
    await tester.pumpAndSettle();
    final pops = fixture.observer.popped.length;
    choose();
    await tester.pumpAndSettle();
    expect(find.text('Another action'), findsOneWidget);
    expect(fixture.observer.popped.length, pops);
    Navigator.of(tester.element(find.byType(AlertDialog))).pop();
    await tester.pumpAndSettle();
    final close = tester
        .widget<IconButton>(find.byWidgetPredicate(
            (widget) => widget is IconButton && widget.tooltip == 'Close'))
        .onPressed!;
    close();
    choose();
    await tester.pumpAndSettle();
    choose();
    expect(fixture.observer.popped.length, pops + 2);
    expect(find.byType(HomeScreen), findsOneWidget);
    fixture.home.state.mapOrNull(loaded: (state) {
      expect(state.selectedFolderId, isNull);
    });
    expect(fixture.notes.writes, 0);
    expect(fixture.folders.writes, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Home cards refresh folder labels and hide redundant scope labels',
    (tester) async {
      final fixture = await open(tester);
      Finder card(String id) => find.byWidgetPredicate(
            (widget) => widget is NoteCard && widget.note.id == id,
          );
      Finder label(String id) =>
          find.descendant(of: card(id), matching: _key('card-folder'));
      expect(
        find.descendant(
          of: label('active-work'),
          matching: find.text('Work [draft]'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: label('active-personal'),
          matching: find.text('Personal'),
        ),
        findsOneWidget,
      );

      await _send(tester, fixture.home, const HomeEvent.selectFolder('work'));
      expect(card('active-work'), findsOneWidget);
      expect(label('active-work'), findsNothing);
      await _send(tester, fixture.home, const HomeEvent.selectFolder(null));
      await _send(
        tester,
        fixture.home,
        const HomeEvent.searchChanged('Release'),
      );
      expect(label('active-work'), findsOneWidget);

      await tester.runAsync(() async {
        await foldersBox.put(
          'work',
          FolderDto(id: 'work', name: '工作與研究 👩🏽‍💻', sortOrder: 3),
        );
      });
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: label('active-work'),
          matching: find.text('工作與研究 👩🏽‍💻'),
        ),
        findsOneWidget,
      );

      await tester.runAsync(() => foldersBox.delete('work'));
      await tester.pumpAndSettle();
      expect(card('active-work'), findsOneWidget);
      expect(label('active-work'), findsNothing);
      expect(label('active-personal'), findsOneWidget);
      expect(fixture.notes.values['active-work']!.folderId, 'work');
      expect(fixture.notes.writes, 0);
      expect(fixture.folders.writes, 0);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
      'Home picker searches literal names while retaining fixed actions and counts',
      (tester) async {
    final fixture = await open(tester);
    await _selectCriteria(tester, fixture.home, 'all');
    final state = fixture.home.state;
    final notes =
        fixture.notes.getAllNotes().map((note) => note.toDomain()).toList();
    final folders = fixture.folders
        .getAllFolders()
        .map((folder) => folder.toDomain())
        .toList();
    final stored = Map<String, String>.of(preferences.values);
    await _openFolderPicker(tester);
    for (final id in ['unicode', 'personal', 'work', 'workshop']) {
      expect(_key('folder-picker-folder-$id'), findsOneWidget);
    }
    expect(tester.getTopLeft(_key('folder-picker-folder-unicode')).dy,
        lessThan(tester.getTopLeft(_key('folder-picker-folder-personal')).dy));
    expect(
        find.descendant(
            of: _key('folder-picker-folder-work'), matching: find.text('1')),
        findsOneWidget);
    final selectedPersonal =
        _rowTile(tester, 'folder-picker-folder-personal').selected;
    expect(selectedPersonal, isTrue);

    await _search(tester, 'folder-picker', '  wOrK  ');
    expect(_key('folder-picker-folder-personal'), findsNothing);
    expect(_key('folder-picker-folder-unicode'), findsNothing);
    expect(_key('folder-picker-folder-work'), findsOneWidget);
    expect(_key('folder-picker-folder-workshop'), findsOneWidget);
    expect(tester.getTopLeft(_key('folder-picker-folder-work')).dy,
        lessThan(tester.getTopLeft(_key('folder-picker-folder-workshop')).dy));
    expect(
        find.descendant(
            of: _key('folder-picker-folder-work'), matching: find.text('1')),
        findsOneWidget);
    await _search(tester, 'folder-picker', '[draft]');
    expect(_key('folder-picker-folder-work'), findsOneWidget);
    expect(_key('folder-picker-folder-workshop'), findsNothing);
    final highlight = tester.widget<SearchHighlight>(find.descendant(
        of: _key('folder-picker-folder-work'),
        matching: find.byType(SearchHighlight)));
    expect(highlight.text, 'Work [draft]');
    expect(highlight.query, '[draft]');
    await _search(tester, 'folder-picker', ' 工作💡 ');
    expect(_key('folder-picker-folder-unicode'), findsOneWidget);
    expect(_key('folder-picker-folder-work'), findsNothing);
    await _search(tester, 'folder-picker', 'not a folder');
    expect(_key('folder-picker-search-empty'), findsOneWidget);
    for (final label in [
      S.current.All_Notes,
      S.current.Archive,
      S.current.Trash,
      S.current.New_Folder,
      S.current.Manage_Folders
    ]) {
      expect(
          find.descendant(
              of: find.byType(AppSheet), matching: find.text(label)),
          findsOneWidget);
    }
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<EditableText>(find.descendant(
                of: _key('folder-picker-search'),
                matching: find.byType(EditableText)))
            .focusNode
            .hasFocus,
        isFalse);
    await _tap(tester, 'folder-picker-clear-search');
    expect(_key('folder-picker-search-empty'), findsNothing);
    expect(_rowTile(tester, 'folder-picker-folder-personal').selected,
        selectedPersonal);
    for (final id in ['unicode', 'personal', 'work', 'workshop']) {
      expect(_key('folder-picker-folder-$id'), findsOneWidget);
    }
    _expectUnchanged(fixture, state, notes, folders);
    expect(preferences.values, stored);
  });

  testWidgets(
      'filtered ordinary picker selection keeps original ID and resets Archive scope',
      (tester) async {
    final fixture = await open(tester);
    await _selectCriteria(tester, fixture.home, 'archive');
    await _openFolderPicker(tester);
    await _search(tester, 'folder-picker', ' [DRAFT] ');
    await _tap(tester, 'folder-picker-folder-work');
    _expectCriteria(fixture.home, 'active');
    fixture.home.state.mapOrNull(loaded: (state) {
      expect(state.selectedViewId, isNull);
      expect(state.savedViews.map((view) => view.toJson()),
          [_storedView.toJson()]);
      expect(state.notes.map((note) => note.id), ['active-work']);
    });
    expect(fixture.notes.writes, 0);
    expect(fixture.folders.writes, 0);
  });

  for (final entry in ['picker', 'settings']) {
    testWidgets(
        '$entry filtered management keeps counts and edit separate from navigation',
        (tester) async {
      final fixture = await open(tester);
      await _selectCriteria(tester, fixture.home, 'all');
      final originalNotes =
          fixture.notes.getAllNotes().map((note) => note.toDomain()).toList();
      final originalFolders = fixture.folders
          .getAllFolders()
          .map((folder) => folder.toDomain())
          .toList();
      final stored = Map<String, String>.of(preferences.values);
      await _openManagement(tester, entry);
      await _search(tester, 'managed-folders', ' work ');
      final highlight = tester.widget<SearchHighlight>(find.descendant(
          of: _key('managed-folder-work'),
          matching: find.byType(SearchHighlight)));
      expect(highlight.text, 'Work [draft]');
      expect(highlight.query, ' work ');
      expect(_key('managed-folder-personal'), findsNothing);
      expect(_key('managed-folder-work'), findsOneWidget);
      expect(_key('managed-folder-workshop'), findsOneWidget);
      expect(
          find.descendant(
              of: _key('managed-folder-work'),
              matching: find.text(S.current.Folder_Notes_Count(2))),
          findsOneWidget);
      expect(tester.getTopLeft(_key('managed-folder-work')).dy,
          lessThan(tester.getTopLeft(_key('managed-folder-workshop')).dy));
      final pops = fixture.observer.popped.length;
      await _tap(tester, 'managed-folder-work-menu');
      await tester.tap(find.text(S.current.Rename_Folder));
      await tester.pumpAndSettle();
      expect(find.byType(FolderNameDialog), findsOneWidget);
      await tester.tap(find.text(S.current.Cancel));
      await tester.pumpAndSettle();
      expect(fixture.observer.popped.length, pops + 2);
      expect(find.byType(ManageFoldersScreen), findsOneWidget);
      expect(
          tester
              .widget<TextField>(_key('managed-folders-search'))
              .controller!
              .text,
          ' work ');
      _expectCriteria(fixture.home, 'all', folderId: 'personal');
      await _tap(tester, 'managed-folder-work');
      expect(find.byType(ManageFoldersScreen), findsNothing);
      expect(find.byType(SettingsScreen), findsNothing);
      _expectCriteria(fixture.home, 'all');
      fixture.home.state.mapOrNull(loaded: (state) {
        expect(state.selectedViewId, isNull);
        expect(state.savedViews.map((view) => view.toJson()),
            [_storedView.toJson()]);
      });
      expect(
          fixture.notes.getAllNotes().map((note) => note.toDomain()).toList(),
          originalNotes);
      expect(
          fixture.folders
              .getAllFolders()
              .map((folder) => folder.toDomain())
              .toList(),
          originalFolders);
      expect(preferences.values, stored);
      expect(fixture.notes.writes, 0);
      expect(fixture.folders.writes, 0);
    });
  }

  testWidgets(
      'management reacts to live folder changes without resetting its search',
      (tester) async {
    final fixture = await open(tester);
    await _selectCriteria(tester, fixture.home, 'all');
    await _openManagement(tester, 'picker');
    await _search(tester, 'managed-folders', ' work ');
    await tester.runAsync(() async {
      await foldersBox.put(
          'work', FolderDto(id: 'work', name: 'Renamed', sortOrder: 3));
      await foldersBox.delete('workshop');
      await foldersBox.put('new-work',
          FolderDto(id: 'new-work', name: 'Work new', sortOrder: 5));
    });
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<TextField>(_key('managed-folders-search'))
            .controller!
            .text,
        ' work ');
    expect(_key('managed-folder-work'), findsNothing);
    expect(_key('managed-folder-workshop'), findsNothing);
    expect(_key('managed-folder-new-work'), findsOneWidget);
    expect(
        find.descendant(
            of: _key('managed-folder-new-work'),
            matching: find.text(S.current.Folder_Notes_Count(0))),
        findsOneWidget);
    await _search(tester, 'managed-folders', 'unmatched');
    expect(_key('managed-folders-search-empty'), findsOneWidget);
    expect(find.widgetWithText(FloatingActionButton, S.current.New_Folder),
        findsOneWidget);
    await _tap(tester, 'managed-folders-clear-search');
    expect(_key('managed-folders-search-empty'), findsNothing);
    expect(_key('managed-folder-work'), findsOneWidget);
    expect(
        find.descendant(
            of: _key('managed-folder-work'), matching: find.text('Renamed')),
        findsOneWidget);
    expect(_key('managed-folder-workshop'), findsNothing);
    expect(_key('managed-folder-new-work'), findsOneWidget);
    _expectCriteria(fixture.home, 'all', folderId: 'personal');
    expect(fixture.notes.writes, 0);
    expect(fixture.folders.writes, 0);
  });

  testWidgets(
      'card move sheet searches without writes and moves only the chosen original folder ID',
      (tester) async {
    final fixture = await open(tester);
    await _selectCriteria(tester, fixture.home, 'all');
    final state = fixture.home.state;
    final notes =
        fixture.notes.getAllNotes().map((note) => note.toDomain()).toList();
    final folders = fixture.folders
        .getAllFolders()
        .map((folder) => folder.toDomain())
        .toList();
    final stored = Map<String, String>.of(preferences.values);
    await _openMoveSheet(tester, 'active-personal');
    expect(_rowTile(tester, 'move-to-folder-folder-personal').selected, isTrue);
    await _search(tester, 'move-to-folder', '[draft]');
    expect(_key('move-to-folder-folder-work'), findsOneWidget);
    expect(_key('move-to-folder-folder-workshop'), findsNothing);
    await _search(tester, 'move-to-folder', 'unmatched');
    expect(_key('move-to-folder-search-empty'), findsOneWidget);
    expect(_key('move-to-folder-none'), findsOneWidget);
    expect(_key('move-to-folder-cancel'), findsOneWidget);
    await _tap(tester, 'move-to-folder-clear-search');
    expect(_rowTile(tester, 'move-to-folder-folder-personal').selected, isTrue);
    _expectUnchanged(fixture, state, notes, folders);
    expect(preferences.values, stored);
    await _search(tester, 'move-to-folder', ' 工作💡 ');
    await _tap(tester, 'move-to-folder-folder-unicode');
    await tester.pumpAndSettle();
    expect(_key('move-to-folder-search'), findsNothing);
    expect(fixture.notes.writes, 1);
    expect(fixture.folders.writes, 0);
    expect(
        fixture.notes.getAllNotes().map((note) => note.toDomain()).toList(), [
      for (final note in notes)
        note.id == 'active-personal' ? note.copyWith(folderId: 'unicode') : note
    ]);
    expect(
        fixture.folders
            .getAllFolders()
            .map((folder) => folder.toDomain())
            .toList(),
        folders);
    expect(preferences.values, stored);
    _expectCriteria(fixture.home, 'all', folderId: 'personal');
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'cancel filtered card move sheet leaves notes and criteria untouched',
      (tester) async {
    final fixture = await open(tester);
    await _selectCriteria(tester, fixture.home, 'all');
    final state = fixture.home.state;
    final notes =
        fixture.notes.getAllNotes().map((note) => note.toDomain()).toList();
    final folders = fixture.folders
        .getAllFolders()
        .map((folder) => folder.toDomain())
        .toList();
    await _openMoveSheet(tester, 'active-personal');
    await _search(tester, 'move-to-folder', 'unmatched');
    await _tap(tester, 'move-to-folder-cancel');
    expect(_key('move-to-folder-search'), findsNothing);
    _expectUnchanged(fixture, state, notes, folders);
  });

  for (final (locale, width) in [
    (const Locale('en'), 180.0),
    (const Locale('zh', 'HK'), 320.0),
  ]) {
    testWidgets(
        '$locale folder picker and management search fit ${width}px at 2x',
        (tester) async {
      final fixture =
          await open(tester, locale: locale, width: width, textScale: 2);
      await _selectCriteria(tester, fixture.home, 'all');
      await _openFolderPicker(tester);
      await _search(tester, 'folder-picker', 'unmatched');
      expect(find.text(S.current.Folder_Search_Empty), findsOneWidget);
      expect(
          tester
              .widget<TextField>(_key('folder-picker-search'))
              .decoration!
              .labelText,
          S.current.Search_Folders);
      await _tap(tester, 'folder-picker-clear-search');
      await _tap(tester, 'home-manage-folders');
      await _search(tester, 'managed-folders', ' 工作💡 ');
      final row = _key('managed-folder-unicode');
      await tester.ensureVisible(row);
      expect(tester.getSize(row).height, greaterThanOrEqualTo(48));
      await _tap(tester, 'managed-folder-unicode');
      _expectCriteria(fixture.home, 'all', folderId: 'unicode');
      expect(fixture.notes.writes, 0);
      expect(fixture.folders.writes, 0);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
      'Chinese narrow 2x card move search keeps cancellation visible and read-only',
      (tester) async {
    final fixture = await open(tester,
        locale: const Locale('zh', 'HK'), width: 280, textScale: 2);
    await _selectCriteria(tester, fixture.home, 'all');
    await _openMoveSheet(tester, 'active-personal');
    await _search(tester, 'move-to-folder', ' 工作💡 ');
    expect(_key('move-to-folder-folder-unicode'), findsOneWidget);
    await _search(tester, 'move-to-folder', 'unmatched');
    expect(find.text(S.current.Folder_Search_Empty), findsOneWidget);
    await _tap(tester, 'move-to-folder-cancel');
    _expectCriteria(fixture.home, 'all', folderId: 'personal');
    expect(fixture.notes.writes, 0);
    expect(fixture.folders.writes, 0);
  });
}
