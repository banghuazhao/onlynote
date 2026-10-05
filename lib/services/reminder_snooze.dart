import 'dart:async';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:onlynote/Tools/reminder_notification_payload.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class ReminderSnoozeRegistration {
  const ReminderSnoozeRegistration(this.payload, this.previous);
  final ReminderNotificationPayload payload;
  final ReminderNotificationPayload? previous;
}

/// Uncached preferences are shared by the foreground and native action engine.
/// Each scheduling revision owns a different negative notification ID, so an
/// old in-flight action cannot cancel a newer reminder's snooze.
class ReminderSnoozeRegistry {
  ReminderSnoozeRegistry({SharedPreferencesAsync? preferences})
      : _preferences = preferences ?? SharedPreferencesAsync();

  final SharedPreferencesAsync _preferences;
  static const _epochKey = 'onlynote_reminder_epoch';
  static const _counterKey = 'onlynote_snooze_next_id';
  String _key(int id) => 'onlynote_reminder_notification_$id';

  Future<ReminderNotificationPayload?> read(int reminderId) async =>
      ReminderNotificationPayload.tryDecode(
          await _preferences.getString(_key(reminderId)));

  Future<bool> hasRegistration(int reminderId) async =>
      await _preferences.getString(_key(reminderId)) != null;

  /// Called only by serialized foreground scheduling operations.
  Future<ReminderSnoozeRegistration> prepare({
    required String noteId,
    required int reminderId,
    required String title,
    required String body,
  }) async {
    if (reminderId < 0 || reminderId > 0x7fffffff || noteId.isEmpty) {
      throw ArgumentError('Invalid reminder identity');
    }
    final previous = await read(reminderId);
    var epoch = await _preferences.getString(_epochKey);
    if (epoch == null) {
      epoch = const Uuid().v4();
      await _preferences.setString(_epochKey, epoch);
    }
    final next = (await _preferences.getInt(_counterKey) ?? 0) + 1;
    if (next > 0x80000000) throw StateError('Snooze IDs exhausted');
    await _preferences.setInt(_counterKey, next);
    final payload = ReminderNotificationPayload(
      noteId: noteId,
      reminderId: reminderId,
      snoozeId: -next,
      revision: const Uuid().v4(),
      epoch: epoch,
      title: title,
      body: body,
    );
    await _preferences.setString(_key(reminderId), payload.encode());
    return ReminderSnoozeRegistration(payload, previous);
  }

  Future<bool> isCurrent(ReminderNotificationPayload payload) async {
    if (await _preferences.getString(_epochKey) != payload.epoch) return false;
    final current = await read(payload.reminderId);
    return current?.encode() == payload.encode();
  }

  Future<ReminderNotificationPayload?> invalidate(int reminderId) async {
    final previous = await read(reminderId);
    await _preferences.setString(_key(reminderId), '');
    return previous;
  }

  Future<void> invalidateAll() =>
      _preferences.setString(_epochKey, const Uuid().v4());

  Future<void> restore(ReminderNotificationPayload? previous,
      {required ReminderNotificationPayload replacing}) async {
    if (!await isCurrent(replacing)) return;
    if (previous == null) {
      await _preferences.remove(_key(replacing.reminderId));
    } else {
      await _preferences.setString(
          _key(replacing.reminderId), previous.encode());
    }
  }
}

class ReminderSnooze {
  ReminderSnooze({
    required this.registry,
    required this.schedule,
    required this.cancel,
    DateTime Function()? now,
  }) : now = now ?? DateTime.now;

  static const tenMinutes = 'onlynote_snooze_10m';
  static const oneHour = 'onlynote_snooze_1h';
  final ReminderSnoozeRegistry registry;
  final Future<bool> Function(ReminderNotificationPayload, DateTime) schedule;
  final Future<void> Function(int) cancel;
  final DateTime Function() now;
  Future<void> _queue = Future.value();

  static bool isSnoozeAction(String? actionId) =>
      actionId == tenMinutes || actionId == oneHour;

  Future<bool> handleResponse(NotificationResponse response) {
    final result = _queue.then((_) => _handle(response));
    _queue = result.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return result;
  }

  Future<bool> _handle(NotificationResponse response) async {
    if (response.notificationResponseType !=
            NotificationResponseType.selectedNotificationAction ||
        !isSnoozeAction(response.actionId)) {
      return false;
    }
    final payload = ReminderNotificationPayload.tryDecode(response.payload);
    if (payload == null ||
        (response.id != payload.reminderId &&
            response.id != payload.snoozeId) ||
        !await registry.isCurrent(payload)) {
      return false;
    }
    final delay = response.actionId == tenMinutes
        ? const Duration(minutes: 10)
        : const Duration(hours: 1);
    // Add elapsed time in UTC even during a daylight-saving clock change.
    final due = now().toUtc().add(delay);
    if (!await schedule(payload, due)) return false;
    if (!await registry.isCurrent(payload)) {
      await cancel(payload.snoozeId);
      return false;
    }
    return true;
  }
}
