import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Neo-Brutalist Minimalism Palette
  static const Color pitchBlack = Color(0xFF0A0A0A);
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color violentRed = Color(0xFFFF0033);
  static const Color neutralGrey = Color(0xFF737373);
  static const Color cardSurface = Color(0xFFFFFFFF);
  static const Color darkSurface = Color(0xFF141414);

  // Borders & Outlines
  static const double borderWidth = 2.0;
  static const BorderSide blackBorder = BorderSide(
    color: pitchBlack,
    width: borderWidth,
  );
  static const BorderSide whiteBorder = BorderSide(
    color: pureWhite,
    width: borderWidth,
  );
  static const BorderSide redBorder = BorderSide(
    color: violentRed,
    width: borderWidth,
  );

  // Neo-Brutalist Container Decoration (White card with crisp 2px border and hard shadow)
  static BoxDecoration neoCardDecoration({
    Color backgroundColor = pureWhite,
    Color borderColor = pitchBlack,
    double shadowOffset = 4.0,
    Color shadowColor = pitchBlack,
  }) {
    return BoxDecoration(
      color: backgroundColor,
      border: Border.all(color: borderColor, width: borderWidth),
      boxShadow: shadowOffset > 0
          ? [
              BoxShadow(
                color: shadowColor,
                offset: Offset(shadowOffset, shadowOffset),
                blurRadius: 0,
              ),
            ]
          : null,
    );
  }

  // Neo-Brutalist Active/Urgent Badge Decoration
  static BoxDecoration urgentBadgeDecoration() {
    return BoxDecoration(
      color: violentRed,
      border: Border.all(color: pitchBlack, width: borderWidth),
    );
  }

  // Typography Getters
  static TextStyle heading({
    double fontSize = 20,
    FontWeight fontWeight = FontWeight.w800,
    Color color = pureWhite,
  }) {
    return GoogleFonts.spaceGrotesk(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
    );
  }

  static TextStyle body({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w400,
    Color color = pitchBlack,
  }) {
    return GoogleFonts.inter(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
    );
  }

  static TextStyle mono({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w700,
    Color color = pitchBlack,
  }) {
    return GoogleFonts.jetBrainsMono(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
    );
  }

  // Global Neo-Brutalist ThemeData
  static ThemeData get themeData {
    final textTheme = TextTheme(
      displayLarge: GoogleFonts.spaceGrotesk(
        fontSize: 32,
        fontWeight: FontWeight.w800,
        color: pureWhite,
      ),
      displayMedium: GoogleFonts.spaceGrotesk(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        color: pureWhite,
      ),
      displaySmall: GoogleFonts.spaceGrotesk(
        fontSize: 24,
        fontWeight: FontWeight.w800,
        color: pureWhite,
      ),
      headlineMedium: GoogleFonts.spaceGrotesk(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: pureWhite,
      ),
      headlineSmall: GoogleFonts.spaceGrotesk(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: pureWhite,
      ),
      titleLarge: GoogleFonts.spaceGrotesk(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: pureWhite,
      ),
      titleMedium: GoogleFonts.spaceGrotesk(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: pureWhite,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: pureWhite,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: pureWhite,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: const Color(0xCCFFFFFF),
      ),
      labelLarge: GoogleFonts.jetBrainsMono(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
        color: pureWhite,
      ),
      labelMedium: GoogleFonts.jetBrainsMono(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: pureWhite,
      ),
      labelSmall: GoogleFonts.jetBrainsMono(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        color: neutralGrey,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: pitchBlack,
      canvasColor: pitchBlack,
      colorScheme: const ColorScheme(
        brightness: Brightness.dark,
        primary: violentRed,
        onPrimary: pureWhite,
        secondary: pureWhite,
        onSecondary: pitchBlack,
        error: violentRed,
        onError: pureWhite,
        surface: pitchBlack,
        onSurface: pureWhite,
      ),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: pitchBlack,
        foregroundColor: pureWhite,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.spaceGrotesk(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: pureWhite,
          letterSpacing: -0.5,
        ),
        shape: const Border(
          bottom: BorderSide(color: pureWhite, width: borderWidth),
        ),
        iconTheme: const IconThemeData(color: pureWhite),
      ),
      cardTheme: const CardThemeData(
        color: pureWhite,
        elevation: 0,
        margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 0.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: BorderSide(color: pitchBlack, width: borderWidth),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: violentRed,
          foregroundColor: pureWhite,
          elevation: 0,
          shadowColor: Colors.transparent,
          textStyle: GoogleFonts.spaceGrotesk(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
            side: BorderSide(color: pitchBlack, width: borderWidth),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: pureWhite,
          elevation: 0,
          textStyle: GoogleFonts.spaceGrotesk(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          side: const BorderSide(color: pureWhite, width: borderWidth),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: violentRed,
          textStyle: GoogleFonts.spaceGrotesk(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: pureWhite,
        labelStyle: GoogleFonts.inter(
          color: pitchBlack,
          fontWeight: FontWeight.w600,
        ),
        hintStyle: GoogleFonts.inter(
          color: neutralGrey,
          fontWeight: FontWeight.w400,
        ),
        prefixIconColor: pitchBlack,
        suffixIconColor: pitchBlack,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: pitchBlack, width: borderWidth),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: violentRed, width: 2.5),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: violentRed, width: borderWidth),
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: violentRed, width: 2.5),
        ),
        errorStyle: GoogleFonts.inter(
          color: violentRed,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: pitchBlack,
        thickness: borderWidth,
        space: borderWidth,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: pitchBlack,
        contentTextStyle: GoogleFonts.inter(
          color: pureWhite,
          fontWeight: FontWeight.w600,
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: BorderSide(color: violentRed, width: borderWidth),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

