import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/Tools/notification_service.dart';
import 'package:onlynote/Tools/reminder_launch.dart';
import 'package:onlynote/data/dto/note_dto.dart';
import 'package:onlynote/domain/repository/note_repository.dart';
import 'package:onlynote/presentation/routes/routes.dart';

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
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late List<MethodCall> calls;
  late Map<String, Object?> launchDetails;

  setUp(() {
    calls = [];
    launchDetails = {'notificationLaunchedApp': false};
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
