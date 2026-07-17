import 'dart:ui' show Color;

const List<Color> colors = [
  // Original neutral/warm palette.
  Color(0xffE3CBB1),
  Color(0xffD5B9AC),
  Color(0xffC1CDDB),
  Color(0xffB0B1B4),
  Color(0xffE5E6E2),
  Color(0xffB9C3B8),
  Color(0xffE6D5D9),
  Color(0xffFBE9D8),
  Color(0xffD2D1CF),
  Color(0xffBFAFA7),
  Color(0xffDFDDB3),
  // Additional pastel hues for more variety.
  Color(0xffF6C6C6), // pink
  Color(0xffF7D9A0), // yellow
  Color(0xffB8E0D2), // mint
  Color(0xffA7C6E0), // blue
  Color(0xffCBB8E0), // lavender
  Color(0xffF3B6A0), // terracotta
  Color(0xffA8D8C9), // sage
  Color(0xffE0B8CE), // rose
  Color(0xffB9D6E0), // sky
  Color(0xffE3D5B8), // sand
];

const Duration animationDuration = Duration(milliseconds: 400);
const Duration apiCallInterval = Duration(seconds: 5);

//? add/update screen form fields
const int maxTitleCharCount = 140;
const int maxTitleLinesCount = 8;
const int todoMaxCharCount = 100;

const String databaseBox = 'note_database_box';
const String folderDatabaseBox = 'folder_database_box';
