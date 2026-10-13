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
import 'package:onlynote/domain/model/note_card_style.dart';
import 'package:onlynote/domain/repository/folder_repository.dart';
import 'package:onlynote/domain/repository/note_repository.dart';
import 'package:onlynote/domain/usecase/usecase.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/routes/routes.dart';
import 'package:onlynote/presentation/screens/card_appearance/card_appearance_screen.dart';
import 'package:onlynote/presentation/screens/home/bloc/home_bloc.dart';
import 'package:onlynote/presentation/screens/home/bloc/multiple_delete/multiple_delete_bloc.dart';
import 'package:onlynote/presentation/screens/home/home_screen.dart';
import 'package:onlynote/presentation/screens/home/widgets/note_card.dart';
import 'package:onlynote/presentation/screens/home/widgets/note_reorder_card.dart';
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

void _expectMenuIcons(WidgetTester tester) {
  final items = tester
      .widgetList<PopupMenuItem<String>>(find.byType(PopupMenuItem<String>));
  expect(items, isNotEmpty);
  for (final item in items) {
    expect(
        find.descendant(of: find.byWidget(item), matching: find.byType(Icon)),
        findsOneWidget,
        reason: 'Home menu action ${item.value} should have a readable icon');
  }
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
      if (width < 240) expect(find.text(S.current.Settings), findsOneWidget);
      expect(find.byKey(const ValueKey('home-search-menu')), findsOneWidget);
      _expectMenuIcons(tester);
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
    _expectMenuIcons(tester);
    await _tap(tester, find.byKey(const ValueKey('home-search-menu')));
    expect(find.byType(TextField), findsOneWidget);
    expect(
        tester
            .widget<Badge>(find.byKey(const ValueKey('home-search-active-dot')))
            .isLabelVisible,
        isTrue);
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

    // Cancel search through the same menu after entering a query, while the
    // checklist filter continues to describe the desired library scope.
    await tester.enterText(find.byType(TextField), 'release');
    await tester.pumpAndSettle();
    expect(home.bloc.state.mapOrNull(loaded: (state) => state.searchQuery),
        'release');
    await _tap(tester, find.byKey(const ValueKey('home-more')));
    final searchAction = find.byKey(const ValueKey('home-search-menu'));
    expect(
        find.descendant(
            of: searchAction, matching: find.text(S.current.Cancel_Searching)),
        findsOneWidget);
    expect(
        find.descendant(
            of: searchAction, matching: find.text(S.current.Search_Notes)),
        findsNothing);
    expect(
        tester
            .widget<Badge>(find.byKey(const ValueKey('home-search-menu-dot')))
            .isLabelVisible,
        isTrue);
    _expectMenuIcons(tester);
    await _tap(tester, find.byKey(const ValueKey('home-search-menu')));
    expect(find.byType(TextField), findsNothing);
    expect(home.bloc.state.mapOrNull(loaded: (state) => state.searchQuery), '');
    expect(home.bloc.state.mapOrNull(loaded: (state) => state.filters),
        {NoteSearchFilter.checklists});
    expect(
        tester
            .widget<Badge>(find.byKey(const ValueKey('home-search-active-dot')))
            .isLabelVisible,
        isFalse);
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

  testWidgets(
      'Home Reorder menu drags persist through Done, filters and todo changes',
      (tester) async {
    final home = await _openHome(tester);
    final semantics = tester.ensureSemantics();
    Finder card(String id) => find.byWidgetPredicate(
        (widget) => widget is NoteCard && widget.note.id == id);
    Finder reorderCard(String id) => find.byWidgetPredicate(
        (widget) => widget is NoteReorderCard && widget.note.id == id);
    List<String?> visibleIds() => home.bloc.state.mapOrNull(
        loaded: (state) => state.notes.map((note) => note.id).toList())!;

    Future<void> openReorder() async {
      await tester.longPress(card('first'));
      await tester.pumpAndSettle();
      await _tap(tester, find.text(S.current.Reorder));
      // This package forwards its key to the underlying GridView too.
      expect(find.byKey(const ValueKey('home-reorder-grid')).first,
          findsOneWidget);
      expect(find.byKey(const ValueKey('home-reorder-instructions')),
          findsOneWidget);
      expect(find.text(S.current.Reorder_Hint), findsOneWidget);
      expect(find.byType(NoteCard), findsNothing);
      expect(tester.takeException(), isNull);
    }

    await openReorder();
    final first = tester.widget<NoteReorderCard>(reorderCard('first'));
    expect(first.onMoveEarlier, isNull);
    expect(first.onMoveLater, isNotNull);
    expect(
        tester
            .getSemantics(reorderCard('first'))
            .getSemanticsData()
            .customSemanticsActionIds,
        isNotEmpty);
    semantics.dispose();

    final from = tester.getCenter(reorderCard('first')) - const Offset(0, 20);
    final to = tester.getCenter(reorderCard('second')) - const Offset(0, 20);
    final gesture = await tester.startGesture(from);
    await tester.pump(const Duration(milliseconds: 600));
    await gesture.moveTo(to);
    await tester.pump(const Duration(milliseconds: 300));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(visibleIds(), ['second', 'first']);
    expect(home.notes.values['second']!.sortOrder,
        lessThan(home.notes.values['first']!.sortOrder!));
    await _tap(tester, find.text(S.current.Done));
    expect(find.byType(NoteReorderCard), findsNothing);
    expect(visibleIds(), ['second', 'first']);

    home.bloc
        .add(const HomeEvent.filtersChanged({NoteSearchFilter.checklists}));
    await tester.pumpAndSettle();
    expect(visibleIds(), ['first']);
    home.bloc.add(const HomeEvent.filtersChanged({}));
    await tester.pumpAndSettle();
    expect(visibleIds(), ['second', 'first']);
    await home.bloc.toggleTodo(noteId: 'first', todoId: 'first-task');
    await tester.pumpAndSettle();
    expect(visibleIds(), ['second', 'first']);
    await openReorder();
    expect(tester.widget<NoteReorderCard>(reorderCard('second')).onMoveEarlier,
        isNull);
    // The menu is also a tap and keyboard alternative to dragging.
    await _tap(tester, find.byKey(const ValueKey('reorder-move-first')));
    await _tap(tester, find.text(S.current.Reorder_Move_Earlier));
    expect(visibleIds(), ['first', 'second']);
    await _tap(tester, find.text(S.current.Done));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'Home dragging respects pinned groups and exposes accessible moves',
      (tester) async {
    final home = await _openHome(tester);
    home.notes.values['first'] =
        home.notes.values['first']!.copyWith(isPinned: true);
    home.notes.values['third'] =
        NoteDto.fromNote(Note(id: 'third', title: 'Third note', sortOrder: 3));
    home.bloc.add(const HomeEvent.getAllNotes());
    await tester.pumpAndSettle();
    await tester.longPress(find.byWidgetPredicate(
        (widget) => widget is NoteCard && widget.note.id == 'first'));
    await tester.pumpAndSettle();
    await _tap(tester, find.text(S.current.Reorder));
    expect(
        find.text(
            '${S.current.Reorder_Hint}\n${S.current.Reorder_Pinned_Hint}'),
        findsOneWidget);
    Finder reorderCard(String id) => find.byWidgetPredicate(
        (widget) => widget is NoteReorderCard && widget.note.id == id);
    final pinned = tester.widget<NoteReorderCard>(reorderCard('first'));
    expect(pinned.onMoveEarlier, isNull);
    expect(pinned.onMoveLater, isNull);
    final gesture = await tester.startGesture(
        tester.getCenter(reorderCard('third')) - const Offset(0, 20));
    await tester.pump(const Duration(milliseconds: 600));
    await gesture
        .moveTo(tester.getCenter(reorderCard('first')) - const Offset(0, 20));
    await tester.pump(const Duration(milliseconds: 300));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(
        home.bloc.state
            .mapOrNull(loaded: (state) => state.notes.map((note) => note.id)),
        ['first', 'third', 'second']);
    expect(home.notes.values['first']!.isPinned, isTrue);
    expect(tester.widget<NoteReorderCard>(reorderCard('third')).onMoveEarlier,
        isNull);
    await _tap(tester, find.text(S.current.Done));
    home.bloc.add(const HomeEvent.getAllNotes());
    await tester.pumpAndSettle();
    expect(
        home.bloc.state
            .mapOrNull(loaded: (state) => state.notes.map((note) => note.id)),
        ['first', 'third', 'second']);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'Home card style saves current content and supports mixed sizes, cancel and defaults',
      (tester) async {
    final home = await _openHome(tester);
    Finder card(String id) => find.byWidgetPredicate(
        (widget) => widget is NoteCard && widget.note.id == id);
    final firstState = tester.state<NoteCardState>(card('first'));
    final secondState = tester.state<NoteCardState>(card('second'));

    Future<void> openStyle() async {
      await tester.longPress(card('first'));
      await tester.pumpAndSettle();
      await _tap(tester, find.text(S.current.Card_Style));
      expect(find.byType(CardAppearanceScreen), findsOneWidget);
      expect(
          tester
              .widget<CardAppearanceScreen>(find.byType(CardAppearanceScreen))
              .note!
              .id,
          'first');
    }

    Finder cardSize(NoteCardSize size) =>
        find.byKey(ValueKey('card-style-card-${size.name}'));

    Future<void> chooseSize(NoteCardSize size) async {
      final section = find.byKey(const ValueKey('card-style-section-layout'));
      await tester.ensureVisible(section);
      await tester.pumpAndSettle();
      await _tap(tester, section.hitTestable());
      final target = cardSize(size);
      await tester.scrollUntilVisible(target, 150,
          scrollable: find.descendant(
              of: find.byKey(const ValueKey('card-style-controls')),
              matching: find.byType(Scrollable)));
      await _tap(tester, target);
    }

    await openStyle();
    await chooseSize(NoteCardSize.large);
    expect(
        tester
            .getSize(find.byKey(const ValueKey('card-style-preview-width')))
            .width,
        358);
    // Content may change while the appearance screen displays its snapshot.
    home.notes.values['first'] = NoteDto.fromNote(home.notes.values['first']!
        .toDomain()
        .copyWith(title: 'Updated project ideas', isPinned: true, todo: [
      Todo(id: 'first-task', title: 'Reviewed release', completed: true),
    ]));
    await _tap(tester, find.byKey(const ValueKey('card-style-save')));
    expect(find.byType(CardAppearanceScreen), findsNothing);
    final saved = home.notes.values['first']!.toDomain();
    expect(saved.cardStyle.cardSize, NoteCardSize.large);
    expect(saved.title, 'Updated project ideas');
    expect(saved.isPinned, isTrue);
    expect(saved.todo.single.title, 'Reviewed release');
    expect(saved.todo.single.completed, isTrue);
    expect(home.notes.values['second']!.toDomain().cardStyle.isDefault, isTrue);
    expect(tester.getSize(card('first')).width, 358);
    expect(tester.getSize(card('second')).width, 173);
    expect(tester.state<NoteCardState>(card('first')), same(firstState));
    expect(tester.state<NoteCardState>(card('second')), same(secondState));

    for (var cycle = 0; cycle < 3; cycle++) {
      home.bloc
          .add(const HomeEvent.filtersChanged({NoteSearchFilter.checklists}));
      await tester.pumpAndSettle();
      expect(card('second'), findsNothing);
      expect(tester.state<NoteCardState>(card('first')), same(firstState));
      home.bloc.add(const HomeEvent.filtersChanged({}));
      await tester.pumpAndSettle();
      expect(card('second'), findsOneWidget);
      expect(tester.getSize(card('first')).width, 358);
      expect(tester.getSize(card('second')).width, 173);
      expect(tester.state<NoteCardState>(card('first')), same(firstState));
      expect(tester.takeException(), isNull);
    }

    await openStyle();
    final reset = find.byKey(const ValueKey('card-style-reset'));
    await tester.scrollUntilVisible(reset, 250,
        scrollable: find.descendant(
            of: find.byKey(const ValueKey('card-style-controls')),
            matching: find.byType(Scrollable)));
    await _tap(tester, reset);
    await _tap(tester, find.byKey(const ValueKey('card-style-save')));
    expect(home.notes.values['first']!.toDomain().cardStyle.isDefault, isTrue);
    expect(tester.getSize(card('first')).width, 173);
    expect(tester.state<NoteCardState>(card('first')), same(firstState));

    await openStyle();
    await chooseSize(NoteCardSize.large);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text(S.current.Card_Style_Discard_Title), findsOneWidget);
    await _tap(tester, find.text(S.current.Card_Style_Discard));
    expect(find.byType(CardAppearanceScreen), findsNothing);
    expect(home.notes.values['first']!.toDomain().cardStyle.isDefault, isTrue);
    expect(tester.getSize(card('first')).width, 173);
    expect(tester.takeException(), isNull);
  });
}
