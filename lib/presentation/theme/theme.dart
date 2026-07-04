import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:onlynote/presentation/theme/colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData light = ThemeData(
    scaffoldBackgroundColor: const Color(0xffFEF7EE),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.white,
      centerTitle: false,
      elevation: 0,
      titleTextStyle: GoogleFonts.montserrat(
        fontSize: 17,
        fontWeight: FontWeight.bold,
        color: AppColors.title,
      ),
      iconTheme: const IconThemeData(color: AppColors.title),
    ),
    colorScheme: ColorScheme.fromSwatch().copyWith(
      secondary: const Color(0xff333333),
      primary: const Color(0xff333333),
    ),
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: Color(0xff252525),
      selectionHandleColor: Color(0xff252525),
      selectionColor: Colors.black26,
    ),
    checkboxTheme: CheckboxThemeData(
      // Unchecked = an empty (transparent-fill, outlined) circle; checked =
      // filled. Using .all() here previously kept the fill color constant
      // regardless of state, so unchecked boxes looked identical to checked
      // ones (both a solid dark circle).
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const Color(0xff252525);
        }
        return Colors.transparent;
      }),
      side: const BorderSide(color: Color(0xff252525), width: 1.5),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(40)),
      ),
    ),
  );
}
