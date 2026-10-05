import 'dart:async';
import 'dart:io';
import 'dart:ui' show DartPluginRegistrant;

import 'package:app_settings/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:onlynote/Tools/reminder.dart';
import 'package:onlynote/Tools/reminder_notification_payload.dart';
import 'package:onlynote/services/reminder_snooze.dart';
import 'package:onlynote/domain/repository/note_repository.dart';
import 'package:onlynote/Tools/reminder_launch.dart';
import 'package:onlynote/Tools/notification_timezone.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:timezone/timezone.dart' as tz;

@pragma('vm:entry-point')
void reminderNotificationActionBackground(NotificationResponse response) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  try {
    await NotificationService().handleSnoozeResponse(response);
  } catch (error) {
    debugPrint('Could not snooze reminder: $error');
  }
}

class NotificationService {
  NotificationService({ReminderSnoozeRegistry? snoozeRegistry})
      : snoozeRegistry = snoozeRegistry ?? ReminderSnoozeRegistry();

  final ReminderSnoozeRegistry snoozeRegistry;
  static const _category = 'onlynote_reminder_actions';
  static Future<void> _scheduleQueue = Future.value();
  static Future<void> _actionQueue = Future.value();

  static Future<T> _serialize<T>(Future<T> Function() operation) {
    final result = _scheduleQueue.then((_) => operation());
    _scheduleQueue =
        result.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return result;
  }

  Future<S> _actionLabels() async {
    final locale = WidgetsBinding.instance.platformDispatcher.locale;
    final traditional = locale.scriptCode == 'Hant' ||
        locale.countryCode == 'TW' ||
        locale.countryCode == 'HK';
    return S.load(locale.languageCode == 'zh'
        ? (traditional ? const Locale('zh', 'HK') : const Locale('zh'))
        : const Locale('en'));
  }

  Future<bool> handleSnoozeResponse(NotificationResponse response) {
    final result = _actionQueue.then((_) => ReminderSnooze(
          registry: snoozeRegistry,
          schedule: (payload, due) => _scheduleNative(
              id: payload.snoozeId,
              title: payload.title,
              body: payload.body,
              time: due,
              payload: payload.encode(),
              repeat: ReminderRepeat.none),
          cancel: (id) => flutterLocalNotificationsPlugin.cancel(id: id),
        ).handleResponse(response));
    _actionQueue =
        result.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return result;
  }

  //instance of FlutterLocalNotificationsPlugin
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    //Initialization Settings for Android
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final labels = await _actionLabels();
    final initializationSettingsIOS = DarwinInitializationSettings(
      requestSoundPermission: false,
      requestBadgePermission: false,
      requestAlertPermission: false,
      notificationCategories: [
        DarwinNotificationCategory(_category, actions: [
          DarwinNotificationAction.plain(
              ReminderSnooze.tenMinutes, labels.Reminder_Snooze_10_Minutes),
          DarwinNotificationAction.plain(
              ReminderSnooze.oneHour, labels.Reminder_Snooze_1_Hour),
        ])
      ],
    );

    //Initializing settings for both platforms (Android & iOS)
    final InitializationSettings initializationSettings =
        InitializationSettings(
            android: initializationSettingsAndroid,
            iOS: initializationSettingsIOS);

    try {
      await NotificationTimezone.initialize();
    } catch (error) {
      // A timezone lookup failure must not stop note access at startup.
      // Scheduling retries the lookup and reports failure to the caller.
      debugPrint('Could not load notification timezone: $error');
    }

    await flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: onDidReceiveNotificationResponse,
      onDidReceiveBackgroundNotificationResponse:
          reminderNotificationActionBackground,
    );

    // The response callback handles an already running app. A tap that starts
    // a terminated process is supplied separately, before the router exists.
    final launch =
        await flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails();
    if (launch?.didNotificationLaunchApp == true &&
        launch?.notificationResponse != null) {
      onDidReceiveNotificationResponse(launch!.notificationResponse!);
    }
  }

  void onDidReceiveNotificationResponse(NotificationResponse response) {
    if (ReminderSnooze.isSnoozeAction(response.actionId)) {
      unawaited(handleSnoozeResponse(response).catchError((Object error) {
        debugPrint('Could not snooze reminder: $error');
        return false;
      }));
    } else {
      ReminderLaunch.instance.handleNotificationResponse(response);
    }
  }

  Future<bool?>? requestIOSPermissions() {
    return flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
  }

  // Android 13+ (API 33) requires this runtime permission before any
  // notification can be shown; older Android versions grant it implicitly.
  Future<bool?>? requestAndroidPermissions() {
    return flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  Future<bool?> _requestPlatformPermissions() {
    if (Platform.isIOS) {
      return requestIOSPermissions() ?? Future.value(true);
    }
    return requestAndroidPermissions() ?? Future.value(true);
  }

  Future<void> showNotifications({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails('your channel id', 'your channel name',
            channelDescription: 'your channel description',
            importance: Importance.max,
            priority: Priority.high,
            ticker: 'ticker');
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: platformChannelSpecifics,
      payload: payload,
    );
  }

  Future<void> askForPermissionAndSchedule(
      BuildContext context, Note note, Reminder reminder) async {
    final result = await _requestPlatformPermissions();

    debugPrint("Notification permission result: $result");
    if (!context.mounted) return;

    if (result != null) {
      if (result == false) {
        openNotificationSettingDialog(context);
      }
    } else {
      openNotificationSettingDialog(context);
    }

    scheduleNotification(context, note, reminder);

    final pendingNotificationRequests =
        await flutterLocalNotificationsPlugin.pendingNotificationRequests();

    debugPrint(
        "pendingNotificationRequests count: ${pendingNotificationRequests.length}");
    for (PendingNotificationRequest request in pendingNotificationRequests) {
      debugPrint("${request.id}: ${request.title}");
    }
  }

  Future<void> clearAll() => _serialize(() async {
        // Invalidate before canceling: an action already in flight checks again
        // after scheduling and removes its own obsolete snooze.
        await snoozeRegistry.invalidateAll();
        await flutterLocalNotificationsPlugin.cancelAll();
      });

  Future<void> removeNotification(Reminder reminder) => _serialize(() async {
        final previous = await snoozeRegistry.invalidate(reminder.reminderId);
        // Attempt both even if a platform cancellation fails for one ID.
        await Future.wait([
          flutterLocalNotificationsPlugin.cancel(id: reminder.reminderId),
          if (previous != null)
            flutterLocalNotificationsPlugin.cancel(id: previous.snoozeId),
        ]);
      });

  /// Upgrade native requests made by older releases without changing current
  /// snoozes or reactivating reminders intentionally omitted during restore.
  Future<void> upgradePendingReminders(
          List<Reminder> reminders, NoteRepository notes) =>
      _serialize(() async {
        try {
          final pending = await flutterLocalNotificationsPlugin
              .pendingNotificationRequests();
          final labels = await _actionLabels();
          for (final request in pending) {
            if (request.id < 0 ||
                ReminderNotificationPayload.tryDecode(request.payload) !=
                    null ||
                await snoozeRegistry.hasRegistration(request.id)) {
              continue;
            }
            final matches = reminders.where((r) => r.reminderId == request.id);
            if (matches.isEmpty) continue;
            final reminder = matches.first;
            if (!reminder.isSchedulable(DateTime.now())) continue;
            final note = await notes.getNote(reminder.noteId);
            if (note.isDeleted) continue;
            await _scheduleRegistered(
                id: reminder.reminderId,
                title: labels.Onlynote,
                body: '${labels.Reminder}: ${note.title ?? ''}',
                time: reminder.reminderDate,
                noteId: reminder.noteId,
                repeat: reminder.repeat);
          }
        } catch (error) {
          debugPrint('Reminder action upgrade deferred: $error');
        }
      });

  Future<bool?> checkAndAskForPermission(BuildContext context) async {
    final result = await _requestPlatformPermissions();

    debugPrint("Notification permission result: $result");
    if (!context.mounted) return result;

    if (result != null) {
      if (result == false) {
        openNotificationSettingDialog(context);
      }
    } else {
      openNotificationSettingDialog(context);
    }

    return result;
  }

  void openNotificationSettingDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          scrollable: true,
          icon: const Icon(Icons.notifications_outlined),
          title: Text(S.of(context).Allow_Notification),
          content: Text(S.of(context).To_get_notification),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(S.of(context).Cancel),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                AppSettings.openAppSettings(type: AppSettingsType.notification);
              },
              child: Text(S.of(context).Settings),
            ),
          ],
        );
      },
    );
  }

  void scheduleNotification(
      BuildContext context, Note note, Reminder reminder) {
    debugPrint('$reminder');
    scheduleNotifications(
        id: reminder.reminderId,
        title: S.of(context).Onlynote,
        body: '${S.of(context).Reminder}: ${note.title ?? ""}',
        time: reminder.reminderDate,
        noteId: reminder.noteId,
        repeat: reminder.repeat);
  }

  Future<bool> scheduleNotifications({
    required int id,
    required String title,
    required String body,
    required DateTime time,
    required String noteId,
    ReminderRepeat repeat = ReminderRepeat.none,
  }) =>
      _serialize(() => _scheduleRegistered(
          id: id,
          title: title,
          body: body,
          time: time,
          noteId: noteId,
          repeat: repeat));

  Future<bool> _scheduleRegistered(
      {required int id,
      required String title,
      required String body,
      required DateTime time,
      required String noteId,
      required ReminderRepeat repeat}) async {
    ReminderSnoozeRegistration? registration;
    try {
      await NotificationTimezone.initialize();
      registration = await snoozeRegistry.prepare(
          noteId: noteId, reminderId: id, title: title, body: body);
      final scheduled = await _scheduleNative(
          id: id,
          title: title,
          body: body,
          time: time,
          payload: registration.payload.encode(),
          repeat: repeat,
          refreshTimezone: false);
      if (!scheduled) {
        await snoozeRegistry.restore(registration.previous,
            replacing: registration.payload);
        return false;
      }
      if (registration.previous != null) {
        try {
          await flutterLocalNotificationsPlugin.cancel(
              id: registration.previous!.snoozeId);
        } catch (error) {
          // Scheduling already succeeded. Keep its action revision active.
          debugPrint('Obsolete snooze cleanup deferred: $error');
        }
      }
      return true;
    } catch (error) {
      // Keep the native action payload and registry in agreement on failure.
      if (registration != null) {
        await snoozeRegistry.restore(registration.previous,
            replacing: registration.payload);
      }
      debugPrint('Could not schedule reminder: $error');
      return false;
    }
  }

  Future<bool> _scheduleNative({
    required int id,
    required String title,
    required String body,
    required DateTime time,
    required String payload,
    required ReminderRepeat repeat,
    bool refreshTimezone = true,
  }) async {
    try {
      if (refreshTimezone) await NotificationTimezone.initialize();
      final labels = await _actionLabels();
      final pattern = time.toLocal();
      // Preserve calendar components for native daily/weekly matching.
      final date = repeat == ReminderRepeat.none
          ? time
          : DateTime(2024, 1, pattern.weekday, pattern.hour, pattern.minute,
              pattern.second, pattern.millisecond, pattern.microsecond);
      final scheduledDate = date.isUtc
          ? tz.TZDateTime.from(date, tz.local)
          : tz.TZDateTime(tz.local, date.year, date.month, date.day, date.hour,
              date.minute, date.second, date.millisecond, date.microsecond);
      await flutterLocalNotificationsPlugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        payload: payload,
        scheduledDate: scheduledDate,
        matchDateTimeComponents: switch (repeat) {
          ReminderRepeat.none => null,
          ReminderRepeat.daily => DateTimeComponents.time,
          ReminderRepeat.weekly => DateTimeComponents.dayOfWeekAndTime,
        },
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
              'your channel id', 'your channel name',
              channelDescription: 'your channel description',
              actions: [
                AndroidNotificationAction(ReminderSnooze.tenMinutes,
                    labels.Reminder_Snooze_10_Minutes),
                AndroidNotificationAction(
                    ReminderSnooze.oneHour, labels.Reminder_Snooze_1_Hour),
              ]),
          iOS: const DarwinNotificationDetails(
              categoryIdentifier: _category,
              presentAlert: true,
              presentBadge: true,
              presentSound: true),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
      return true;
    } catch (error) {
      debugPrint('Could not schedule reminder notification: $error');
      return false;
    }
  }

  Future<bool> isNotificationOpen() async {
    final pendingNotificationRequests =
        await flutterLocalNotificationsPlugin.pendingNotificationRequests();
    return pendingNotificationRequests.isNotEmpty;
  }
}
