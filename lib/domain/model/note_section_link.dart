/// A relationship to a saved heading. The title is a label for unavailable
/// targets; navigation always resolves the stable heading identity.
class NoteSectionLink {
  const NoteSectionLink({
    required this.noteId,
    required this.headingId,
    required this.headingText,
  });

  final String noteId;
  final String headingId;
  final String headingText;

  Map<String, dynamic> toMap() => {
        'noteId': noteId,
        'headingId': headingId,
        'headingText': headingText,
      };

  NoteSectionLink copyWith({String? noteId}) => NoteSectionLink(
        noteId: noteId ?? this.noteId,
        headingId: headingId,
        headingText: headingText,
      );

  static NoteSectionLink? tryFromMap(Object? value) {
    if (value is! Map) return null;
    final noteId = value['noteId'];
    final headingId = value['headingId'];
    final headingText = value['headingText'];
    if (noteId is! String ||
        noteId.trim().isEmpty ||
        noteId.length > 512 ||
        headingId is! String ||
        headingId.trim().isEmpty ||
        headingId.length > 128 ||
        headingText is! String ||
        headingText.trim().isEmpty ||
        headingText.length > 1024) {
      return null;
    }
    return NoteSectionLink(
        noteId: noteId, headingId: headingId, headingText: headingText);
  }

  @override
  bool operator ==(Object other) =>
      other is NoteSectionLink &&
      other.noteId == noteId &&
      other.headingId == headingId &&
      other.headingText == headingText;

  @override
  int get hashCode => Object.hash(noteId, headingId, headingText);
}
