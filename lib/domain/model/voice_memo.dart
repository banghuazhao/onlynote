import 'package:flutter/foundation.dart';

/// A recording owned by a note or reusable template. Paths remain relative so
/// recordings survive an iOS container move and portable backup restore.
@immutable
class VoiceMemo {
  const VoiceMemo({
    required this.id,
    required this.path,
    required this.durationMs,
    required this.createdAt,
    this.transcript,
  });

  final String id;
  final String path;
  final int durationMs;
  final DateTime createdAt;
  final String? transcript;

  static bool isManagedPath(String path) =>
      RegExp(r'^(note_audio|template_audio)/[A-Za-z0-9-]{1,128}\.m4a$')
          .hasMatch(path);

  static VoiceMemo? tryFromMap(Object? value) {
    if (value is! Map) return null;
    final id = value['id'];
    final path = value['path'];
    final duration = value['durationMs'];
    final createdAt = value['createdAt'];
    final transcript = value['transcript'];
    if (id is! String ||
        id.isEmpty ||
        id.length > 256 ||
        path is! String ||
        !isManagedPath(path) ||
        duration is! int ||
        duration < 0 ||
        createdAt is! String ||
        (transcript != null && transcript is! String)) {
      return null;
    }
    final date = DateTime.tryParse(createdAt);
    if (date == null) return null;
    return VoiceMemo(
        id: id,
        path: path,
        durationMs: duration,
        createdAt: date,
        transcript: transcript as String?);
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'path': path,
        'durationMs': durationMs,
        'createdAt': createdAt.toIso8601String(),
        if (transcript != null) 'transcript': transcript,
      };

  VoiceMemo copyWith(
          {String? id,
          String? path,
          int? durationMs,
          DateTime? createdAt,
          String? transcript,
          bool clearTranscript = false}) =>
      VoiceMemo(
          id: id ?? this.id,
          path: path ?? this.path,
          durationMs: durationMs ?? this.durationMs,
          createdAt: createdAt ?? this.createdAt,
          transcript: clearTranscript ? null : transcript ?? this.transcript);

  @override
  bool operator ==(Object other) =>
      other is VoiceMemo &&
      other.id == id &&
      other.path == path &&
      other.durationMs == durationMs &&
      other.createdAt == createdAt &&
      other.transcript == transcript;

  @override
  int get hashCode => Object.hash(id, path, durationMs, createdAt, transcript);
}
