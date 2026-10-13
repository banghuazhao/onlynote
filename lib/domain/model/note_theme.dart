/// Stationery choices use stable names in appearance maps and preferences.
enum NoteTheme {
  classic(false),
  sticky(false),
  legalPad(false),
  ruledNotebook(false),
  gridPaper(false),
  dottedJournal(true),
  kraftNotebook(true),
  parchment(true);

  const NoteTheme(this.isPremium);

  final bool isPremium;
}
