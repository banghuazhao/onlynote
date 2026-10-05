import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/Tools/notification_service.dart';
import 'package:onlynote/Tools/reminder.dart';
import 'package:onlynote/Tools/reminder_launch.dart';
import 'package:onlynote/data/dto/note_dto.dart';
import 'package:onlynote/domain/repository/note_repository.dart';
import 'package:onlynote/presentation/routes/routes.dart';
import 'package:timezone/timezone.dart' as tz;

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

  setUp(() {
    calls = [];
    launchDetails = {'notificationLaunchedApp': false};
    timezoneIdentifier = 'Pacific/Auckland';
    timezoneRequests = 0;
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
    test('${platform.name} schedules the note ID as its notification payload',
        () async {
      _usePlatform(platform);
      final service = NotificationService();
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
      expect(arguments['payload'], 'shopping-note');
      expect(arguments['timeZoneName'], 'Pacific/Auckland');
      expect(arguments.containsKey('matchDateTimeComponents'), isFalse);
    });

    for (final repeat in [ReminderRepeat.daily, ReminderRepeat.weekly]) {
      test('${platform.name} schedules ${repeat.name} at the local clock time',
          () async {
        _usePlatform(platform);
        final service = NotificationService();
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
        expect(arguments['payload'], 'shopping-note');
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
      final service = NotificationService();
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
      final service = NotificationService();
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
      final service = NotificationService();
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
      await NotificationService().init();
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
