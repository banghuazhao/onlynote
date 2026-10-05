import 'dart:convert';

/// Everything a native snooze action needs without opening the notes database.
class ReminderNotificationPayload {
  const ReminderNotificationPayload({
    required this.noteId,
    required this.reminderId,
    required this.snoozeId,
    required this.revision,
    required this.epoch,
    required this.title,
    required this.body,
  });

  final String noteId;
  final int reminderId;
  final int snoozeId;
  final String revision;
  final String epoch;
  final String title;
  final String body;

  String encode() => jsonEncode({
        'kind': 'onlynote-reminder',
        'version': 1,
        'noteId': noteId,
        'reminderId': reminderId,
        'snoozeId': snoozeId,
        'revision': revision,
        'epoch': epoch,
        'title': title,
        'body': body,
      });

  static ReminderNotificationPayload? tryDecode(String? encoded) {
    if (encoded == null) return null;
    try {
      final value = jsonDecode(encoded);
      if (value is! Map<String, dynamic> ||
          value['kind'] != 'onlynote-reminder' ||
          value['version'] != 1) {
        return null;
      }
      final noteId = value['noteId'];
      final reminderId = value['reminderId'];
      final snoozeId = value['snoozeId'];
      final revision = value['revision'];
      final epoch = value['epoch'];
      final title = value['title'];
      final body = value['body'];
      if (noteId is! String ||
          noteId.isEmpty ||
          reminderId is! int ||
          reminderId < 0 ||
          reminderId > 0x7fffffff ||
          snoozeId is! int ||
          snoozeId >= 0 ||
          snoozeId < -0x80000000 ||
          revision is! String ||
          revision.isEmpty ||
          epoch is! String ||
          epoch.isEmpty ||
          title is! String ||
          body is! String) {
        return null;
      }
      return ReminderNotificationPayload(
        noteId: noteId,
        reminderId: reminderId,
        snoozeId: snoozeId,
        revision: revision,
        epoch: epoch,
        title: title,
        body: body,
      );
    } on FormatException {
      return null;
    }
  }

  /// Older releases sent just the note ID. Malformed new payloads are ignored.
  static String? noteIdFrom(String? encoded) {
    final structured = tryDecode(encoded);
    if (structured != null) return structured.noteId;
    final legacy = encoded?.trim();
    if (legacy == null || legacy.isEmpty || legacy.startsWith('{')) return null;
    return legacy;
  }
}
