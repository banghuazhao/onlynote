// Run explicitly: flutter test test/presentation/store_screenshots_test.dart
// --dart-define=CAPTURE_STORE_SCREENSHOTS=true --concurrency=1
// Optional comma-separated STORE_DEVICES, STORE_LOCALES and STORE_SCREENS
// defines limit a review run without changing the complete capture sequence.
import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:onlynote/Tools/app_appearance_settings.dart';
import 'package:onlynote/Tools/app_card_style_settings.dart';
import 'package:onlynote/Tools/app_layout_settings.dart';
import 'package:onlynote/Tools/app_typography_settings.dart';
import 'package:onlynote/Tools/locator.dart';
import 'package:onlynote/Tools/reminder.dart';
import 'package:onlynote/Tools/reminder_data.dart';
import 'package:onlynote/Tools/widget_discovery_settings.dart';
import 'package:onlynote/common/constants.dart';
import 'package:onlynote/data/dto/folder_dto.dart';
import 'package:onlynote/data/dto/note_dto.dart';
import 'package:onlynote/di/di.dart';
import 'package:onlynote/domain/database/database.dart';
import 'package:onlynote/domain/model/folder.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/domain/repository/folder_repository.dart';
import 'package:onlynote/domain/repository/note_repository.dart';
import 'package:onlynote/domain/usecase/usecase.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/note_template_picker_sheet.dart';
import 'package:onlynote/presentation/routes/routes.dart';
import 'package:onlynote/presentation/screens/card_appearance/card_appearance_screen.dart';
import 'package:onlynote/presentation/screens/home/bloc/home_bloc.dart';
import 'package:onlynote/presentation/screens/home/bloc/multiple_delete/multiple_delete_bloc.dart';
import 'package:onlynote/presentation/screens/home/home_screen.dart';
import 'package:onlynote/presentation/screens/note_detail/bloc/detail/note_detail_bloc.dart';
import 'package:onlynote/presentation/screens/note_detail/note_detail_screen.dart';
import 'package:onlynote/presentation/screens/reminders/reminders_screen.dart';
import 'package:onlynote/presentation/theme/theme.dart';
import 'package:onlynote/services/custom_note_template_store.dart';
import 'package:onlynote/services/custom_template_images.dart';
import 'package:onlynote/services/note_position_store.dart';
import 'package:onlynote/services/purchase_service.dart';
import 'package:onlynote/services/reminder_agenda_controller.dart';
import 'package:onlynote/services/voice_memo_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
// Both packages are exposed by the plugins used by the actual app screens.
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
// ignore: depend_on_referenced_packages
import 'package:visibility_detector/visibility_detector.dart';

import '../support/premium_test_fakes.dart';
import '../support/store_screenshot_content.dart';

const _captureEnabled = bool.fromEnvironment('CAPTURE_STORE_SCREENSHOTS');
const _outputRoot = 'build/store_screenshots/2026-10-08';
const _captureKey = ValueKey('store-screenshot');

class _Device {
  const _Device(this.name, this.size, this.pixelRatio, {this.ios = false});
  final String name;
  final Size size;
  final double pixelRatio;
  final bool ios;
  bool get tablet => size.width >= 600;
}

const _devices = [
  _Device('iphone6_9', Size(440, 956), 3, ios: true),
  _Device('iphone6_3', Size(402, 874), 3, ios: true),
  _Device('ipad13', Size(1032, 1376), 2, ios: true),
  _Device('playphone', Size(360, 640), 3),
  _Device('play7inch', Size(600, 960), 2),
  _Device('play10inch', Size(800, 1280), 2),
];

bool _selected(String filter, String value) =>
    filter.isEmpty || filter.split(',').contains(value);

String _subtitle(StoreScreenshotContent content, StoreScreenshotScreen screen,
    {required bool ios}) {
  final caption = content.caption(screen, ios: ios);
  return caption.premiumQualifier == null
      ? caption.subtitle
      : '${caption.premiumQualifier} · ${caption.subtitle}';
}

// AppTheme retains text styles in component themes as well as textTheme.
// Supplying the bundled system font to both avoids the widget runner's Ahem
// fallback while retaining the actual screen's sizes, weights and colors.
ThemeData _captureTheme(_Device device) {
  final base = AppTheme.light;
  TextStyle? font(TextStyle? style) => style?.copyWith(
      fontFamily: 'Roboto', fontFamilyFallback: const ['DroidSansFallback']);
  ButtonStyle? button(ButtonStyle? style) => style?.copyWith(
      textStyle: WidgetStatePropertyAll(font(base.textTheme.labelLarge)));
  return base.copyWith(
    platform: device.ios ? TargetPlatform.iOS : TargetPlatform.android,
    textTheme: base.textTheme
        .apply(fontFamily: 'Roboto', fontFamilyFallback: ['DroidSansFallback']),
    primaryTextTheme: base.primaryTextTheme
        .apply(fontFamily: 'Roboto', fontFamilyFallback: ['DroidSansFallback']),
    appBarTheme: base.appBarTheme
        .copyWith(titleTextStyle: font(base.appBarTheme.titleTextStyle)),
    textButtonTheme:
        TextButtonThemeData(style: button(base.textButtonTheme.style)),
    filledButtonTheme:
        FilledButtonThemeData(style: button(base.filledButtonTheme.style)),
    outlinedButtonTheme:
        OutlinedButtonThemeData(style: button(base.outlinedButtonTheme.style)),
    elevatedButtonTheme:
        ElevatedButtonThemeData(style: button(base.elevatedButtonTheme.style)),
    listTileTheme: base.listTileTheme.copyWith(
        titleTextStyle: font(base.listTileTheme.titleTextStyle),
        subtitleTextStyle: font(base.listTileTheme.subtitleTextStyle)),
    chipTheme:
        base.chipTheme.copyWith(labelStyle: font(base.chipTheme.labelStyle)),
    dialogTheme: base.dialogTheme.copyWith(
        titleTextStyle: font(base.dialogTheme.titleTextStyle),
        contentTextStyle: font(base.dialogTheme.contentTextStyle)),
    snackBarTheme: base.snackBarTheme
        .copyWith(contentTextStyle: font(base.snackBarTheme.contentTextStyle)),
    floatingActionButtonTheme: base.floatingActionButtonTheme.copyWith(
        extendedTextStyle:
            font(base.floatingActionButtonTheme.extendedTextStyle)),
  );
}

final class _Preferences extends SharedPreferencesAsyncPlatform {
  final values = <String, String>{};
  @override
  Future<String?> getString(
          String key, SharedPreferencesOptions options) async =>
      values[key];
  @override
  Future<void> setString(
          String key, String value, SharedPreferencesOptions options) async =>
      values[key] = value;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Notes implements NoteRepository {
  _Notes(Iterable<Note> notes)
      : values = {for (final note in notes) note.id!: NoteDto.fromNote(note)};
  final Map<String, NoteDto> values;
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
    for (final id in ids) {
      values.remove(id);
    }
  }
}

class _Folders implements FolderRepository {
  _Folders(List<Folder> folders)
      : values = {
          for (final folder in folders) folder.id: FolderDto.fromDomain(folder)
        };
  final Map<String, FolderDto> values;
  @override
  List<FolderDto> getAllFolders() => values.values.toList();
  @override
  Future<void> addUpdateFolder(FolderDto folder) async =>
      values[folder.id!] = folder;
  @override
  Future<void> deleteFolder(String id) async => values.remove(id);
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
  Future<void> addUpdate<T>(String id, T item) => box.put(id, item);
  @override
  Future<void> delete(String id) => box.delete(id);
  @override
  Future<void> deleteAll(List<String> keys) => box.deleteAll(keys);
}

class _TemplateImages implements CustomTemplateImages {
  @override
  Future<List<String>> copyToNote(List<String> sources) async => sources;
  @override
  Future<List<String>> copyToTemplate(List<String> sources) async => sources;
  @override
  Future<void> deleteTemplates(List<String> paths) async {}
  @override
  Future<void> pruneTemplates(Set<String> keep) async {}
}

/// Routes still build the production widgets. Only storage and native services
/// are replaced; the navigation, cards, typography, sheets and controls are real.
class _CaptureRouter extends AppRouter {
  _CaptureRouter(
      {required this.screen,
      required this.content,
      required this.fixture,
      required this.templates,
      required this.agenda});
  final StoreScreenshotScreen screen;
  final StoreScreenshotContent content;
  final PremiumTestFixture fixture;
  final CustomNoteTemplateStore templates;
  final ReminderAgendaController agenda;
  final positions = NotePositionStore.memory();
  bool get hasHomeParent =>
      screen == StoreScreenshotScreen.cardStyle ||
      screen == StoreScreenshotScreen.reminderAgenda;

  Widget _screen() => switch (screen) {
        StoreScreenshotScreen.home ||
        StoreScreenshotScreen.foldersSearch ||
        StoreScreenshotScreen.starterTemplates =>
          const HomeScreen(),
        StoreScreenshotScreen.formattedNote => NoteDetailScreen(
            noteId: content.formattedNote().id!,
            positionStore: positions,
            templateStore: templates),
        StoreScreenshotScreen.checklist => NoteDetailScreen(
            noteId: content.checklistNote.id!,
            positionStore: positions,
            templateStore: templates),
        StoreScreenshotScreen.voiceMemo => NoteDetailScreen(
            noteId: content.voiceNote.id!,
            positionStore: positions,
            templateStore: templates),
        StoreScreenshotScreen.cardStyle => CardAppearanceScreen(
            note: content.styleNote,
            premiumAccess: fixture.access,
            onSaveAppearance: (_, __) async {}),
        StoreScreenshotScreen.reminderAgenda =>
          RemindersScreen(controller: agenda),
      };

  @override
  List<AutoRoute> get routes => [
        AutoRoute(
            initial: !hasHomeParent,
            page: PageInfo('StoreScreenshotRoute', builder: (_) => _screen())),
        AutoRoute(
            initial: hasHomeParent,
            page: PageInfo(HomeRoute.name, builder: (_) => const HomeScreen())),
        AutoRoute(
            page: PageInfo(NoteDetailRoute.name,
                builder: (data) => NoteDetailScreen(
                    noteId: data.argsAs<NoteDetailRouteArgs>().noteId,
                    positionStore: positions,
                    templateStore: templates))),
        AutoRoute(
            page: PageInfo(RemindersRoute.name,
                builder: (_) => RemindersScreen(controller: agenda))),
      ];
}

class _CaptureHost {
  _CaptureHost(this.home, this.selection, this.detail, this.router,
      this.fixture, this.templates, this.agenda);
  final HomeBloc home;
  final MultipleDeleteBloc selection;
  final NoteDetailBloc detail;
  final _CaptureRouter router;
  final PremiumTestFixture fixture;
  final CustomNoteTemplateStore templates;
  final ReminderAgendaController agenda;

  Future<void> dispose(WidgetTester tester) async {
    debugPrint('store dispose: unmount');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    // Stream controllers close in the real test zone. Creating their close
    // futures inside the widget fake zone can leave asyncExpand waiting forever.
    await tester.runAsync(() async {
      router.dispose();
      debugPrint('store dispose: blocs');
      await home.close();
      await selection.close();
      await detail.close();
      templates.dispose();
      agenda.dispose();
      debugPrint('store dispose: purchase fixture');
      await fixture.dispose();
      debugPrint('store dispose: scope');
      await getIt.popScope();
    });
  }
}

/// The title treatment is store artwork. Everything below it is a production
/// app screen, constrained to the remaining viewport without a device mockup.
class _StoreFrame extends StatelessWidget {
  const _StoreFrame(
      {required this.device,
      required this.heading,
      required this.subtitle,
      required this.child});
  final _Device device;
  final String heading;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final headerHeight = device.size.height * (device.tablet ? .08 : .14);
    final headerSize =
        device.tablet ? (device.size.width < 700 ? 28.0 : 34.0) : 22.0;
    // On the smallest Play canvas this keeps the actual app above 80% of the
    // image area, including its border and rounded corners.
    final inset = device.tablet ? 24.0 : 8.0;
    return ColoredBox(
      color: const Color(0xFFF4E9D6),
      child: Column(children: [
        SizedBox(
            height: headerHeight,
            child: Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: device.tablet ? 36 : 20, vertical: 4),
              child: LayoutBuilder(
                  builder: (context, constraints) => FittedBox(
                        fit: BoxFit.scaleDown,
                        child: SizedBox(
                            width: constraints.maxWidth,
                            child: Column(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(heading,
                                      maxLines: 2,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          fontFamily: 'Montserrat',
                                          fontFamilyFallback: const [
                                            'DroidSansFallback'
                                          ],
                                          fontSize: headerSize,
                                          height: 1.06,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFF302D27),
                                          decoration: TextDecoration.none)),
                                  const SizedBox(height: 5),
                                  Text(subtitle,
                                      maxLines: 2,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          fontFamily: 'Montserrat',
                                          fontFamilyFallback: const [
                                            'DroidSansFallback'
                                          ],
                                          fontSize: device.tablet
                                              ? (device.size.width < 700
                                                  ? 14
                                                  : 16)
                                              : 11.5,
                                          fontWeight: FontWeight.w400,
                                          height: 1.22,
                                          color: const Color(0xFF665D50),
                                          decoration: TextDecoration.none)),
                                ])),
                      )),
            )),
        Expanded(
            child: Padding(
          padding: EdgeInsets.fromLTRB(inset, 0, inset, inset),
          child: DecoratedBox(
            decoration: BoxDecoration(
                color: const Color(0xFFF9F2E5),
                borderRadius: BorderRadius.circular(device.tablet ? 18 : 12),
                border: Border.all(color: const Color(0xFFD6C7AF)),
                boxShadow: const [
                  BoxShadow(
                      color: Color(0x143E3020),
                      blurRadius: 16,
                      offset: Offset(0, 5))
                ]),
            child: ClipRRect(
                borderRadius: BorderRadius.circular(device.tablet ? 18 : 12),
                child: LayoutBuilder(
                    builder: (context, constraints) => MediaQuery(
                        data: MediaQuery.of(context).copyWith(
                            size: Size(
                                constraints.maxWidth, constraints.maxHeight),
                            padding: EdgeInsets.zero,
                            viewPadding: EdgeInsets.zero,
                            viewInsets: EdgeInsets.zero,
                            textScaler: TextScaler.noScaling,
                            disableAnimations: true),
                        child: child))),
          ),
        )),
      ]),
    );
  }
}

Future<_CaptureHost> _mount(WidgetTester tester, _Device device,
    StoreScreenshotContent content, StoreScreenshotScreen screen) async {
  final fixture = PremiumTestFixture(premium: true, supported: device.ios);
  await fixture.init();
  final notes = _Notes(content.notes());
  final folders = _Folders(content.folders);
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
      premiumAccess: fixture.access);
  final selection = MultipleDeleteBloc(DeleteMultipleNotesUsecase(notes));
  final detail =
      NoteDetailBloc(GetNoteUsecase(notes), UpdateNoteUsecase(notes));
  final templates = CustomNoteTemplateStore(
      images: _TemplateImages(),
      documentsPath: '/tmp/onlynote-store-media',
      premiumAccess: fixture.access);
  final agenda = ReminderAgendaController(
      readReminders: () => content.reminders,
      readNotes: () async => content.notes(),
      readNote: (id) async => notes.values[id]?.toDomain(),
      readPendingSnoozes: (_) async => {},
      now: () => content.nowDate,
      snoozeReminder: (_, __) async => true,
      rescheduleReminder: (_, __, ___) async => true);
  final router = _CaptureRouter(
      screen: screen,
      content: content,
      fixture: fixture,
      templates: templates,
      agenda: agenda);
  getIt.pushNewScope();
  getIt.registerSingleton<NoteRepository>(notes);
  getIt.registerSingleton<FolderRepository>(folders);
  getIt.registerSingleton<Database>(_Database(Hive.box(databaseBox)));
  getIt.registerSingleton<AppRouter>(router);
  // Library and reader reminder labels use the system clock for recurrence.
  // Their sample reminders are one-time dates so re-running this artwork does
  // not move a date. The agenda separately demonstrates repeats with its fixed
  // injected clock and the same sample note content.
  ReminderData.shared.reminders = [
    for (final reminder in content.reminders)
      // Reminders live in ReminderData rather than the Note model. The Android
      // appearance sample has no reminder so its whole card fits the preview.
      if (!(screen == StoreScreenshotScreen.cardStyle &&
          !device.ios &&
          reminder.noteId == content.styleNote.id))
        Reminder(
            reminderDate: reminder.reminderDate,
            reminderId: reminder.reminderId,
            noteId: reminder.noteId),
  ];
  final theme = _captureTheme(device);
  final host =
      _CaptureHost(home, selection, detail, router, fixture, templates, agenda);
  await tester.pumpWidget(MultiBlocProvider(
      providers: [
        BlocProvider.value(value: home),
        BlocProvider.value(value: selection),
        BlocProvider.value(value: detail),
      ],
      child: RepaintBoundary(
          key: _captureKey,
          child: MaterialApp.router(
            debugShowCheckedModeBanner: false,
            routerConfig: router.config(),
            theme: theme,
            locale: content.locale,
            // Resolve both script and region names to the app's Traditional
            // Chinese translation, zh_HK.
            localeResolutionCallback: (locale, _) =>
                locale?.scriptCode == 'Hant' || locale?.countryCode == 'HK'
                    ? const Locale('zh', 'HK')
                    : locale?.languageCode == 'zh'
                        ? const Locale('zh')
                        : const Locale('en'),
            supportedLocales: S.delegate.supportedLocales,
            localizationsDelegates: const [
              S.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate
            ],
            builder: (context, child) => _StoreFrame(
                device: device,
                heading: content.heading(screen, ios: device.ios),
                subtitle: _subtitle(content, screen, ios: device.ios),
                child: child!),
          ))));
  await tester.pumpAndSettle();
  if (router.hasHomeParent) {
    unawaited(router.push(const PageRouteInfo('StoreScreenshotRoute')));
    await tester.pumpAndSettle();
  }
  if (screen == StoreScreenshotScreen.cardStyle && !device.tablet) {
    // Show the actual controls after the same scroll a user makes. The color
    // remains visible in the pinned live preview above the font and size options.
    final textControls = find.byKey(const ValueKey('card-style-text'));
    await tester.scrollUntilVisible(textControls, 150,
        scrollable: find.descendant(
            of: find.byKey(const ValueKey('card-style-controls')),
            matching: find.byType(Scrollable)),
        maxScrolls: 8);
    await tester.ensureVisible(textControls);
    await tester.pumpAndSettle();
  }
  if (screen == StoreScreenshotScreen.starterTemplates) {
    final context = tester.element(find.byType(HomeScreen));
    unawaited(showNoteTemplatePickerSheet(context, store: templates));
    await tester.pumpAndSettle();
  }
  if (screen == StoreScreenshotScreen.foldersSearch) {
    home.add(HomeEvent.selectFolder(content.searchFolderId));
    await tester.pumpAndSettle();
    if (find.byTooltip(S.current.Search_Notes).evaluate().isNotEmpty) {
      await tester.tap(find.byTooltip(S.current.Search_Notes));
    } else {
      await tester.tap(find.byKey(const ValueKey('home-more')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('home-search-menu')));
    }
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, content.searchQuery);
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
  }
  return host;
}

Future<void> _capture(WidgetTester tester, _Device device,
    StoreScreenshotContent content, StoreScreenshotScreen screen) async {
  expect(Localizations.localeOf(tester.element(find.byType(Navigator).first)),
      content.locale,
      reason: 'The app interface must match the artwork language.');
  expect(tester.takeException(), isNull,
      reason: '${device.name}/${content.outputCode}/${screen.name}');
  final boundary =
      tester.renderObject<RenderRepaintBoundary>(find.byKey(_captureKey));
  final number = (screen.index + 1).toString().padLeft(2, '0');
  final path =
      '$_outputRoot/${device.name}/${content.outputCode}/$number-${screen.name}.png';
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: device.pixelRatio);
    try {
      expect(image.width, (device.size.width * device.pixelRatio).round());
      expect(image.height, (device.size.height * device.pixelRatio).round());
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      if (bytes == null) throw StateError('Could not encode $path');
      final output = File(path);
      await output.parent.create(recursive: true);
      await output.writeAsBytes(bytes.buffer.asUint8List());
    } finally {
      image.dispose();
    }
  });
}

Future<void> _loadFonts() async {
  for (final (family, paths) in [
    (
      'Montserrat',
      [
        'build/store_screenshots/fonts/Montserrat-Regular.ttf',
        'build/store_screenshots/fonts/Montserrat-Bold.ttf'
      ]
    ),
    (
      'Roboto',
      ['assets/fonts/Roboto-Regular.ttf', 'assets/fonts/Roboto-Bold.ttf']
    ),
    ('DroidSansFallback', ['assets/fonts/DroidSansFallback.ttf']),
  ]) {
    final loader = FontLoader(family);
    for (final path in paths) {
      loader.addFont(File(path).readAsBytes().then(ByteData.sublistView));
    }
    await loader.load();
  }
  await (FontLoader('MaterialIcons')
        ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
      .load();
}

void main() {
  if (!_captureEnabled) {
    test('store screenshots are opt-in', () {},
        skip: 'Set CAPTURE_STORE_SCREENSHOTS=true');
    return;
  }
  TestWidgetsFlutterBinding.ensureInitialized();
  final fonts = Map<String, GoogleFontBuilder>.of(kAppFontFamilies);
  final preferencesPlatform = SharedPreferencesAsyncPlatform.instance;
  final visibilityInterval =
      VisibilityDetectorController.instance.updateInterval;
  final previousReminders = List<Reminder>.of(ReminderData.shared.reminders);
  final previousDefaultPlatform = debugDefaultTargetPlatformOverride;
  final previousRuntimeFonts = GoogleFonts.config.allowRuntimeFetching;
  final previousPreferences = <String, Object>{
    'remove_ads_entitlement': PurchaseService.instance.isAdsRemoved,
    'widget_discovery_handled': WidgetDiscoverySettings.instance.handled,
    'app_font_family': AppTypographySettings.instance.fontFamily,
    'app_font_size': AppTypographySettings.instance.fontSize.name,
    'app_note_card_size': AppLayoutSettings.instance.cardSize.name,
    'app_theme_mode': AppAppearanceSettings.instance.themeMode.name,
    'app_plain_paper': AppAppearanceSettings.instance.plainPaper,
    'app_note_card_show_date': AppCardStyleSettings.instance.showDate,
    if (AppCardStyleSettings.instance.paperStyle != null)
      'app_note_card_paper_style':
          AppCardStyleSettings.instance.paperStyle!.name,
  };
  late Directory directory;
  late Box noteBox;
  late Box folderBox;
  late bool registeredLocalization;

  setUpAll(() async {
    // Construct the legacy Home entitlement singleton before simulating iOS.
    // The fixture services used for paid controls are injected separately.
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    final homePurchases = PurchaseService.instance;
    SharedPreferences.setMockInitialValues({
      'remove_ads_entitlement': true,
      'widget_discovery_handled': true,
      'app_font_family': 'Montserrat',
      'app_font_size': 'medium',
      'app_note_card_size': 'medium',
      'app_theme_mode': 'light',
    });
    SharedPreferencesAsyncPlatform.instance = _Preferences();
    await homePurchases.init();
    debugDefaultTargetPlatformOverride = previousDefaultPlatform;
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
    registeredLocalization = !locator.isRegistered<S>();
    if (registeredLocalization) locator.registerSingleton(S());
    await initializeDateFormatting();
    GoogleFonts.config.allowRuntimeFetching = false;
    await _loadFonts();
    for (final family in fonts.keys) {
      kAppFontFamilies[family] = (
              {textStyle, color, fontSize, fontWeight, fontStyle}) =>
          (textStyle ?? const TextStyle()).copyWith(
              fontFamily: family == 'Montserrat' ? 'Montserrat' : 'Roboto',
              fontFamilyFallback: const ['DroidSansFallback'],
              color: color,
              fontSize: fontSize,
              fontWeight: fontWeight,
              fontStyle: fontStyle);
    }
    await AppTypographySettings.instance.load();
    await AppLayoutSettings.instance.load();
    await AppAppearanceSettings.instance.load();
    await AppCardStyleSettings.instance.load();
    await WidgetDiscoverySettings.instance.load();
    directory =
        await Directory.systemTemp.createTemp('onlynote-store-screenshots-');
    Hive.init(directory.path);
    noteBox = await Hive.openBox(databaseBox);
    folderBox = await Hive.openBox(folderDatabaseBox);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            MethodChannelVoiceMemoPlatform.channel,
            (call) async => call.method == 'state'
                ? {'phase': 'idle', 'transcriptionSupported': true}
                : null);
  });

  tearDownAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(MethodChannelVoiceMemoPlatform.channel, null);
    VoiceMemoService.instance.state.value = const VoiceMemoState();
    ReminderData.shared.reminders = previousReminders;
    kAppFontFamilies.addAll(fonts);
    GoogleFonts.config.allowRuntimeFetching = previousRuntimeFonts;
    VisibilityDetectorController.instance.updateInterval = visibilityInterval;
    SharedPreferences.setMockInitialValues(previousPreferences);
    await AppTypographySettings.instance.load();
    await AppLayoutSettings.instance.load();
    await AppAppearanceSettings.instance.load();
    await AppCardStyleSettings.instance.load();
    await WidgetDiscoverySettings.instance.load();
    await PurchaseService.instance.init();
    SharedPreferencesAsyncPlatform.instance = preferencesPlatform;
    debugDefaultTargetPlatformOverride = previousDefaultPlatform;
    await noteBox.close();
    await folderBox.close();
    await directory.delete(recursive: true);
    if (registeredLocalization) await locator.unregister<S>();
  });

  for (final device in _devices) {
    if (!_selected(
        const String.fromEnvironment('STORE_DEVICES'), device.name)) {
      continue;
    }
    for (final language in StoreScreenshotLanguage.values) {
      if (!_selected(const String.fromEnvironment('STORE_LOCALES'),
          StoreScreenshotContent(language).outputCode)) {
        continue;
      }
      testWidgets(
          '${device.name} ${StoreScreenshotContent(language).outputCode} store screenshots',
          (tester) async {
        tester.view.physicalSize = device.size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        debugDefaultTargetPlatformOverride =
            device.ios ? TargetPlatform.iOS : TargetPlatform.android;
        final content = StoreScreenshotContent(language);
        try {
          for (final screen in StoreScreenshotScreen.values) {
            if (!_selected(
                const String.fromEnvironment('STORE_SCREENS'), screen.name)) {
              continue;
            }
            _CaptureHost? host;
            try {
              debugPrint(
                  'store mount: ${device.name}/${content.outputCode}/${screen.name}');
              host = await _mount(tester, device, content, screen);
              debugPrint('store mounted: ${screen.name}');
              await _capture(tester, device, content, screen);
              debugPrint('store captured: ${screen.name}');
            } finally {
              if (host != null) await host.dispose(tester);
              debugPrint('store disposed: ${screen.name}');
            }
          }
        } finally {
          debugDefaultTargetPlatformOverride = previousDefaultPlatform;
        }
      }, timeout: const Timeout(Duration(minutes: 8)));
    }
  }
}
