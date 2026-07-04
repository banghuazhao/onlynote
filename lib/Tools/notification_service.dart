import 'dart:io';

import 'package:app_settings/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:onlynote/Tools/reminder.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  //instance of FlutterLocalNotificationsPlugin
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    //Initialization Settings for Android
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    //Initialization Settings for iOS
    const DarwinInitializationSettings initializationSettingsIOS = DarwinInitializationSettings(
      requestSoundPermission: false,
      requestBadgePermission: false,
      requestAlertPermission: false,
    );

    //Initializing settings for both platforms (Android & iOS)
    const InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid, iOS: initializationSettingsIOS);

    tz.initializeTimeZones();

    await flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: onDidReceiveNotificationResponse,
    );
  }

  void onDidReceiveNotificationResponse(NotificationResponse response) {
    //Navigate to wherever you want
  }

  Future<bool?>? requestIOSPermissions() {
    return flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
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
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  Future<bool?> _requestPlatformPermissions() {
    if (Platform.isIOS) {
      return requestIOSPermissions() ?? Future.value(true);
    }
    return requestAndroidPermissions() ?? Future.value(true);
  }

  Future<void> showNotifications({id, title, body, payload}) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
        'your channel id', 'your channel name',
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
    var result = await _requestPlatformPermissions();

    print("Notification permission result: $result");

    if (result != null) {
      if (result == false) {
        openNotificationSettingDialog(context);
      }
    } else {
      openNotificationSettingDialog(context);
    }

    scheduleNotification(context, note, reminder);

    var pendingNotificationRequests =
        await flutterLocalNotificationsPlugin.pendingNotificationRequests();

    print("pendingNotificationRequests count: ${pendingNotificationRequests.length}");
    for (PendingNotificationRequest request in pendingNotificationRequests) {
      print("${request.id}: ${request.title}");
    }
  }

  Future<void> clearAll() async {
    await flutterLocalNotificationsPlugin.cancelAll();
    var pendingNotificationRequests =
        await flutterLocalNotificationsPlugin.pendingNotificationRequests();

    print(
        "after clear all: pendingNotificationRequests count: ${pendingNotificationRequests.length}");
    for (PendingNotificationRequest request in pendingNotificationRequests) {
      print("${request.id}: ${request.title}");
    }
  }

  Future<void> removeNotification(Reminder reminder) async {
    await flutterLocalNotificationsPlugin.cancel(id: reminder.reminderId);
  }

  Future<bool?> checkAndAskForPermission(BuildContext context) async {
    var result = await _requestPlatformPermissions();

    print("Notification permission result: $result");

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
          backgroundColor: Color(0xFFFDF9F5),
          title: Text(
            S.of(context).Allow_Notification,
          ),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(
                  S.of(context).To_get_notification,
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                S.of(context).OK,
                style: TextStyle(color: Color(0xFFAE7056), fontSize: 18),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                AppSettings.openAppSettings(type: AppSettingsType.notification);
              },
            ),
            TextButton(
              child: Text(
                S.of(context).Cancel,
                style: TextStyle(color: Color(0xFFAE7056), fontSize: 18),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void scheduleNotification(BuildContext context, Note note, Reminder reminder) {
    print(reminder);
    NotificationService().scheduleNotifications(
        id: reminder.reminderId,
        title: S.of(context).Onlynote,
        body: S.of(context).Reminder + ": " + (note.title ?? ""),
        time: reminder.reminderDate);
  }

  Future<void> scheduleNotifications({id, title, body, time}) async {
    try {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: tz.TZDateTime.from(time, tz.local),
        notificationDetails: const NotificationDetails(
            android: AndroidNotificationDetails('your channel id', 'your channel name',
                channelDescription: 'your channel description')),
        // Inexact avoids needing the restricted SCHEDULE_EXACT_ALARM /
        // USE_EXACT_ALARM permission on Android 12+ — fine for a note
        // reminder, which doesn't need to-the-second precision.
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    } catch (e) {
      print(e);
    }
  }

  Future<bool> isNotificationOpen() async {
    var pendingNotificationRequests =
        await flutterLocalNotificationsPlugin.pendingNotificationRequests();
    return pendingNotificationRequests.isNotEmpty;
  }
}
