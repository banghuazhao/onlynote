import 'dart:async';
import 'dart:convert';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/Tools/reminder_notification_payload.dart';
import 'package:onlynote/services/reminder_snooze.dart';

import '../support/memory_preferences.dart';

NotificationResponse _action(
  ReminderNotificationPayload payload, {
  String actionId = 'onlynote_snooze_10m',
  int? id,
}) =>
    NotificationResponse(
      notificationResponseType:
          NotificationResponseType.selectedNotificationAction,
      id: id ?? payload.reminderId,
      payload: payload.encode(),
      actionId: actionId,
    );

void main() {
  late MemoryPreferences preferences;
  late ReminderSnoozeRegistry registry;
  late ReminderSnooze snooze;
  late List<(ReminderNotificationPayload, DateTime)> scheduled;
  late List<int> cancelled;
  late DateTime clock;

  Future<ReminderNotificationPayload> prepare({
    int reminderId = 42,
    String noteId = 'shopping',
  }) async =>
      (await registry.prepare(
        noteId: noteId,
        reminderId: reminderId,
        title: 'Onlynote',
        body: 'Reminder: Shopping',
      ))
          .payload;

  setUp(() {
    preferences = MemoryPreferences();
    registry = ReminderSnoozeRegistry(preferences: preferences);
    scheduled = [];
    cancelled = [];
    clock = DateTime.utc(2026, 10, 5, 10, 20, 30);
    snooze = ReminderSnooze(
      registry: registry,
      now: () => clock,
      schedule: (payload, date) async {
        scheduled.add((payload, date));
        return true;
      },
      cancel: (id) async {
        cancelled.add(id);
      },
    );
  });

  for (final (actionId, delay) in [
    ('onlynote_snooze_10m', const Duration(minutes: 10)),
    ('onlynote_snooze_1h', const Duration(hours: 1)),
  ]) {
    test('$actionId adds a separate reminder after the elapsed delay',
        () async {
      final payload = await prepare();

      expect(await snooze.handleResponse(_action(payload, actionId: actionId)),
          isTrue);

      final (notification, due) = scheduled.single;
      expect(notification.reminderId, 42);
      expect(notification.snoozeId, inInclusiveRange(-0x80000000, -1));
      expect(notification.noteId, 'shopping');
      expect(notification.title, 'Onlynote');
      expect(notification.body, 'Reminder: Shopping');
      expect(due, clock.add(delay));
      expect(due.isUtc, isTrue);
      // Snooze must leave the base notification's daily/weekly schedule alone.
      expect(cancelled, isNot(contains(42)));
    });
  }

  test('snoozing the delivered snooze replaces its ID and keeps the base',
      () async {
    final payload = await prepare();
    expect(await snooze.handleResponse(_action(payload)), isTrue);
    clock = clock.add(const Duration(minutes: 12));

    expect(
        await snooze.handleResponse(_action(payload,
            id: payload.snoozeId, actionId: 'onlynote_snooze_1h')),
        isTrue);

    expect(scheduled, hasLength(2));
    expect(scheduled.first.$1.snoozeId, scheduled.last.$1.snoozeId);
    expect(scheduled.last.$2, clock.add(const Duration(hours: 1)));
    expect(cancelled, isNot(contains(payload.reminderId)));
  });

  test('body taps, unknown actions and malformed payloads cannot snooze',
      () async {
    final payload = await prepare();
    final responses = [
      NotificationResponse(
        notificationResponseType: NotificationResponseType.selectedNotification,
        id: payload.reminderId,
        payload: payload.encode(),
      ),
      _action(payload, actionId: 'other_action'),
      NotificationResponse(
        notificationResponseType:
            NotificationResponseType.selectedNotificationAction,
        id: 42,
        payload: 'shopping',
        actionId: 'onlynote_snooze_10m',
      ),
      NotificationResponse(
        notificationResponseType:
            NotificationResponseType.selectedNotificationAction,
        id: 42,
        payload: '{invalid json',
        actionId: 'onlynote_snooze_10m',
      ),
      _action(payload, id: 123),
    ];

    for (final response in responses) {
      expect(await snooze.handleResponse(response), isFalse);
    }
    expect(scheduled, isEmpty);
    expect(cancelled, isEmpty);
  });

  test('changed notification content cannot impersonate a current reminder',
      () async {
    final payload = await prepare();
    final tampered = jsonDecode(payload.encode()) as Map<String, dynamic>;
    tampered['noteId'] = 'different-note';
    expect(
        await snooze.handleResponse(NotificationResponse(
          notificationResponseType:
              NotificationResponseType.selectedNotificationAction,
          id: payload.reminderId,
          payload: jsonEncode(tampered),
          actionId: 'onlynote_snooze_10m',
        )),
        isFalse);
    expect(scheduled, isEmpty);
  });

  test('removing or trashing a reminder rejects an older delivered action',
      () async {
    final payload = await prepare();
    await registry.invalidate(payload.reminderId);

    expect(await snooze.handleResponse(_action(payload)), isFalse);
    expect(scheduled, isEmpty);
  });

  test('editing invalidates old actions and allocates a different snooze ID',
      () async {
    final old = await prepare();
    final edited = await prepare();

    expect(edited.snoozeId, isNot(old.snoozeId));
    expect(await snooze.handleResponse(_action(old)), isFalse);
    expect(await snooze.handleResponse(_action(edited)), isTrue);
    expect(scheduled.single.$1.revision, edited.revision);
  });

  test('a failed edit can restore the previous notification identity',
      () async {
    final original = await prepare();
    final edit = await registry.prepare(
      noteId: original.noteId,
      reminderId: original.reminderId,
      title: 'Onlynote',
      body: 'Reminder: Edited shopping',
    );
    expect(await registry.isCurrent(original), isFalse);

    await registry.restore(edit.previous, replacing: edit.payload);

    expect(await registry.isCurrent(original), isTrue);
    expect(await registry.isCurrent(edit.payload), isFalse);
    expect(await snooze.handleResponse(_action(original)), isTrue);
  });

  test('a late edit rollback cannot replace a newer notification identity',
      () async {
    await prepare();
    final edit = await registry.prepare(
      noteId: 'shopping',
      reminderId: 42,
      title: 'Onlynote',
      body: 'Reminder: First edit',
    );
    final newest = await prepare();

    await registry.restore(edit.previous, replacing: edit.payload);

    expect(await registry.isCurrent(newest), isTrue);
    expect(await registry.isCurrent(edit.payload), isFalse);
  });

  test('snooze IDs remain unique when foreground registry is recreated',
      () async {
    final first = await prepare();
    registry = ReminderSnoozeRegistry(preferences: preferences);
    final second = await prepare(reminderId: 43, noteId: 'packing');

    expect(second.snoozeId, isNot(first.snoozeId));
    expect(await registry.isCurrent(first), isTrue);
    expect(await registry.isCurrent(second), isTrue);
  });

  test('a new registry instance sees cancellation persisted by another engine',
      () async {
    final payload = await prepare();
    final backgroundRegistry = ReminderSnoozeRegistry(preferences: preferences);
    expect(await backgroundRegistry.isCurrent(payload), isTrue);

    await registry.invalidate(payload.reminderId);

    expect(await backgroundRegistry.isCurrent(payload), isFalse);
  });

  test('removal during native scheduling cancels the late snooze only',
      () async {
    final payload = await prepare();
    final started = Completer<void>();
    final finish = Completer<void>();
    snooze = ReminderSnooze(
      registry: registry,
      now: () => clock,
      schedule: (notification, date) async {
        scheduled.add((notification, date));
        started.complete();
        await finish.future;
        return true;
      },
      cancel: (id) async => cancelled.add(id),
    );

    final result = snooze.handleResponse(_action(payload));
    await started.future;
    await registry.invalidate(payload.reminderId);
    finish.complete();

    expect(await result, isFalse);
    expect(cancelled, [payload.snoozeId]);
    expect(await registry.isCurrent(payload), isFalse);
  });

  test('an in-flight old action cannot cancel the edited reminder snooze ID',
      () async {
    final old = await prepare();
    final started = Completer<void>();
    final finish = Completer<void>();
    snooze = ReminderSnooze(
      registry: registry,
      schedule: (_, __) async {
        started.complete();
        await finish.future;
        return true;
      },
      cancel: (id) async => cancelled.add(id),
    );

    final result = snooze.handleResponse(_action(old));
    await started.future;
    final edited = await prepare();
    finish.complete();

    expect(await result, isFalse);
    expect(cancelled, [old.snoozeId]);
    expect(cancelled, isNot(contains(edited.snoozeId)));
    expect(await registry.isCurrent(edited), isTrue);
  });

  test(
      'all-reminder cancellation invalidates old actions and keeps preferences',
      () async {
    preferences.values['app_theme'] = 'dark';
    final first = await prepare();
    final second = await prepare(reminderId: 43, noteId: 'packing');
    await registry.invalidateAll();

    expect(await snooze.handleResponse(_action(first)), isFalse);
    expect(await snooze.handleResponse(_action(second)), isFalse);
    expect(preferences.values['app_theme'], 'dark');
    final current = await prepare();
    expect(await snooze.handleResponse(_action(current)), isTrue);
    expect(current.snoozeId, isNot(first.snoozeId));
  });

  test('a failed notification schedule reports failure without canceling base',
      () async {
    final payload = await prepare();
    snooze = ReminderSnooze(
      registry: registry,
      schedule: (_, __) async => false,
      cancel: (id) async => cancelled.add(id),
    );

    expect(await snooze.handleResponse(_action(payload)), isFalse);
    expect(cancelled, isNot(contains(payload.reminderId)));
    expect(await registry.isCurrent(payload), isTrue);
  });

  test('rapid snooze actions schedule in order so the last choice wins',
      () async {
    final payload = await prepare();
    final started = Completer<void>();
    final finish = Completer<void>();
    snooze = ReminderSnooze(
      registry: registry,
      now: () => clock,
      schedule: (notification, date) async {
        scheduled.add((notification, date));
        if (scheduled.length == 1) {
          started.complete();
          await finish.future;
        }
        return true;
      },
      cancel: (_) async {},
    );
    final first = snooze.handleResponse(_action(payload));
    await started.future;
    final second =
        snooze.handleResponse(_action(payload, actionId: 'onlynote_snooze_1h'));
    await Future<void>.delayed(Duration.zero);
    expect(scheduled, hasLength(1));
    finish.complete();

    expect(await first, isTrue);
    expect(await second, isTrue);
    expect(scheduled, hasLength(2));
    expect(scheduled.last.$2, clock.add(const Duration(hours: 1)));
    expect(scheduled.first.$1.snoozeId, scheduled.last.$1.snoozeId);
  });

  test('structured payload preserves content and supports legacy note taps',
      () async {
    final payload = (await registry.prepare(
      noteId: 'shopping',
      reminderId: 42,
      title: 'Onlynote',
      body: 'Reminder: 今日購物 🛒',
    ))
        .payload;

    final decoded = ReminderNotificationPayload.tryDecode(payload.encode())!;
    expect(decoded.encode(), payload.encode());
    expect(
        ReminderNotificationPayload.noteIdFrom(payload.encode()), 'shopping');
    expect(
        ReminderNotificationPayload.noteIdFrom('legacy-note'), 'legacy-note');
    expect(ReminderNotificationPayload.noteIdFrom(null), isNull);
    expect(ReminderNotificationPayload.noteIdFrom('   '), isNull);
    expect(ReminderNotificationPayload.noteIdFrom('{broken payload'), isNull);
  });

  test('invalid payload versions, identities and ID ranges are ignored',
      () async {
    final payload = await prepare();
    final valid = jsonDecode(payload.encode()) as Map<String, dynamic>;
    for (final changed in [
      {'version': 2},
      {'kind': 'different-app'},
      {'noteId': ''},
      {'reminderId': -1},
      {'reminderId': 0x80000000},
      {'snoozeId': 0},
      {'snoozeId': -0x80000001},
      {'revision': ''},
      {'epoch': ''},
    ]) {
      expect(
          ReminderNotificationPayload.tryDecode(
              jsonEncode({...valid, ...changed})),
          isNull);
    }
  });
}
