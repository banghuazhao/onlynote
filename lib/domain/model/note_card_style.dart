/// The available note type scales, shared by defaults and individual cards.
enum AppFontSize {
  small(0.85),
  medium(1.0),
  large(1.2);

  const AppFontSize(this.scale);
  final double scale;
}

enum NoteCardSize {
  large(1),
  medium(2),
  small(3);

  const NoteCardSize(this.columns);
  final int columns;
}

enum NoteCardPaperStyle { textured, plain }

/// Optional appearance overrides. An absent field follows the current default.
class NoteCardStyle {
  const NoteCardStyle({
    this.fontFamily,
    this.fontSize,
    this.cardSize,
    this.paperStyle,
    this.showDate,
  });

  final String? fontFamily;
  final AppFontSize? fontSize;
  final NoteCardSize? cardSize;
  final NoteCardPaperStyle? paperStyle;
  final bool? showDate;

  bool get isDefault =>
      fontFamily == null &&
      fontSize == null &&
      cardSize == null &&
      paperStyle == null &&
      showDate == null;

  NoteCardStyle copyWith({
    String? fontFamily,
    AppFontSize? fontSize,
    NoteCardSize? cardSize,
    NoteCardPaperStyle? paperStyle,
    bool? showDate,
    bool clearFontFamily = false,
    bool clearFontSize = false,
    bool clearCardSize = false,
    bool clearPaperStyle = false,
    bool clearShowDate = false,
  }) =>
      NoteCardStyle(
        fontFamily: clearFontFamily ? null : fontFamily ?? this.fontFamily,
        fontSize: clearFontSize ? null : fontSize ?? this.fontSize,
        cardSize: clearCardSize ? null : cardSize ?? this.cardSize,
        paperStyle: clearPaperStyle ? null : paperStyle ?? this.paperStyle,
        showDate: clearShowDate ? null : showDate ?? this.showDate,
      );

  Map<String, dynamic> toMap() => {
        if (fontFamily != null) 'fontFamily': fontFamily,
        if (fontSize != null) 'fontSize': fontSize!.name,
        if (cardSize != null) 'cardSize': cardSize!.name,
        if (paperStyle != null) 'paperStyle': paperStyle!.name,
        if (showDate != null) 'showDate': showDate,
      };

  /// Unknown or malformed choices safely fall back to inherited defaults.
  factory NoteCardStyle.fromMap(Object? value) {
    if (value is! Map) return const NoteCardStyle();
    final family = value['fontFamily'];
    return NoteCardStyle(
      fontFamily:
          family is String && family.trim().isNotEmpty && family.length <= 100
              ? family
              : null,
      fontSize: AppFontSize.values
          .where((size) => size.name == value['fontSize'])
          .firstOrNull,
      cardSize: NoteCardSize.values
          .where((size) => size.name == value['cardSize'])
          .firstOrNull,
      paperStyle: NoteCardPaperStyle.values
          .where((style) => style.name == value['paperStyle'])
          .firstOrNull,
      showDate: value['showDate'] is bool ? value['showDate'] as bool : null,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is NoteCardStyle &&
      other.fontFamily == fontFamily &&
      other.fontSize == fontSize &&
      other.cardSize == cardSize &&
      other.paperStyle == paperStyle &&
      other.showDate == showDate;

  @override
  int get hashCode =>
      Object.hash(fontFamily, fontSize, cardSize, paperStyle, showDate);

  @override
  String toString() =>
      'NoteCardStyle($fontFamily, $fontSize, $cardSize, $paperStyle, $showDate)';
}
