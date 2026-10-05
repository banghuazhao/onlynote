import 'dart:async';

import 'package:flutter/foundation.dart';
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
  String _dueKey(ReminderNotificationPayload payload) =>
      'onlynote_reminder_snooze_due_${payload.revision}';

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

  /// Older action registrations have no due entry until snoozed again.
  /// A separate revision key prevents a background write from reviving an
  /// edited or removed reminder's action registration.
  Future<DateTime?> readPendingDue(ReminderNotificationPayload payload,
      {DateTime? now}) async {
    if (!await isCurrent(payload)) return null;
    final encoded = await _preferences.getString(_dueKey(payload));
    final due = encoded == null ? null : DateTime.tryParse(encoded);
    if (due == null || !due.isAfter(now ?? DateTime.now())) return null;
    return await isCurrent(payload) ? due.toUtc() : null;
  }

  Future<bool> savePendingDue(
      ReminderNotificationPayload payload, DateTime due) async {
    if (!await isCurrent(payload)) return false;
    await _preferences.setString(
        _dueKey(payload), due.toUtc().toIso8601String());
    if (await isCurrent(payload)) return true;
    await clearPendingDue(payload);
    return false;
  }

  Future<void> clearPendingDue(ReminderNotificationPayload payload) =>
      _preferences.remove(_dueKey(payload));

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

  Future<bool> snooze(ReminderNotificationPayload payload,
      {required Duration delay}) {
    final result = _queue.then((_) => _snooze(payload, delay));
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
    return _snooze(payload, delay);
  }

  Future<bool> _snooze(
      ReminderNotificationPayload payload, Duration delay) async {
    if (delay <= Duration.zero || !await registry.isCurrent(payload)) {
      return false;
    }
    final instant = now().toUtc();
    final previousDue = await registry.readPendingDue(payload, now: instant);
    // Add elapsed time in UTC even during a daylight-saving clock change.
    final due = instant.add(delay);
    if (!await schedule(payload, due)) return false;
    if (!await registry.isCurrent(payload)) {
      await cancel(payload.snoozeId);
      return false;
    }
    try {
      if (!await registry.savePendingDue(payload, due)) {
        await cancel(payload.snoozeId);
        return false;
      }
    } catch (error) {
      // A failed metadata write must not leave an invisible new snooze. The
      // previous snooze shares this ID, so restore its native due time too.
      try {
        await cancel(payload.snoozeId);
        if (await registry.isCurrent(payload)) {
          if (previousDue != null && previousDue.isAfter(now())) {
            await schedule(payload, previousDue);
          }
          if (previousDue == null) {
            await registry.clearPendingDue(payload);
          } else {
            await registry.savePendingDue(payload, previousDue);
          }
        }
      } catch (rollbackError) {
        debugPrint('Could not restore previous snooze: $rollbackError');
      }
      debugPrint('Could not save snooze due time: $error');
      return false;
    }
    return true;
  }
}
