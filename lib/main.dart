import 'dart:convert';

import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:injectable/injectable.dart';
import 'package:localstorage/localstorage.dart';
import 'package:onlynote/common/constants.dart';
import 'package:onlynote/data/dto/note_dto.dart';
import 'package:onlynote/observer.dart';
import 'package:onlynote/presentation/screens/add_update_note/bloc/add_update_bloc.dart';
import 'package:onlynote/presentation/screens/home/bloc/home_bloc.dart';

import 'Tools/ads_manager.dart';
import 'Tools/app_layout_settings.dart';
import 'Tools/app_typography_settings.dart';
import 'Tools/image_storage.dart';
import 'Tools/in_app_reviewer_helper.dart';
import 'Tools/locator.dart';
import 'Tools/notification_service.dart';
import 'Tools/reminder_data.dart';
import 'di/di.dart';
import 'presentation/app.dart';
import 'presentation/screens/add_update_note/bloc/add_update_form/add_update_form_bloc.dart';
import 'presentation/screens/home/bloc/multiple_delete/multiple_delete_bloc.dart';
import 'presentation/screens/note_detail/bloc/action/note_action_bloc.dart';
import 'presentation/screens/note_detail/bloc/detail/note_detail_bloc.dart';

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  //* observe bloc logs
  Bloc.observer = MyBlocObserver();

  //* inject dependencies
  configureInjection(Environment.dev);

  //* hive local database setup
  await Hive.initFlutter();
  Hive.registerAdapter(NoteDtoAdapter());
  Hive.registerAdapter(TodoDtoAdapter());
  await Hive.openBox(databaseBox);

  //* Update statusbar theme
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  setupLocator();

  await AppTypographySettings.instance.load();
  await AppLayoutSettings.instance.load();
  await ImageStorage.init();

  Future.delayed(const Duration(seconds: 1), () {
    AppTrackingTransparency.requestTrackingAuthorization();
  });

  MobileAds.instance.initialize();

  AdsManager.debugPrintID();

  InAppReviewHelper.checkAndAskForReview();

  await NotificationService().init();

  await initLocalStorage();
  List items = [];
  final result = localStorage.getItem('reminders');
  if (result != null) {
    items = jsonDecode(result) as List;
  }

  ReminderData.shared.init(items);

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
