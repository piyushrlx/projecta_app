import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Enterprise Navy & Slate Color Palette
  static const Color scaffoldBg = Color(0xFFF8FAFC);
  static const Color cardSurface = Color(0xFFFFFFFF);
  static const Color pureWhite = Color(0xFFFFFFFF);

  // Brand & Accent Colors
  static const Color navyBlue = Color(0xFF1E3A8A); // Executive Navy Blue
  static const Color royalBlue = Color(
    0xFF2563EB,
  ); // Interactive Accent Royal Blue
  static const Color borderSubtle = Color(0xFFE2E8F0); // Subtle 1px Border
  static const Color dividerColor = Color(0xFFE2E8F0);

  // Text Hierarchy
  static const Color deepSlate = Color(0xFF0F172A); // Headings / Titles
  static const Color mutedSlate = Color(0xFF475569); // Labels / Subtitles
  static const Color lightSlate = Color(0xFF94A3B8); // Hints / Placeholders

  // Semantic Status Badges & Alerts
  static const Color successBg = Color(0xFFDCFCE7);
  static const Color successText = Color(0xFF15803D);

  static const Color infoBg = Color(0xFFDBEAFE);
  static const Color infoText = Color(0xFF1D4ED8);

  static const Color warningBg = Color(0xFFFEF3C7);
  static const Color warningText = Color(0xFFB45309);

  static const Color dangerBg = Color(0xFFFEE2E2);
  static const Color dangerText = Color(0xFFB91C1C);

  // Backward compatibility aliases mapped to new palette
  static const Color pitchBlack = deepSlate;
  static const Color violentRed = dangerText;
  static const Color neutralGrey = mutedSlate;
  static const Color mutedGrey = lightSlate;
  static const Color offWhite = scaffoldBg;
  static const Color darkSurface = deepSlate;

  // Borders & Outlines
  static const double borderWidth = 1.0;
  static const BorderSide subtleBorder = BorderSide(
    color: borderSubtle,
    width: 1.0,
  );
  static const BorderSide blackBorder = subtleBorder;
  static const BorderSide whiteBorder = BorderSide(
    color: pureWhite,
    width: 1.0,
  );
  static const BorderSide redBorder = BorderSide(color: dangerText, width: 1.0);

  // Soft diffused elevation shadow
  static const BoxShadow softShadow = BoxShadow(
    color: Color(0x0A0F172A),
    blurRadius: 12,
    offset: Offset(0, 4),
  );

  // Enterprise Card Decoration (Pure White, 12px rounded corners, 1px #E2E8F0 border, soft shadow)
  static BoxDecoration cardDecoration({
    Color backgroundColor = pureWhite,
    Color borderColor = borderSubtle,
    double borderRadius = 12.0,
    bool hasShadow = true,
  }) {
    return BoxDecoration(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(color: borderColor, width: 1.0),
      boxShadow: hasShadow ? [softShadow] : null,
    );
  }

  // Alias for backward compatibility with existing screen references
  static BoxDecoration neoCardDecoration({
    Color backgroundColor = pureWhite,
    Color borderColor = borderSubtle,
    double shadowOffset = 4.0,
    Color shadowColor = const Color(0x0A0F172A),
    double borderRadius = 12.0,
  }) {
    return BoxDecoration(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(color: borderColor, width: 1.0),
      boxShadow: shadowOffset > 0 ? const [softShadow] : null,
    );
  }

  // Semantic Status Badge Decoration (Soft pastel pill, 6px corners)
  static BoxDecoration statusBadgeDecoration({
    required Color backgroundColor,
    double borderRadius = 6.0,
    Border? border,
  }) {
    return BoxDecoration(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(borderRadius),
      border: border,
    );
  }

  // Urgent Badge Decoration (Pastel Danger pill)
  static BoxDecoration urgentBadgeDecoration({
    Color color = dangerBg,
    double borderRadius = 6.0,
  }) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(borderRadius),
    );
  }

  // Typography Getters
  // Headings & Titles: Plus Jakarta Sans (600 / 700)
  static TextStyle heading({
    double fontSize = 20,
    FontWeight fontWeight = FontWeight.w700,
    Color color = deepSlate,
    double? letterSpacing,
    double? height,
  }) {
    return GoogleFonts.plusJakartaSans(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing ?? -0.3,
      height: height,
    );
  }

  // Body & Descriptions: Inter (400 / 500)
  static TextStyle body({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w400,
    Color color = deepSlate,
    double? letterSpacing,
    double? height,
  }) {
    return GoogleFonts.inter(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
    );
  }

  // Entity / Task / Project Codes: JetBrains Mono
  static TextStyle mono({
    double fontSize = 13,
    FontWeight fontWeight = FontWeight.w600,
    Color color = deepSlate,
  }) {
    return GoogleFonts.jetBrainsMono(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
    );
  }

  // Global Enterprise ThemeData
  static ThemeData get themeData {
    final textTheme = TextTheme(
      displayLarge: GoogleFonts.plusJakartaSans(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: deepSlate,
        letterSpacing: -0.8,
      ),
      displayMedium: GoogleFonts.plusJakartaSans(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        color: deepSlate,
        letterSpacing: -0.5,
      ),
      displaySmall: GoogleFonts.plusJakartaSans(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: deepSlate,
        letterSpacing: -0.3,
      ),
      headlineMedium: GoogleFonts.plusJakartaSans(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: deepSlate,
        letterSpacing: -0.3,
      ),
      headlineSmall: GoogleFonts.plusJakartaSans(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: deepSlate,
      ),
      titleLarge: GoogleFonts.plusJakartaSans(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: deepSlate,
      ),
      titleMedium: GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: deepSlate,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: deepSlate,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: deepSlate,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: mutedSlate,
      ),
      labelLarge: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: deepSlate,
      ),
      labelMedium: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: mutedSlate,
      ),
      labelSmall: GoogleFonts.jetBrainsMono(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: mutedSlate,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: scaffoldBg,
      canvasColor: pureWhite,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: navyBlue,
        onPrimary: pureWhite,
        secondary: royalBlue,
        onSecondary: pureWhite,
        error: dangerText,
        onError: pureWhite,
        surface: cardSurface,
        onSurface: deepSlate,
      ),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: pureWhite,
        foregroundColor: deepSlate,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        toolbarHeight: 64,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: deepSlate,
        ),
        shape: const Border(
          bottom: BorderSide(color: borderSubtle, width: 1.0),
        ),
        iconTheme: const IconThemeData(color: deepSlate),
      ),
      cardTheme: CardThemeData(
        color: pureWhite,
        elevation: 0,
        margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 0.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: borderSubtle, width: 1.0),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: navyBlue,
          foregroundColor: pureWhite,
          elevation: 0,
          shadowColor: Colors.transparent,
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: deepSlate,
          backgroundColor: pureWhite,
          elevation: 0,
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          side: const BorderSide(color: borderSubtle, width: 1.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: royalBlue,
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scaffoldBg,
        labelStyle: GoogleFonts.inter(
          color: mutedSlate,
          fontWeight: FontWeight.w500,
        ),
        hintStyle: GoogleFonts.inter(
          color: lightSlate,
          fontWeight: FontWeight.w400,
        ),
        prefixIconColor: mutedSlate,
        suffixIconColor: mutedSlate,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: borderSubtle, width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: royalBlue, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: dangerText, width: 1.0),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: dangerText, width: 1.5),
        ),
        errorStyle: GoogleFonts.inter(
          color: dangerText,
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: borderSubtle,
        thickness: 1.0,
        space: 1.0,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: deepSlate,
        contentTextStyle: GoogleFonts.inter(
          color: pureWhite,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
