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
import 'package:onlynote/presentation/components/note_template_picker_sheet.dart';
import 'package:onlynote/presentation/routes/routes.dart';
import 'package:onlynote/presentation/screens/add_update_note/add_update_note_screen.dart';
import 'package:onlynote/presentation/screens/add_update_note/bloc/add_update_bloc.dart';
import 'package:onlynote/presentation/screens/home/bloc/home_bloc.dart';
import 'package:onlynote/presentation/screens/home/bloc/multiple_delete/multiple_delete_bloc.dart';
import 'package:onlynote/presentation/screens/home/home_screen.dart';
import 'package:onlynote/presentation/theme/theme.dart';
import 'package:onlynote/services/custom_note_template_store.dart';
import 'package:onlynote/services/note_autosave.dart';
import 'package:onlynote/services/note_templates.dart';
import 'package:onlynote/services/purchase_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
// The preferences plugin exposes its test platform in a separate package.
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
// FocusDetector uses this package internally; prevent deferred test callbacks.
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

  @override
  List<NoteDto> getAllNotes() => values.values.toList();
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
  List<FolderDto> getAllFolders() => [];
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

class _AutosaveStore implements NoteAutosaveStore {
  _AutosaveStore(this.notes, {required this.onSaved});
  final _Notes notes;
  final VoidCallback onSaved;
  final drafts = <String, Note>{};
  final saved = <String, Note>{};

  @override
  Future<void> writeDraft(Note note) async => drafts[note.id!] = note;
  @override
  Future<void> removeDraft(String id) async => drafts.remove(id);
  @override
  Future<void> saveNote(Note note) async {
    saved[note.id!] = note;
    await notes.addUpdateNote(NoteDto.fromNote(note));
    // Mirror the library refresh emitted by production Hive writes.
    onSaved();
  }
}

class _Router extends AppRouter {
  _Router(this.store);
  final _AutosaveStore store;

  // Keep the production Home page and adaptive routing. Only storage is
  // replaced so disk latency cannot decide when the editor's pop finishes.
  @override
  List<AutoRoute> get routes => [
        AutoRoute(initial: true, page: HomeRoute.page),
        AutoRoute(
          path: '/add-update-note',
          page: PageInfo(AddUpdateNoteRoute.name, builder: (data) {
            final args = data.argsAs<AddUpdateNoteRouteArgs>();
            return AddUpdateNoteScreen(
              note: args.note,
              folderId: args.folderId,
              template: args.template,
              customTemplateNote: args.customTemplateNote,
              autosaveStore: store,
            );
          }),
        ),
      ];
}

Future<(_Router, _AutosaveStore, Future<void> Function())> _openHome(
    WidgetTester tester, TargetPlatform platform, double width) async {
  if (tester.binding is AutomatedTestWidgetsFlutterBinding) {
    tester.view.physicalSize = Size(width, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  final notes = _Notes();
  for (var index = 0; index < 48; index++) {
    final note = Note(
      id: 'existing-$index',
      title: index.isEven
          ? 'Existing note $index'
          : 'Existing note $index with a longer title that wraps across lines',
      description: index % 3 == 0
          ? ''
          : List.generate(
                  index % 7 + 1,
                  (line) =>
                      'Line $line of a varied height library note $index.')
              .join('\n'),
      todo: [
        for (var item = 0; item < index % 5; item++)
          Todo(
            id: 'existing-$index-task-$item',
            title: item.isEven
                ? 'Task $item'
                : 'A longer task $item that also wraps across multiple lines',
            completed: item == 0,
          ),
      ],
      tags: index % 3 == 0 ? ['Work', 'Ideas'] : [],
      dateTime: DateTime(2026, 10, index % 20 + 1),
      sortOrder: index,
    );
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
  final editor = AddUpdateBloc(AddNoteUsecase(notes), UpdateNoteUsecase(notes));
  final store = _AutosaveStore(notes,
      onSaved: () => home.add(const HomeEvent.getAllNotes()));
  final router = _Router(store);
  getIt.pushNewScope();
  getIt.registerSingleton<NoteRepository>(notes);
  getIt.registerSingleton<Database>(_Database(Hive.box(databaseBox)));
  getIt.registerSingleton<AppRouter>(router);
  var closed = false;
  Future<void> close() async {
    if (closed) return;
    closed = true;
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    router.dispose();
    await home.close();
    await selection.close();
    await editor.close();
    await getIt.popScope();
  }

  addTearDown(close);
  await tester.pumpWidget(MultiBlocProvider(
    providers: [
      BlocProvider.value(value: home),
      BlocProvider.value(value: selection),
      BlocProvider.value(value: editor),
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
    ),
  ));
  await tester.pumpAndSettle();
  return (router, store, close);
}

Future<void> _openTemplates(WidgetTester tester, double width) async {
  if (width < 360) {
    await tester.tap(find.byKey(const ValueKey('home-more')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(S.current.Templates));
  } else {
    await tester.tap(find.byTooltip(S.current.Templates));
  }
  await tester.pump();
  // The singleton's serialized queue originated outside the widget test's
  // fake clock. Drain the picker's queued read on the real async event loop.
  await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  await tester.pumpAndSettle();
  expect(find.byType(NoteTemplatePickerSheet), findsOneWidget);
}

void main() {
  final fonts = Map<String, GoogleFontBuilder>.of(kAppFontFamilies);
  final preferencesPlatform = SharedPreferencesAsyncPlatform.instance;
  final visibilityInterval =
      VisibilityDetectorController.instance.updateInterval;
  late Directory directory;
  late Box noteBox;
  late Box folderBox;

  setUpAll(() async {
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
    await initializeDateFormatting();
    if (!locator.isRegistered<S>()) locator.registerSingleton(S());
    SharedPreferencesAsyncPlatform.instance = _PreferencesPlatform();
    directory =
        await Directory.systemTemp.createTemp('onlynote-template-navigation-');
    Hive.init(directory.path);
    noteBox = await Hive.openBox(databaseBox);
    folderBox = await Hive.openBox(folderDatabaseBox);
    SharedPreferences.setMockInitialValues({'remove_ads_entitlement': true});
    final platform = debugDefaultTargetPlatformOverride;
    try {
      // This fixture starts with ads removed and does not exercise StoreKit.
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
      'scrolled iOS Home returns from edited templates with the keyboard',
      (tester) async {
    // Home opens the shared device store. Complete its one-time housekeeping
    // outside the fake clock before exercising the animated picker routes.
    await tester.runAsync(() => CustomNoteTemplateStore.instance.load());
    final automated = tester.binding is AutomatedTestWidgetsFlutterBinding;
    final width = automated
        ? 390.0
        : tester.view.physicalSize.width / tester.view.devicePixelRatio;
    if (automated) addTearDown(tester.view.resetViewInsets);
    final (router, store, _) =
        await _openHome(tester, TargetPlatform.iOS, width);
    for (var visit = 0; visit < NoteTemplate.values.length; visit++) {
      final template = NoteTemplate.values[visit];
      final grid = Scrollable.of(tester.element(find.byType(SliverMasonryGrid)))
          .position;
      expect(grid.maxScrollExtent, greaterThan(1000));
      grid.jumpTo(grid.maxScrollExtent * .55);
      await tester.pumpAndSettle();
      expect(grid.pixels, greaterThan(0));

      await _openTemplates(tester, width);
      final choice = find.byKey(ValueKey('template-${template.name}'));
      await tester.ensureVisible(choice);
      await tester.pumpAndSettle();
      await tester.tap(choice);
      await tester.pumpAndSettle();
      expect(find.byType(AddUpdateNoteScreen), findsOneWidget);
      expect(find.byType(NoteTemplatePickerSheet), findsNothing);
      expect(router.hasPagelessTopRoute, isFalse);
      final content = template.content(S.current);
      expect(find.text(content.title), findsOneWidget);

      final firstTodo = find.byWidgetPredicate((widget) =>
          widget is TextField &&
          widget.key is ValueKey<String> &&
          (widget.key! as ValueKey<String>).value.startsWith('todo-field-'));
      final todo = firstTodo.first;
      final todoKey = tester.widget<TextField>(todo).key! as ValueKey<String>;
      final todoId = todoKey.value.substring('todo-field-'.length);
      final completed = find.byKey(ValueKey('todo-check-$todoId'));
      await tester.ensureVisible(completed);
      await tester.pumpAndSettle();
      await tester.tap(completed);
      await tester.pumpAndSettle();
      await tester.ensureVisible(todo);
      await tester.pumpAndSettle();
      await tester.tap(todo);
      await tester.enterText(todo, '${content.items.first} edited $visit');
      await tester.pump();

      final body = find.byWidgetPredicate(
          (widget) => widget is TextField && widget.maxLines == 100);
      await tester.ensureVisible(body);
      await tester.pumpAndSettle();
      await tester.tap(body);
      final bodyText = '${content.body}\nKeyboard edits for ${template.name}.\n'
          'This new paragraph changes the library card height.';
      await tester.enterText(body, bodyText);
      if (template == NoteTemplate.shopping ||
          template == NoteTemplate.packing) {
        // Exercise checklist focus as well as the body's keyboard toolbar.
        // The checklist has a nested scrollable, so ensureVisible can position
        // this field behind the app bar on the native test surface.
        tester.widget<TextField>(todo).focusNode!.requestFocus();
      }
      if (automated) {
        tester.view.viewInsets = const FakeViewPadding(bottom: 280);
      }
      await tester.pumpAndSettle();
      expect(FocusManager.instance.primaryFocus?.hasFocus, isTrue);
      expect(
          tester
              .widget<TextField>(template == NoteTemplate.shopping ||
                      template == NoteTemplate.packing
                  ? todo
                  : body)
              .focusNode!
              .hasFocus,
          isTrue);
      if (automated) expect(tester.testTextInput.isVisible, isTrue);

      if (visit.isEven) {
        await tester.tap(find.byTooltip(S.current.Done));
      } else {
        await tester.binding.handlePopRoute();
      }
      await tester.pump();
      if (automated) {
        // Model the keyboard resizing both the outgoing editor and the
        // retained masonry viewport during the native back transition.
        for (final inset in [210.0, 110.0, 0.0]) {
          tester.view.viewInsets = FakeViewPadding(bottom: inset);
          await tester.pump(const Duration(milliseconds: 45));
        }
      }
      await tester.pumpAndSettle();
      expect(router.stackData.map((route) => route.name), [HomeRoute.name]);
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byType(AddUpdateNoteScreen), findsNothing);
      expect(store.saved, hasLength(visit + 1));
      final saved = store.saved.values.last;
      expect(saved.todo.first.title, '${content.items.first} edited $visit');
      expect(saved.todo.first.completed, isTrue);
      expect(saved.description, bodyText);
      expect(store.drafts, isEmpty);
      expect(tester.takeException(), isNull);
    }

    // Cancelling a later picker must leave Home active, without creating an
    // editor or retaining a pageless route for the next visit.
    await _openTemplates(tester, width);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(NoteTemplatePickerSheet), findsNothing);
    expect(router.stackData.map((route) => route.name), [HomeRoute.name]);
    expect(router.hasPagelessTopRoute, isFalse);
    expect(store.saved, hasLength(NoteTemplate.values.length));
    expect(tester.takeException(), isNull);
  }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));
}
