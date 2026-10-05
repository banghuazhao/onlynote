import 'package:onlynote/Tools/app_appearance_settings.dart';
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:injectable/injectable.dart';
import 'package:localstorage/localstorage.dart';
import 'package:onlynote/common/constants.dart';
import 'package:onlynote/data/dto/folder_dto.dart';
import 'package:onlynote/data/dto/note_dto.dart';
import 'package:onlynote/domain/repository/note_repository.dart';
import 'package:onlynote/observer.dart';
import 'package:onlynote/presentation/screens/add_update_note/bloc/add_update_bloc.dart';
import 'package:onlynote/presentation/screens/home/bloc/home_bloc.dart';

import 'Tools/ads_manager.dart';
import 'Tools/app_layout_settings.dart';
import 'Tools/app_typography_settings.dart';
import 'Tools/consent_gate.dart';
import 'Tools/image_storage.dart';
import 'Tools/in_app_reviewer_helper.dart';
import 'Tools/locator.dart';
import 'Tools/note_cleanup.dart';
import 'Tools/notification_service.dart';
import 'Tools/onboarding_settings.dart';
import 'Tools/reminder_data.dart';
import 'Tools/widget_sync.dart';
import 'di/di.dart';
import 'presentation/app.dart';
import 'presentation/screens/add_update_note/bloc/add_update_form/add_update_form_bloc.dart';
import 'presentation/screens/home/bloc/multiple_delete/multiple_delete_bloc.dart';
import 'presentation/screens/note_detail/bloc/action/note_action_bloc.dart';
import 'presentation/screens/note_detail/bloc/detail/note_detail_bloc.dart';
import 'services/purchase_service.dart';
import 'services/note_autosave.dart';
import 'services/custom_note_template_store.dart';
import 'services/backup/backup_service.dart';
import 'package:path_provider/path_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  //* observe bloc logs
  Bloc.observer = MyBlocObserver();

  //* inject dependencies
  configureInjection(Environment.dev);

  //* hive local database setup
  await Hive.initFlutter();
  Hive.registerAdapter(NoteDtoAdapter());
  Hive.registerAdapter(TodoDtoAdapter());
  Hive.registerAdapter(FolderDtoAdapter());
  await Hive.openBox(databaseBox);
  await Hive.openBox(folderDatabaseBox);
  await Hive.openBox(draftDatabaseBox);
  await Hive.openBox(backupRecoveryBox);

  //* Update statusbar theme
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
    ),
  );

  setupLocator();

  await AppTypographySettings.instance.load();
  await AppLayoutSettings.instance.load();
  await AppAppearanceSettings.instance.load();
  await OnboardingSettings.instance.load();
  await ImageStorage.init();
  await WidgetSync.instance.init();

  await PurchaseService.instance.init();

  if (PurchaseService.instance.shouldShowAds) {
    // Not awaited: the gate shows a consent form, so awaiting it here would
    // hold back the first frame. Ad code waits on ConsentGate.isResolved
    // instead, which is what actually has to happen before a request goes out.
    unawaited(ConsentGate.instance.resolve());
    AdsManager.debugPrintID();
  }

  // Track use without interrupting launch; completed actions decide when to
  // consider a review request.
  unawaited(InAppReviewHelper.instance.recordAppOpen());

  final notifications = NotificationService();
  await notifications.init();

  await initLocalStorage();
  List items = [];
  final result = localStorage.getItem('reminders');
  if (result != null) {
    items = jsonDecode(result) as List;
  }

  ReminderData.shared.init(items);
  await BackupService(
    notes: Hive.box(databaseBox),
    folders: Hive.box(folderDatabaseBox),
    journal: Hive.box(backupRecoveryBox),
    documents: await getApplicationDocumentsDirectory(),
    readReminders: () => ReminderData.shared.reminders,
    writeReminders: ReminderData.shared.replaceAll,
    templateStore: CustomNoteTemplateStore.instance,
  ).recoverInterruptedRestore();
  await HiveNoteAutosaveStore(
          getIt<NoteRepository>(), Hive.box(draftDatabaseBox))
      .recover();
  // Finish recovery before pruning; pending drafts may own photos too.
  await NoteCleanup.pruneOrphanImages(getIt<NoteRepository>());

  // Native upgrades run after recovery and do not delay the first frame.
  WidgetsBinding.instance.addPostFrameCallback((_) {
    unawaited(notifications.upgradePendingReminders(
        ReminderData.shared.reminders, getIt<NoteRepository>()));
  });

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider<HomeBloc>(
          create: (_) => getIt<HomeBloc>()..add(const HomeEvent.getAllNotes()),
        ),
        BlocProvider<AddUpdateFormBloc>(
          create: (_) => getIt<AddUpdateFormBloc>(),
        ),
        BlocProvider<AddUpdateBloc>(
          create: (_) => getIt<AddUpdateBloc>(),
        ),
        BlocProvider<NoteActionBloc>(
          create: (_) => getIt<NoteActionBloc>(),
        ),
        BlocProvider<NoteDetailBloc>(
          create: (_) => getIt<NoteDetailBloc>(),
        ),
        BlocProvider<MultipleDeleteBloc>(
          create: (_) => getIt<MultipleDeleteBloc>(),
        ),
      ],
      child: const App(),
    ),
  );
}
