import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Uses the device's named zone so repeating reminders keep their wall time
/// when daylight saving changes. Refresh before scheduling after travel too.
class NotificationTimezone {
  NotificationTimezone._();

  static bool _databaseInitialized = false;

  static Future<void> initialize() async {
    if (!_databaseInitialized) {
      tz.initializeTimeZones();
      _databaseInitialized = true;
    }
    final timezone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timezone.identifier));
  }
}
