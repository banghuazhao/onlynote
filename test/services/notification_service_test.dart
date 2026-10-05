import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/Tools/notification_service.dart';
import 'package:onlynote/Tools/reminder.dart';
import 'package:onlynote/Tools/reminder_launch.dart';
import 'package:onlynote/Tools/reminder_notification_payload.dart';
import 'package:onlynote/data/dto/note_dto.dart';
import 'package:onlynote/domain/repository/note_repository.dart';
import 'package:onlynote/presentation/routes/routes.dart';
import 'package:onlynote/services/reminder_snooze.dart';
import 'package:timezone/timezone.dart' as tz;

import '../support/memory_preferences.dart';

/// Records which notification responses reach the note launcher. Returning
/// trashed notes prevents navigation here; routing has its own widget tests.
class _LookupNotes extends Fake implements NoteRepository {
  final lookedUp = <String>[];

  @override
  Future<NoteDto> getNote(String id) async {
    lookedUp.add(id);
    return NoteDto(id: id, deletedAt: '2026-01-01T00:00:00');
  }
}

class _StoredNotes extends Fake implements NoteRepository {
  _StoredNotes(Iterable<NoteDto> notes)
      : notes = {for (final note in notes) note.id!: note};

  final Map<String, NoteDto> notes;
  final lookedUp = <String>[];

  @override
  Future<NoteDto> getNote(String id) async {
    lookedUp.add(id);
    return notes[id]!;
  }
}

void _usePlatform(TargetPlatform platform) {
  debugDefaultTargetPlatformOverride = platform;
  if (platform == TargetPlatform.android) {
    AndroidFlutterLocalNotificationsPlugin.registerWith();
  } else {
    IOSFlutterLocalNotificationsPlugin.registerWith();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('dexterous.com/flutter/local_notifications');
  const timezoneChannel = MethodChannel('flutter_timezone');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late List<MethodCall> calls;
  late Map<String, Object?> launchDetails;
  late String timezoneIdentifier;
  late int timezoneRequests;
  late ReminderSnoozeRegistry registry;
  late bool failNextSchedule;
  late Set<int> failCancellationIds;
  late List<Map<String, Object?>> pendingRequests;
  late Map<int, Map> nativeSchedules;
  void Function()? onNativeSchedule;

  NotificationService makeService() =>
      NotificationService(snoozeRegistry: registry);

  ReminderNotificationPayload payloadOf(Map arguments) =>
      ReminderNotificationPayload.tryDecode(arguments['payload'] as String)!;

  List<Map> scheduledCalls() => calls
      .where((call) => call.method == 'zonedSchedule')
      .map((call) => call.arguments as Map)
      .toList();

  setUp(() {
    calls = [];
    launchDetails = {'notificationLaunchedApp': false};
    timezoneIdentifier = 'Pacific/Auckland';
    timezoneRequests = 0;
    registry = ReminderSnoozeRegistry(preferences: MemoryPreferences());
    failNextSchedule = false;
    failCancellationIds = {};
    pendingRequests = [];
    nativeSchedules = {};
    onNativeSchedule = null;
    messenger.setMockMethodCallHandler(timezoneChannel, (call) async {
      expect(call.method, 'getLocalTimezone');
      timezoneRequests++;
      return {'identifier': timezoneIdentifier};
    });
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      switch (call.method) {
        case 'initialize':
          return true;
        case 'getNotificationAppLaunchDetails':
          return launchDetails;
        case 'zonedSchedule':
          if (failNextSchedule) {
            failNextSchedule = false;
            throw PlatformException(code: 'schedule_failed');
          }
          final arguments = call.arguments as Map;
          nativeSchedules[arguments['id'] as int] = Map.of(arguments);
          onNativeSchedule?.call();
          return null;
        case 'cancel':
          final arguments = call.arguments;
          final id =
              arguments is int ? arguments : (arguments as Map)['id'] as int;
          if (failCancellationIds.contains(id)) {
            throw PlatformException(code: 'cancel_failed');
          }
          nativeSchedules.remove(id);
          return null;
        case 'cancelAll':
          nativeSchedules.clear();
          return null;
        case 'pendingNotificationRequests':
          return pendingRequests;
        default:
          return null;
      }
    });
  });

  tearDown(() {
    ReminderLaunch.instance.detach();
    messenger.setMockMethodCallHandler(channel, null);
    messenger.setMockMethodCallHandler(timezoneChannel, null);
    debugDefaultTargetPlatformOverride = null;
  });

  for (final platform in [TargetPlatform.android, TargetPlatform.iOS]) {
    test('${platform.name} schedules note identity and native snooze actions',
        () async {
      _usePlatform(platform);
      final service = makeService();
      await service.init();
      final scheduled = await service.scheduleNotifications(
        id: 42,
        title: 'Onlynote',
        body: 'Reminder: Shopping',
        time: DateTime.now().add(const Duration(hours: 1)),
        noteId: 'shopping-note',
      );

      expect(scheduled, isTrue);
      final arguments = calls
          .singleWhere((call) => call.method == 'zonedSchedule')
          .arguments as Map;
      expect(arguments['id'], 42);
      expect(payloadOf(arguments).noteId, 'shopping-note');
      expect(arguments['timeZoneName'], 'Pacific/Auckland');
      expect(arguments.containsKey('matchDateTimeComponents'), isFalse);

      final specific = arguments['platformSpecifics'] as Map;
      if (platform == TargetPlatform.android) {
        final actions = (specific['actions'] as List).cast<Map>();
        expect(actions.map((action) => action['id']),
            [ReminderSnooze.tenMinutes, ReminderSnooze.oneHour]);
        expect(actions.every((action) => action['showsUserInterface'] == false),
            isTrue);
        expect(actions.every((action) => action['cancelNotification'] == true),
            isTrue);
      } else {
        final initialize = calls
            .singleWhere((call) => call.method == 'initialize')
            .arguments as Map;
        final category =
            (initialize['notificationCategories'] as List).single as Map;
        expect(specific['categoryIdentifier'], category['identifier']);
        final actions = (category['actions'] as List).cast<Map>();
        expect(actions.map((action) => action['identifier']),
            [ReminderSnooze.tenMinutes, ReminderSnooze.oneHour]);
        expect(actions.every((action) => (action['options'] as List).isEmpty),
            isTrue);
        expect(specific['presentSound'], isTrue);
      }
    });

    for (final repeat in [ReminderRepeat.daily, ReminderRepeat.weekly]) {
      test('${platform.name} schedules ${repeat.name} at the local clock time',
          () async {
        _usePlatform(platform);
        final service = makeService();
        await service.init();
        final scheduled = await service.scheduleNotifications(
          id: 42,
          title: 'Onlynote',
          body: 'Reminder: Shopping',
          time: DateTime(2020, 1, 6, 9, 30),
          noteId: 'shopping-note',
          repeat: repeat,
        );

        expect(scheduled, isTrue);
        final arguments = calls
            .singleWhere((call) => call.method == 'zonedSchedule')
            .arguments as Map;
        expect(
            arguments['matchDateTimeComponents'],
            repeat == ReminderRepeat.daily
                ? DateTimeComponents.time.index
                : DateTimeComponents.dayOfWeekAndTime.index);
        expect(arguments['timeZoneName'], 'Pacific/Auckland');
        expect(payloadOf(arguments).noteId, 'shopping-note');
        final date = DateTime.parse(arguments['scheduledDateTime'] as String);
        expect(date.hour, 9);
        expect(date.minute, 30);
        if (repeat == ReminderRepeat.weekly) {
          expect(date.weekday, DateTime.monday);
        }
      });
    }

    test('${platform.name} preserves one-time instants across DST offsets',
        () async {
      _usePlatform(platform);
      final service = makeService();
      await service.init();
      final zone = tz.getLocation('Pacific/Auckland');
      for (final date in [
        tz.TZDateTime(zone, 2030, 1, 2, 9),
        tz.TZDateTime(zone, 2030, 7, 2, 9),
      ]) {
        await service.scheduleNotifications(
          id: 42,
          title: 'Onlynote',
          body: 'Reminder',
          time: date.toUtc(),
          noteId: 'shopping-note',
        );
      }

      final arguments = calls
          .where((call) => call.method == 'zonedSchedule')
          .map((call) => call.arguments as Map)
          .toList();
      expect(arguments, hasLength(2));
      expect(arguments[0]['scheduledDateTime'], '2030-01-02T09:00:00');
      expect(arguments[1]['scheduledDateTime'], '2030-07-02T09:00:00');
      expect(arguments[0]['scheduledDateTimeISO8601'], endsWith('+1300'));
      expect(arguments[1]['scheduledDateTimeISO8601'], endsWith('+1200'));
    });

    test('${platform.name} refreshes the device timezone before scheduling',
        () async {
      _usePlatform(platform);
      final service = makeService();
      await service.init();
      timezoneIdentifier = 'America/New_York';
      expect(
          await service.scheduleNotifications(
            id: 42,
            title: 'Onlynote',
            body: 'Reminder',
            time: DateTime(2030, 1, 1, 9),
            noteId: 'shopping-note',
          ),
          isTrue);

      final arguments = calls
          .singleWhere((call) => call.method == 'zonedSchedule')
          .arguments as Map;
      expect(arguments['timeZoneName'], 'America/New_York');
      expect(timezoneRequests, 2);
    });

    test(
        '${platform.name} reports an invalid timezone without blocking startup',
        () async {
      _usePlatform(platform);
      timezoneIdentifier = 'Invalid/Timezone';
      final service = makeService();
      await service.init();
      expect(
          await service.scheduleNotifications(
            id: 42,
            title: 'Onlynote',
            body: 'Reminder',
            time: DateTime(2030, 1, 1, 9),
            noteId: 'shopping-note',
            repeat: ReminderRepeat.daily,
          ),
          isFalse);

      expect(calls.where((call) => call.method == 'initialize'), hasLength(1));
      expect(calls.where((call) => call.method == 'zonedSchedule'), isEmpty);
    });

    test(
        '${platform.name} snoozes a daily reminder without replacing its repeat',
        () async {
      _usePlatform(platform);
      final service = makeService();
      await service.init();
      await service.scheduleNotifications(
        id: 42,
        title: 'Onlynote',
        body: 'Reminder: Daily plan',
        time: DateTime(2020, 1, 6, 9, 30),
        noteId: 'daily-plan',
        repeat: ReminderRepeat.daily,
      );
      final base = Map.of(nativeSchedules[42]!);
      final payload = payloadOf(base);

      expect(
          await service.handleSnoozeResponse(NotificationResponse(
            notificationResponseType:
                NotificationResponseType.selectedNotificationAction,
            id: 42,
            payload: payload.encode(),
            actionId: ReminderSnooze.tenMinutes,
          )),
          isTrue);

      final snoozed = nativeSchedules[payload.snoozeId]!;
      expect(nativeSchedules[42], base);
      expect(snoozed.containsKey('matchDateTimeComponents'), isFalse);
      expect(snoozed['payload'], payload.encode());
      expect(snoozed['title'], base['title']);
      expect(snoozed['body'], base['body']);
      expect(calls.where((call) => call.method == 'cancel'), isEmpty);
    });

    test('${platform.name} removal cancels the base and its snooze', () async {
      _usePlatform(platform);
      final service = makeService();
      await service.init();
      final date = DateTime.now().add(const Duration(hours: 1));
      await service.scheduleNotifications(
        id: 42,
        title: 'Onlynote',
        body: 'Reminder: Shopping',
        time: date,
        noteId: 'shopping-note',
      );
      final payload = payloadOf(nativeSchedules[42]!);
      await service.handleSnoozeResponse(NotificationResponse(
        notificationResponseType:
            NotificationResponseType.selectedNotificationAction,
        id: 42,
        payload: payload.encode(),
        actionId: ReminderSnooze.oneHour,
      ));

      await service.removeNotification(Reminder(
        reminderDate: date,
        reminderId: 42,
        noteId: 'shopping-note',
      ));

      expect(nativeSchedules, isEmpty);
      expect(
          calls.where((call) => call.method == 'cancel').map((call) =>
              call.arguments is int
                  ? call.arguments
                  : (call.arguments as Map)['id']),
          [42, payload.snoozeId]);
      expect(await registry.isCurrent(payload), isFalse);
      expect(await registry.hasRegistration(42), isTrue);
      expect(
          await service.handleSnoozeResponse(NotificationResponse(
            notificationResponseType:
                NotificationResponseType.selectedNotificationAction,
            id: 42,
            payload: payload.encode(),
            actionId: ReminderSnooze.tenMinutes,
          )),
          isFalse);
    });

    test(
        '${platform.name} clearing notifications invalidates delivered actions',
        () async {
      _usePlatform(platform);
      final service = makeService();
      await service.init();
      await service.scheduleNotifications(
        id: 42,
        title: 'Onlynote',
        body: 'Reminder: Shopping',
        time: DateTime.now().add(const Duration(hours: 1)),
        noteId: 'shopping-note',
      );
      final payload = payloadOf(nativeSchedules[42]!);

      await service.clearAll();

      expect(nativeSchedules, isEmpty);
      expect(calls.where((call) => call.method == 'cancelAll'), hasLength(1));
      expect(await registry.isCurrent(payload), isFalse);
      expect(
          await service.handleSnoozeResponse(NotificationResponse(
            notificationResponseType:
                NotificationResponseType.selectedNotificationAction,
            id: 42,
            payload: payload.encode(),
            actionId: ReminderSnooze.tenMinutes,
          )),
          isFalse);
      expect(scheduledCalls(), hasLength(1));
    });

    test(
        '${platform.name} a failed edit preserves the base and action identity',
        () async {
      _usePlatform(platform);
      final service = makeService();
      await service.init();
      await service.scheduleNotifications(
        id: 42,
        title: 'Onlynote',
        body: 'Reminder: Shopping',
        time: DateTime.now().add(const Duration(hours: 1)),
        noteId: 'shopping-note',
      );
      final base = Map.of(nativeSchedules[42]!);
      final payload = payloadOf(base);
      failNextSchedule = true;

      expect(
          await service.scheduleNotifications(
            id: 42,
            title: 'Onlynote',
            body: 'Reminder: Edited shopping',
            time: DateTime.now().add(const Duration(hours: 2)),
            noteId: 'shopping-note',
          ),
          isFalse);

      expect(nativeSchedules[42], base);
      expect(await registry.isCurrent(payload), isTrue);
      expect(calls.where((call) => call.method == 'cancel'), isEmpty);
    });

    test('${platform.name} cleanup failure keeps the successful edit active',
        () async {
      _usePlatform(platform);
      final service = makeService();
      await service.init();
      await service.scheduleNotifications(
        id: 42,
        title: 'Onlynote',
        body: 'Reminder: Shopping',
        time: DateTime.now().add(const Duration(hours: 1)),
        noteId: 'shopping-note',
      );
      final previous = payloadOf(nativeSchedules[42]!);
      failCancellationIds.add(previous.snoozeId);

      expect(
          await service.scheduleNotifications(
            id: 42,
            title: 'Onlynote',
            body: 'Reminder: Edited shopping',
            time: DateTime.now().add(const Duration(hours: 2)),
            noteId: 'shopping-note',
          ),
          isTrue);

      final current = payloadOf(nativeSchedules[42]!);
      expect(await registry.isCurrent(current), isTrue);
      expect(await registry.isCurrent(previous), isFalse);
      expect(current.snoozeId, isNot(previous.snoozeId));
    });

    test('${platform.name} upgrades only active legacy native requests',
        () async {
      _usePlatform(platform);
      final service = makeService();
      await service.init();
      final modern = (await registry.prepare(
              noteId: 'modern',
              reminderId: 46,
              title: 'Onlynote',
              body: 'Reminder: Modern'))
          .payload;
      await registry.invalidate(49);
      pendingRequests = [
        for (final id in [42, 43, 44, 45, 48, 49])
          {
            'id': id,
            'title': 'Onlynote',
            'body': 'Reminder',
            'payload': 'legacy'
          },
        {'id': 46, 'payload': modern.encode()},
        {'id': modern.snoozeId, 'payload': modern.encode()},
      ];
      final future = DateTime.now().add(const Duration(days: 1));
      final reminders = [
        Reminder(noteId: 'future', reminderId: 42, reminderDate: future),
        Reminder(
            noteId: 'daily',
            reminderId: 43,
            reminderDate: DateTime(2020),
            repeat: ReminderRepeat.daily),
        Reminder(
            noteId: 'expired', reminderId: 44, reminderDate: DateTime(2020)),
        Reminder(noteId: 'trashed', reminderId: 45, reminderDate: future),
        Reminder(noteId: 'modern', reminderId: 46, reminderDate: future),
        Reminder(noteId: 'canceled', reminderId: 49, reminderDate: future),
      ];
      final notes = _StoredNotes([
        NoteDto(id: 'future', title: 'Future'),
        NoteDto(id: 'daily', title: 'Daily'),
        NoteDto(id: 'expired'),
        NoteDto(id: 'trashed', deletedAt: '2026-01-01T00:00:00'),
        NoteDto(id: 'modern'),
        NoteDto(id: 'canceled'),
      ]);

      await service.upgradePendingReminders(reminders, notes);

      expect(scheduledCalls().map((call) => call['id']), [42, 43]);
      expect(scheduledCalls().map((call) => payloadOf(call).noteId),
          ['future', 'daily']);
      expect(await registry.isCurrent(modern), isTrue);
      expect(notes.lookedUp, ['future', 'daily', 'trashed']);
      expect(calls.where((call) => call.method == 'cancel'), isEmpty);
    });

    test('${platform.name} snooze actions handle cold and warm callbacks',
        () async {
      _usePlatform(platform);
      final payload = (await registry.prepare(
              noteId: 'shopping-note',
              reminderId: 42,
              title: 'Onlynote',
              body: 'Reminder: Shopping'))
          .payload;
      launchDetails = {
        'notificationLaunchedApp': true,
        'notificationResponse': {
          'notificationId': 42,
          'notificationResponseType': 1,
          'actionId': ReminderSnooze.tenMinutes,
          'payload': payload.encode(),
        },
      };
      final notes = _LookupNotes();
      final router = AppRouter();
      addTearDown(router.dispose);
      ReminderLaunch.instance.attach(
        router: router,
        notes: notes,
        reminders: () => [],
      );
      final service = makeService();
      final coldScheduled = Completer<void>();
      onNativeSchedule = coldScheduled.complete;
      // No widgets are involved in snoozing. Keep the callbacks and their
      // Future queues in one async zone instead of crossing FakeAsync/runAsync.
      await service.init();
      await coldScheduled.future.timeout(const Duration(seconds: 5));
      await Future<void>.delayed(Duration.zero);
      expect(scheduledCalls(), hasLength(1));
      expect(scheduledCalls().single['id'], payload.snoozeId);
      expect(notes.lookedUp, isEmpty);

      final warmScheduled = Completer<void>();
      onNativeSchedule = warmScheduled.complete;
      await messenger.handlePlatformMessage(
        channel.name,
        channel.codec.encodeMethodCall(MethodCall(
          'didReceiveNotificationResponse',
          {
            'notificationId': payload.snoozeId,
            'notificationResponseType': 1,
            'actionId': ReminderSnooze.oneHour,
            'payload': payload.encode(),
          },
        )),
        (_) {},
      );
      await warmScheduled.future.timeout(const Duration(seconds: 5));
      await Future<void>.delayed(Duration.zero);

      expect(scheduledCalls(), hasLength(2));
      expect(scheduledCalls().last['id'], payload.snoozeId);
      expect(notes.lookedUp, isEmpty);
    });

    testWidgets('${platform.name} forwards cold and native warm taps',
        (tester) async {
      _usePlatform(platform);
      launchDetails = {
        'notificationLaunchedApp': true,
        'notificationResponse': {
          'notificationId': 41,
          'notificationResponseType': 0,
          'payload': 'cold-note',
        },
      };
      final notes = _LookupNotes();
      final router = AppRouter();
      addTearDown(router.dispose);

      // Initialization happens before storage and the app's router attach.
      await makeService().init();
      expect(notes.lookedUp, isEmpty);
      ReminderLaunch.instance.attach(
        router: router,
        notes: notes,
        reminders: () => [],
      );
      await tester.pumpAndSettle();
      expect(notes.lookedUp, ['cold-note']);

      await messenger.handlePlatformMessage(
        channel.name,
        channel.codec.encodeMethodCall(const MethodCall(
          'didReceiveNotificationResponse',
          {
            'notificationId': 42,
            'notificationResponseType': 0,
            'payload': 'warm-note',
          },
        )),
        (_) {},
      );
      await tester.pumpAndSettle();

      expect(notes.lookedUp, ['cold-note', 'warm-note']);
      expect(
        calls.where((call) => call.method == 'getNotificationAppLaunchDetails'),
        hasLength(1),
      );
      expect(tester.takeException(), isNull);
    }, variant: TargetPlatformVariant.only(platform));
  }
}
