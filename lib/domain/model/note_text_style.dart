/// Formatting is stored separately from the plain note text. Offsets use the
/// same UTF-16 coordinates as Flutter's text selection APIs.
enum NoteTextStyleKind { bold, heading, highlight, divider }

class NoteTextStyleRange {
  const NoteTextStyleRange({
    required this.start,
    required this.end,
    required this.kind,
    this.anchorId,
  });

  final int start;
  final int end;
  final NoteTextStyleKind kind;

  /// A persisted section identity, independent of heading text and offsets.
  final String? anchorId;

  Map<String, dynamic> toMap() => {
        'start': start,
        'end': end,
        'kind': kind.name,
        if (anchorId != null) 'anchorId': anchorId,
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
      'highlight' => NoteTextStyleKind.highlight,
      'divider' => NoteTextStyleKind.divider,
      _ => null,
    };
    if (kind == null) return null;
    final anchorId = value['anchorId'];
    if (anchorId != null &&
        (kind != NoteTextStyleKind.heading ||
            anchorId is! String ||
            anchorId.isEmpty ||
            anchorId.length > 128)) {
      return null;
    }
    return NoteTextStyleRange(
        start: start, end: end, kind: kind, anchorId: anchorId as String?);
  }

  @override
  bool operator ==(Object other) =>
      other is NoteTextStyleRange &&
      other.start == start &&
      other.end == end &&
      other.kind == kind &&
      other.anchorId == anchorId;

  @override
  int get hashCode => Object.hash(start, end, kind, anchorId);

  @override
  String toString() => 'NoteTextStyleRange($start, $end, ${kind.name})';
}
