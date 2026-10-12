import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:onlynote/Tools/app_typography_settings.dart';
import 'package:onlynote/Tools/locator.dart';
import 'package:onlynote/common/constants.dart';
import 'package:onlynote/data/dto/folder_dto.dart';
import 'package:onlynote/data/dto/note_dto.dart';
import 'package:onlynote/di/di.dart';
import 'package:onlynote/domain/database/database.dart';
import 'package:onlynote/domain/repository/folder_repository.dart';
import 'package:onlynote/domain/repository/note_repository.dart';
import 'package:onlynote/domain/usecase/usecase.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/folder_name_dialog.dart';
import 'package:onlynote/presentation/components/library_filters_sheet.dart';
import 'package:onlynote/presentation/routes/routes.dart';
import 'package:onlynote/presentation/screens/home/bloc/home_bloc.dart';
import 'package:onlynote/presentation/screens/home/bloc/multiple_delete/multiple_delete_bloc.dart';
import 'package:onlynote/presentation/screens/home/home_screen.dart';
import 'package:onlynote/presentation/theme/theme.dart';
import 'package:onlynote/services/purchase_service.dart';
import 'package:onlynote/services/saved_note_views.dart';
import 'package:shared_preferences/shared_preferences.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
// ignore: depend_on_referenced_packages
import 'package:visibility_detector/visibility_detector.dart';

final class _Preferences extends SharedPreferencesAsyncPlatform {
  final raw = jsonEncode({
    'version': 1,
    'views': [
      for (var i = 0; i < SavedNoteViewStore.maxViews; i++)
        SavedNoteView(id: 'view-$i', name: 'View $i').toJson(),
    ],
  });
  var writes = 0;

  @override
  Future<String?> getString(
          String key, SharedPreferencesOptions options) async =>
      key == SavedNoteViewStore.storageKey ? raw : null;

  @override
  Future<void> setString(
      String key, String value, SharedPreferencesOptions options) async {
    writes++;
    throw StateError('This navigation must not write preferences');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Notes implements NoteRepository {
  @override
  List<NoteDto> getAllNotes() => [];

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('Unexpected note operation: ${invocation.memberName}');
}

class _Folders implements FolderRepository {
  @override
  List<FolderDto> getAllFolders() => [];

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('Unexpected folder operation: ${invocation.memberName}');
}

class _Database implements Database {
  _Database(this.box);
  @override
  final Box box;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('Unexpected database operation');
}

class _Router extends RootStackRouter {
  @override
  List<AutoRoute> get routes => [
        AutoRoute(
            initial: true,
            page: PageInfo(HomeRoute.name, builder: (_) => const HomeScreen())),
      ];
}

void main() {
  final fonts = Map<String, GoogleFontBuilder>.of(kAppFontFamilies);
  final oldPreferences = SharedPreferencesAsyncPlatform.instance;
  final oldVisibility = VisibilityDetectorController.instance.updateInterval;
  final preferences = _Preferences();
  late Directory directory;
  late Box notesBox;
  late Box foldersBox;

  setUpAll(() async {
    if (!locator.isRegistered<S>()) locator.registerSingleton(S());
    SharedPreferencesAsyncPlatform.instance = preferences;
    await SavedNoteViewStore.instance.load();
    expect(
        SavedNoteViewStore.instance.views.length, SavedNoteViewStore.maxViews);
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
    directory =
        await Directory.systemTemp.createTemp('onlynote-view-capacity-');
    Hive.init(directory.path);
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

  tearDownAll(() async {
    kAppFontFamilies.addAll(fonts);
    SharedPreferencesAsyncPlatform.instance = oldPreferences;
    VisibilityDetectorController.instance.updateInterval = oldVisibility;
    await notesBox.close();
    await foldersBox.close();
    await directory.delete(recursive: true);
  });

  testWidgets('Home rejects a stale save-view result before requesting a name',
      (tester) async {
    final notes = _Notes();
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
    getIt.registerSingleton<Database>(_Database(notesBox));
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      router.dispose();
      await home.close();
      await selection.close();
      await getIt.popScope();
    });
    final originalViews = SavedNoteViewStore.instance.views;
    try {
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
              child: child!),
        ),
      ));
      await tester.pumpAndSettle();
      home.add(HomeEvent.savedViewsChanged(originalViews));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('home-library-filters')));
      final sheet = find.byType(LibraryFiltersSheet);
      for (var frame = 0; frame < 30 && sheet.evaluate().isEmpty; frame++) {
        // Alternate the real and fake microtask queues without awaiting the
        // shared store's cached tail from a different widget-test clock.
        await tester.runAsync(() => Future<void>.delayed(Duration.zero));
        await tester.pump(const Duration(milliseconds: 16));
      }
      expect(sheet, findsOneWidget);
      final save = find.byKey(const ValueKey('library-save-view'));
      expect(tester.widget<ListTile>(save).onTap, isNull);
      expect(tester.widget<LibraryFiltersSheet>(sheet).savedViews.length,
          SavedNoteViewStore.maxViews);

      // An older open panel could have returned this action just as another
      // operation filled the store. Home must check its current capacity.
      Navigator.of(tester.element(sheet))
          .pop(const CreateSavedNoteView({}, {}, NoteArchiveScope.active));
      await tester.pumpAndSettle();
      expect(find.byType(FolderNameDialog), findsNothing);
      expect(find.byType(SnackBar), findsOneWidget);
      expect(
          find.text(
              S.current.Saved_View_Limit_Reached(SavedNoteViewStore.maxViews)),
          findsOneWidget);
      expect(find.text(S.current.Saved_View_Failed), findsNothing);
      expect(SavedNoteViewStore.instance.views, originalViews);
      expect(preferences.writes, 0);
      expect(notesBox.values, isEmpty);
      expect(foldersBox.values, isEmpty);
      expect(tester.takeException(), isNull);
    } finally {
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });
}
