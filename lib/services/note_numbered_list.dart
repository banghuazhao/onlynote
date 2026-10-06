/// Numbered list markers remain ordinary document text. Restrict the shape to
/// a paragraph-start positive integer, a period and a space so decimals,
/// leading zeroes and numbers inside sentences stay literal.
NoteNumberedListMarker? noteNumberedListMarker(String paragraph) {
  final match = _numberedMarker.firstMatch(paragraph);
  if (match == null) return null;
  final number = int.parse(match.group(1)!);
  return NoteNumberedListMarker(number: number, prefix: match.group(0)!);
}

final _numberedMarker = RegExp(r'^([1-9][0-9]{0,8})\. ');

class NoteNumberedListMarker {
  const NoteNumberedListMarker({required this.number, required this.prefix});

  final int number;
  final String prefix;

  String get nextPrefix => '${number + 1}. ';
}

/// Automatic Return inserts a whole list marker in one native edit. Formatting
/// should treat that edit as a paragraph break, just like a plain Return.
bool isNoteParagraphBreak(String inserted) {
  if (inserted == '\n' || inserted == '\n• ') return true;
  if (!inserted.startsWith('\n')) return false;
  final marker = noteNumberedListMarker(inserted.substring(1));
  return marker != null && inserted.length == marker.prefix.length + 1;
}
