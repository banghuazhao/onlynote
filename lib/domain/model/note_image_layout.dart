/// An image's position among the note's paragraphs. Text offsets use UTF-16,
/// matching Flutter text selection and the note's separately saved formatting.
class NoteImageLayout {
  const NoteImageLayout({
    required this.path,
    required this.textOffset,
    this.widthFactor = .85,
    this.xFactor = .5,
    this.aspectRatio = 4 / 3,
    this.isDocumentPage = false,
  });

  final String path;
  final int textOffset;

  /// A fraction of the available paragraph width.
  final double widthFactor;

  /// Alignment within the space left after sizing: 0 is left, 1 is right.
  final double xFactor;
  final double aspectRatio;
  final bool isDocumentPage;

  NoteImageLayout copyWith({
    String? path,
    int? textOffset,
    double? widthFactor,
    double? xFactor,
    double? aspectRatio,
    bool? isDocumentPage,
  }) =>
      NoteImageLayout(
        path: path ?? this.path,
        textOffset: textOffset ?? this.textOffset,
        widthFactor: widthFactor ?? this.widthFactor,
        xFactor: xFactor ?? this.xFactor,
        aspectRatio: aspectRatio ?? this.aspectRatio,
        isDocumentPage: isDocumentPage ?? this.isDocumentPage,
      );

  Map<String, dynamic> toMap() => {
        'path': path,
        'textOffset': textOffset,
        'widthFactor': widthFactor,
        'xFactor': xFactor,
        'aspectRatio': aspectRatio,
        if (isDocumentPage) 'isDocumentPage': true,
      };

  static NoteImageLayout? tryFromMap(Object? value) {
    if (value is! Map) return null;
    final path = value['path'];
    final textOffset = value['textOffset'];
    final widthFactor = value['widthFactor'] ?? .85;
    final xFactor = value['xFactor'] ?? .5;
    final aspectRatio = value['aspectRatio'] ?? 4 / 3;
    final isDocumentPage = value['isDocumentPage'] ?? false;
    if (path is! String ||
        path.trim().isEmpty ||
        textOffset is! int ||
        textOffset < 0 ||
        widthFactor is! num ||
        xFactor is! num ||
        aspectRatio is! num ||
        isDocumentPage is! bool ||
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
      isDocumentPage: isDocumentPage,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is NoteImageLayout &&
      other.path == path &&
      other.textOffset == textOffset &&
      other.widthFactor == widthFactor &&
      other.xFactor == xFactor &&
      other.aspectRatio == aspectRatio &&
      other.isDocumentPage == isDocumentPage;

  @override
  int get hashCode => Object.hash(
      path, textOffset, widthFactor, xFactor, aspectRatio, isDocumentPage);

  @override
  String toString() =>
      'NoteImageLayout($path, $textOffset, $widthFactor, $xFactor, $aspectRatio)';
}
