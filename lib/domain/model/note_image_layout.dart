/// An image's position among the note's paragraphs. Text offsets use UTF-16,
/// matching Flutter text selection and the note's separately saved formatting.
class NoteImageLayout {
  const NoteImageLayout({
    required this.path,
    required this.textOffset,
    this.widthFactor = .85,
    this.xFactor = .5,
    this.aspectRatio = 4 / 3,
  });

  final String path;
  final int textOffset;

  /// A fraction of the available paragraph width.
  final double widthFactor;

  /// Alignment within the space left after sizing: 0 is left, 1 is right.
  final double xFactor;
  final double aspectRatio;

  NoteImageLayout copyWith({
    String? path,
    int? textOffset,
    double? widthFactor,
    double? xFactor,
    double? aspectRatio,
  }) =>
      NoteImageLayout(
        path: path ?? this.path,
        textOffset: textOffset ?? this.textOffset,
        widthFactor: widthFactor ?? this.widthFactor,
        xFactor: xFactor ?? this.xFactor,
        aspectRatio: aspectRatio ?? this.aspectRatio,
      );

  Map<String, dynamic> toMap() => {
        'path': path,
        'textOffset': textOffset,
        'widthFactor': widthFactor,
        'xFactor': xFactor,
        'aspectRatio': aspectRatio,
      };

  static NoteImageLayout? tryFromMap(Object? value) {
    if (value is! Map) return null;
    final path = value['path'];
    final textOffset = value['textOffset'];
    final widthFactor = value['widthFactor'] ?? .85;
    final xFactor = value['xFactor'] ?? .5;
    final aspectRatio = value['aspectRatio'] ?? 4 / 3;
    if (path is! String ||
        path.trim().isEmpty ||
        textOffset is! int ||
        textOffset < 0 ||
        widthFactor is! num ||
        xFactor is! num ||
        aspectRatio is! num ||
        !widthFactor.isFinite ||
        !xFactor.isFinite ||
        !aspectRatio.isFinite) {
      return null;
    }
    return NoteImageLayout(
      path: path,
      textOffset: textOffset,
      widthFactor: widthFactor.toDouble(),
      xFactor: xFactor.toDouble(),
      aspectRatio: aspectRatio.toDouble(),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is NoteImageLayout &&
      other.path == path &&
      other.textOffset == textOffset &&
      other.widthFactor == widthFactor &&
      other.xFactor == xFactor &&
      other.aspectRatio == aspectRatio;

  @override
  int get hashCode =>
      Object.hash(path, textOffset, widthFactor, xFactor, aspectRatio);

  @override
  String toString() =>
      'NoteImageLayout($path, $textOffset, $widthFactor, $xFactor, $aspectRatio)';
}
