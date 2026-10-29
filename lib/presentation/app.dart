import 'package:onlynote/Tools/app_appearance_settings.dart';
import 'package:onlynote/Tools/app_card_style_settings.dart';
import 'dart:async';
import 'dart:ui' show AppExitResponse, AppExitType;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:onlynote/Tools/desktop_commands.dart';
import 'package:onlynote/Tools/app_shortcut_launch.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:onlynote/Tools/app_layout_settings.dart';
import 'package:onlynote/Tools/app_typography_settings.dart';
import 'package:onlynote/Tools/onboarding_settings.dart';
import 'package:onlynote/Tools/reminder_data.dart';
import 'package:onlynote/Tools/reminder_launch.dart';
import 'package:onlynote/Tools/widget_launch.dart';
import 'package:onlynote/Tools/widget_commands.dart';
import 'package:onlynote/Tools/shared_note_launch.dart';
import 'package:onlynote/di/di.dart';
import 'package:onlynote/domain/repository/note_repository.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/toast.dart'
    show showTransientSnackBar;
import 'package:onlynote/presentation/screens/home/bloc/home_bloc.dart';
import 'package:onlynote/services/photo_search_index.dart';
import 'package:onlynote/services/document_scan_capture.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:onlynote/presentation/screens/add_update_note/add_update_note_screen.dart';
import 'package:onlynote/presentation/screens/settings/settings_screen.dart';

import 'routes/routes.dart';
import 'theme/theme.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> with WidgetsBindingObserver {
  AppRouter get _router => getIt<AppRouter>();
  WidgetCommands? _widgetCommands;
  late final DocumentScanner _documentScanner;
  AppLifecycleListener? _exitListener;
  bool _openingDesktopNote = false;
  bool _openingDesktopSettings = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.macOS) {
      _exitListener = AppLifecycleListener(onExitRequested: _prepareToExit);
    }
    _widgetCommands = WidgetCommands.initializedInstance;
    _widgetCommands?.updates.addListener(_refreshLibrary);
    _documentScanner = DocumentScanner.instance;
    _documentScanner.addListener(_recoverDocumentScans);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!OnboardingSettings.instance.completed) {
        await _router.replaceAll([OnboardingRoute()]);
      }
      if (!mounted) return;
      AppShortcutLaunch.instance.attach(_router);
      AppShortcutLaunch.instance.init();
      SharedNoteLaunch.instance.attach(
        _router,
        onImported: _refreshLibrary,
        onFailure: () {
          final navigatorContext = _router.navigatorKey.currentContext;
          if (!mounted || navigatorContext == null) return;
          showTransientSnackBar(
            navigatorContext,
            SnackBar(content: Text(S.of(navigatorContext).Share_Import_Failed)),
          );
        },
      );
      unawaited(SharedNoteLaunch.instance.init());
      // Subscribed unconditionally, and only once the router is live: a widget
      // tap can arrive at any point in this process's life, and finishing
      // onboarding doesn't restart the process. Skipping it here would leave
      // taps dead for the whole first session. Taps that land *during*
      // onboarding are dropped inside the handler instead.
      WidgetLaunch.instance.init();
      ReminderLaunch.instance.attach(
        router: _router,
        notes: getIt<NoteRepository>(),
        reminders: () => ReminderData.shared.reminders,
      );
    });
  }

  void _refreshLibrary() {
    if (mounted) context.read<HomeBloc>().add(const HomeEvent.getAllNotes());
  }

  Future<AppExitResponse> _prepareToExit() async {
    final response = await DesktopCommands.instance.prepareToExit();
    if (response == AppExitResponse.cancel && mounted) {
      final navigatorContext = _router.navigatorKey.currentContext;
      if (navigatorContext != null && navigatorContext.mounted) {
        showTransientSnackBar(navigatorContext,
            SnackBar(content: Text(S.of(navigatorContext).Autosave_Failed)));
      }
    }
    return response;
  }

  void _quitDesktopApp() => unawaited(
      ServicesBinding.instance.exitApplication(AppExitType.cancelable));

  Future<void> _newDesktopNote() async {
    if (_openingDesktopNote || _router.hasPagelessTopRoute) return;
    if (DesktopCommands.instance.invoke(DesktopCommand.newNote)) return;
    _openingDesktopNote = true;
    try {
      final route = AddUpdateNoteRoute(start: NoteEditorStart.quickNote);
      if (!OnboardingSettings.instance.completed) {
        await OnboardingSettings.instance.complete();
        if (!mounted) return;
        await _router.replaceAll([const HomeRoute(), route]);
      } else {
        // Keep the editor underneath alive with its draft and undo history.
        if (await _prepareToExit() != AppExitResponse.exit || !mounted) return;
        unawaited(_router
            .push<void>(route)
            .then((_) => DesktopCommands.instance.refreshEditors()));
      }
    } finally {
      _openingDesktopNote = false;
    }
  }

  Future<void> _desktopSettings() async {
    if (_openingDesktopSettings || _router.hasPagelessTopRoute) return;
    if (DesktopCommands.instance.invoke(DesktopCommand.settings)) return;
    final navigator = _router.navigatorKey.currentState;
    if (navigator == null) return;
    _openingDesktopSettings = true;
    try {
      if (await _prepareToExit() != AppExitResponse.exit || !mounted) return;
      await navigator.push<void>(
          MaterialPageRoute(builder: (_) => const SettingsScreen()));
      await DesktopCommands.instance.refreshEditors();
    } finally {
      _openingDesktopSettings = false;
    }
  }

  void _recoverDocumentScans() {
    final capture = DocumentScanCapture.initializedInstance;
    if (!mounted || capture == null) return;
    unawaited(capture.recover().then((_) {
      _refreshLibrary();
    }).catchError((Object error) {
      debugPrint('Document scan recovery deferred: $error');
    }));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    PhotoSearchIndex.initializedInstance
        ?.setActive(state == AppLifecycleState.resumed);
    if (state == AppLifecycleState.resumed) {
      unawaited(_widgetCommands?.importPending());
      _recoverDocumentScans();
    }
  }

  @override
  void dispose() {
    _exitListener?.dispose();
    WidgetsBinding.instance.removeObserver(this);
    _widgetCommands?.updates.removeListener(_refreshLibrary);
    _documentScanner.removeListener(_recoverDocumentScans);
    SharedNoteLaunch.instance.detach();
    AppShortcutLaunch.instance.detach();
    ReminderLaunch.instance.detach();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Rebuilds the whole app when the font/layout preferences change, so
    // AppTypography's getters and the home grid's column count are
    // re-evaluated everywhere they're used.
    return ListenableBuilder(
      listenable: Listenable.merge([
        AppTypographySettings.instance,
        AppLayoutSettings.instance,
        AppAppearanceSettings.instance,
        AppCardStyleSettings.instance,
      ]),
      builder: (context, _) => _buildMaterialApp(),
    );
  }

  Widget _buildMaterialApp() {
    return MaterialApp.router(
      title: "Onlynote",
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      // 讲en设置为第一项,没有适配语言时,英语为首选项
      supportedLocales: S.delegate.supportedLocales,
      // 插件目前不完善手动处理简繁体
      localeResolutionCallback: (locale, supportLocales) {
        // 中文 简繁体处理
        if (locale?.languageCode == 'zh') {
          if (locale?.scriptCode == 'Hant') {
            return const Locale('zh', 'HK'); //繁体
          } else {
            return const Locale('zh', ''); //简体
          }
        }
        return const Locale('en', '');
      },
      routeInformationParser: _router.defaultRouteParser(),
      routerDelegate: _router.delegate(),
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: AppAppearanceSettings.instance.themeMode,
      builder: (context, child) => DesktopAppMenu(
        onNewNote: () => unawaited(_newDesktopNote()),
        onSettings: () => unawaited(_desktopSettings()),
        onQuit: _quitDesktopApp,
        child: child ?? const SizedBox.shrink(),
      ),
    );
  }
}
