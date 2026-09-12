import 'dart:ui' show Color;

const List<Color> colors = [
  // Stationery and sticky-note papers. Existing notes keep whatever Color
  // was stored; this list only affects new notes and the editor swatches.
  Color(0xFFFFF4C2), // sticky yellow
  Color(0xFFFFF6D8), // legal pad
  Color(0xFFFFE4C4), // manila
  Color(0xFFF8D5C0), // kraft blush
  Color(0xFFF7C9C9), // pink sticky
  Color(0xFFF3D1E0), // rose
  Color(0xFFE4D4F0), // lilac
  Color(0xFFD4E3F5), // index card blue
  Color(0xFFD3EDE4), // mint
  Color(0xFFE2EDD4), // sage
  Color(0xFFF0E6D2), // parchment
  Color(0xFFE8E4D9), // cotton
  Color(0xFFE6D5C3), // kraft
  Color(0xFFD9D3C9), // stone
  Color(0xFFC9D6C8), // olive paper
  Color(0xFFF7C8A8), // coral
  Color(0xFFBFD7EA), // sky
  Color(0xFFE8C4B8), // terracotta paper
  Color(0xFFD5C6B0), // cardboard
  Color(0xFFF3E5AB), // butter
  Color(0xFFE5E6E2), // cold white
];

const Duration animationDuration = Duration(milliseconds: 400);
const Duration apiCallInterval = Duration(seconds: 5);

//? add/update screen form fields
const int maxTitleCharCount = 140;
const int maxTitleLinesCount = 8;
const int todoMaxCharCount = 100;

const String databaseBox = 'note_database_box';
const String folderDatabaseBox = 'folder_database_box';

/// Reachable from Settings > Privacy. Both stores also point at this URL, so
/// the in-app link and the listing stay one document.
const String kPrivacyPolicyUrl =
    'https://apps-bay.github.io/Apps-Bay-Website/privacy/';
