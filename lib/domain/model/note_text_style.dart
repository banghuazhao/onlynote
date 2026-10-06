/// Formatting is stored separately from the plain note text. Offsets use the
/// same UTF-16 coordinates as Flutter's text selection APIs.
enum NoteTextStyleKind { bold, heading }

class NoteTextStyleRange {
  const NoteTextStyleRange({
    required this.start,
    required this.end,
    required this.kind,
  });

  final int start;
  final int end;
  final NoteTextStyleKind kind;

  Map<String, dynamic> toMap() => {
        'start': start,
        'end': end,
        'kind': kind.name,
      };

  static NoteTextStyleRange? tryFromMap(Object? value) {
    if (value is! Map) return null;
    final start = value['start'];
    final end = value['end'];
    final rawKind = value['kind'];
    if (start is! int || end is! int || start < 0 || end <= start) {
      return null;
    }
    final kind = switch (rawKind) {
      'bold' => NoteTextStyleKind.bold,
      'heading' => NoteTextStyleKind.heading,
      _ => null,
    };
    if (kind == null) return null;
    return NoteTextStyleRange(start: start, end: end, kind: kind);
  }

  @override
  bool operator ==(Object other) =>
      other is NoteTextStyleRange &&
      other.start == start &&
      other.end == end &&
      other.kind == kind;

  @override
  int get hashCode => Object.hash(start, end, kind);

  @override
  String toString() => 'NoteTextStyleRange($start, $end, ${kind.name})';
}
