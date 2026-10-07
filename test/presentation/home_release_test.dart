import 'dart:io';

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
import 'package:onlynote/presentation/routes/routes.dart';
import 'package:onlynote/presentation/screens/home/bloc/home_bloc.dart';
import 'package:onlynote/presentation/screens/home/bloc/multiple_delete/multiple_delete_bloc.dart';
import 'package:onlynote/presentation/screens/home/home_screen.dart';
import 'package:onlynote/presentation/screens/home/widgets/note_card.dart';
import 'package:onlynote/presentation/theme/theme.dart';
import 'package:onlynote/services/note_search.dart';
import 'package:onlynote/services/purchase_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
// The preference plugin exposes its test platform in a separate package.
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
// FocusDetector uses this package internally; disable its timer in UI tests.
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
  bool failRead = false;
  int reads = 0;

  @override
  List<NoteDto> getAllNotes() {
    reads++;
    if (failRead) throw StateError('Storage temporarily unavailable');
    return values.values.toList();
  }

  @override
  Future<NoteDto> getNote(String id) async => values[id]!;
  @override
  Future<void> addUpdateNote(NoteDto note) async => values[note.id!] = note;
  @override
  Future<void> deleteNote(String id) async => values.remove(id);
  @override
  Future<void> deleteMultiNotes(List<String> ids) async {
    ids.forEach(values.remove);
  }
}

class _Folders implements FolderRepository {
  @override
  List<FolderDto> getAllFolders() => [FolderDto(id: 'work', name: 'Work')];
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

class _Router extends AppRouter {
  @override
  List<AutoRoute> get routes => [
        AutoRoute(
          initial: true,
          page: PageInfo(HomeRoute.name, builder: (_) => const HomeScreen()),
        ),
        AutoRoute(
          page: PageInfo(AddUpdateNoteRoute.name,
              builder: (_) => const Scaffold(body: Text('New note editor'))),
        ),
        AutoRoute(
          page: PageInfo(NoteDetailRoute.name,
              builder: (_) => const Scaffold(body: Text('Note reader'))),
        ),
      ];
}

class _Home {
  _Home(this.notes, this.bloc, this.selection, this.router);
  final _Notes notes;
  final HomeBloc bloc;
  final MultipleDeleteBloc selection;
  final _Router router;
}

Future<_Home> _openHome(WidgetTester tester,
    {double width = 390, bool failRead = false}) async {
  tester.view.physicalSize = Size(width, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final notes = _Notes()..failRead = failRead;
  for (final note in [
    Note(
        id: 'first',
        title: 'Project ideas',
        description: 'Draft the release plan.',
        sortOrder: 0,
        todo: [Todo(id: 'first-task', title: 'Review release')]),
    Note(id: 'second', title: 'Travel notes', sortOrder: 1),
    Note(
        id: 'trashed',
        title: 'Removed note',
        sortOrder: 2,
        deletedAt: DateTime(2026, 10, 1)),
  ]) {
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
  getIt.registerSingleton<AppRouter>(router);
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
      theme: AppTheme.light,
      supportedLocales: S.delegate.supportedLocales,
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: true),
        child: child!,
      ),
    ),
  ));
  await tester.pumpAndSettle();
  return _Home(notes, home, selection, router);
}

Future<void> _tap(WidgetTester tester, Finder target) async {
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}

Future<void> _openFolders(WidgetTester tester, double width) async {
  if (width < 280) {
    await _tap(tester, find.byKey(const ValueKey('home-more')));
    await _tap(tester, find.text(S.current.Folders));
  } else {
    await _tap(tester, find.text(S.current.All_Notes));
  }
}

Future<void> _dismissMenu(WidgetTester tester) async {
  await tester.tapAt(const Offset(5, 750));
  await tester.pumpAndSettle();
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
    directory = await Directory.systemTemp.createTemp('onlynote-home-release-');
    Hive.init(directory.path);
    noteBox = await Hive.openBox(databaseBox);
    folderBox = await Hive.openBox(folderDatabaseBox);
    SharedPreferences.setMockInitialValues({'remove_ads_entitlement': true});
    await PurchaseService.instance.init();
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

  for (final width in [180.0, 320.0]) {
    testWidgets('home actions and Trash selection remain usable at $width px',
        (tester) async {
      final home = await _openHome(tester, width: width);
      expect(find.byTooltip(S.current.Add_Note), findsOneWidget);
      await _tap(tester, find.byKey(const ValueKey('home-more')));
      expect(find.text(S.current.Search_Notes), findsOneWidget);
      expect(find.text(S.current.Templates), findsOneWidget);
      if (width < 280) expect(find.text(S.current.Folders), findsOneWidget);
      await _dismissMenu(tester);

      home.selection.add(const MultipleDeleteEvent.toggleSelect('first'));
      await tester.pumpAndSettle();
      await _tap(tester, find.byKey(const ValueKey('home-selection-more')));
      expect(find.text(S.current.Archive_Note), findsOneWidget);
      expect(find.text('${S.current.Delete} (1)'), findsOneWidget);
      await _dismissMenu(tester);
      await _tap(tester, find.byTooltip(S.current.Cancel));

      await _openFolders(tester, width);
      await _tap(tester, find.text(S.current.Trash));
      expect(home.bloc.state.mapOrNull(loaded: (state) => state.showTrash),
          isTrue);
      home.selection.add(const MultipleDeleteEvent.toggleSelect('trashed'));
      await tester.pumpAndSettle();
      await _tap(tester, find.byKey(const ValueKey('home-selection-more')));
      expect(find.text('${S.current.Delete_Forever} (1)'), findsOneWidget);
      expect(find.text(S.current.Restore), findsOneWidget);
      await _tap(tester, find.text(S.current.Restore));
      expect(home.notes.values['trashed']!.isDeleted, isFalse);
      expect(home.selection.state, const MultipleDeleteState.initial());
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('search and filter changes clear selections from hidden notes',
      (tester) async {
    final home = await _openHome(tester, width: 320);
    await _tap(tester, find.byKey(const ValueKey('home-more')));
    await _tap(tester, find.text(S.current.Search_Notes));
    home.selection.add(const MultipleDeleteEvent.toggleSelect('first'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Travel');
    await tester.pumpAndSettle();
    expect(home.selection.state, const MultipleDeleteState.initial());
    expect(
        home.bloc.state
            .mapOrNull(loaded: (state) => state.notes.map((n) => n.id)),
        ['second']);

    await tester.enterText(find.byType(TextField), '');
    await tester.pumpAndSettle();
    home.selection.add(const MultipleDeleteEvent.toggleSelect('second'));
    await tester.pumpAndSettle();
    final checklists =
        find.widgetWithText(FilterChip, S.current.Filter_Checklists);
    await _tap(tester, checklists);
    expect(home.selection.state, const MultipleDeleteState.initial());
    expect(home.bloc.state.mapOrNull(loaded: (state) => state.filters),
        {NoteSearchFilter.checklists});
    expect(
        home.bloc.state
            .mapOrNull(loaded: (state) => state.notes.map((n) => n.id)),
        ['first']);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Retry reloads the library after a temporary storage error',
      (tester) async {
    final home = await _openHome(tester, failRead: true);
    expect(find.byKey(const ValueKey('home-retry')), findsOneWidget);
    expect(find.byType(NoteCard), findsNothing);
    final failedReads = home.notes.reads;
    home.notes.failRead = false;
    await _tap(tester, find.byKey(const ValueKey('home-retry')));
    expect(home.notes.reads, greaterThan(failedReads));
    expect(find.byKey(const ValueKey('home-retry')), findsNothing);
    expect(find.text('Project ideas'), findsOneWidget);
    expect(find.text('Travel notes'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('library sorting keeps each card state attached to its note ID',
      (tester) async {
    final home = await _openHome(tester);
    final before = {
      for (final card in tester.widgetList<NoteCard>(find.byType(NoteCard)))
        card.note.id: tester.element(find.byWidget(card)),
    };
    expect(before.keys, containsAll(['first', 'second']));
    home.notes.values['second'] =
        home.notes.values['second']!.copyWith(isPinned: true);
    home.bloc.add(const HomeEvent.getAllNotes());
    await tester.pumpAndSettle();
    expect(home.bloc.state.mapOrNull(loaded: (state) => state.notes.first.id),
        'second');
    for (final card in tester.widgetList<NoteCard>(find.byType(NoteCard))) {
      expect(tester.element(find.byWidget(card)), same(before[card.note.id]));
    }
    expect(tester.takeException(), isNull);
  });
}
