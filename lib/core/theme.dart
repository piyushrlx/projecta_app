import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Projeqta Website Light Mode Brand Palette (from app.css)
  static const Color scaffoldBg = Color(0xFFF6F7FB); // Website --bg: #f6f7fb
  static const Color cardSurface = Color(0xFFFFFFFF); // Website --surface: #ffffff
  static const Color surface2 = Color(0xFFF8FAFC); // Website --surface-2: #f8fafc
  static const Color dockSurface = Color(0xFFFFFFFF); // Pure White Bottom Dock
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color softGreyFill = Color(0xFFF8FAFC); // Soft Cool Grey for Inputs

  // Brand & Accent Colors
  static const Color electricBlue = Color(0xFF2D3FE3); // Website --primary: #2d3fe3
  static const Color electricIndigo = Color(0xFF2D3FE3); // Electric Indigo Blue alias
  static const Color primary600 = Color(0xFF2231C2); // Website --primary-600
  static const Color primary50 = Color(0xFFEEF0FF); // Website --primary-50
  static const Color primary100 = Color(0xFFDCDFFF); // Website --primary-100
  static const Color amber = Color(0xFFF5B400); // Website --accent: #f5b400
  static const Color amberBg = Color(0xFFFFF5D6); // Website --accent-bg
  static const Color deepInk = Color(0xFF141A2B); // Website --ink: #141a2b
  static const Color ink2 = Color(0xFF1C2440); // Website --ink-2
  static const Color royalBlue = Color(0xFF2D3FE3); // Backward-compatibility alias
  static const Color navyBlue = Color(0xFF141A2B); // Backward-compatibility alias
  static const Color borderSubtle = Color(0xFFE5E9F2); // Website --border: #e5e9f2
  static const Color borderStrong = Color(0xFFCFD6E4); // Website --border-strong: #cfd6e4
  static const Color dividerColor = Color(0xFFE5E9F2);

  // Text Hierarchy
  static const Color deepSlate = Color(0xFF141A2B); // Website --text: #141a2b (High-contrast dark ink)
  static const Color textSecondaryNavy = Color(0xFF4B5567); // Website --text-2: #4b5567 (Body text)
  static const Color mutedSlate = Color(0xFF7A8599); // Website --muted: #7a8599 (Labels / Subtitles)
  static const Color lightSlate = Color(0xFF94A3B8); // Hints / Placeholders
  static const Color textCanvas = Color(0xFF141A2B); // Canvas Headings / Section Titles
  static const Color textWhite = Color(0xFFFFFFFF);
  static const Color sidebarSectionHeader = Color(0xFF64748B);

  // Semantic Status Badges & Alerts (with 6px dot style)
  static const Color successBg = Color(0xFFE7F8EF);
  static const Color successText = Color(0xFF0F7A46);
  static const Color successDot = Color(0xFF15A35F);

  static const Color warningBg = Color(0xFFFFF6E5);
  static const Color warningText = Color(0xFF9A6205);
  static const Color warningDot = Color(0xFFD98A06);

  static const Color dangerBg = Color(0xFFFDECEC);
  static const Color dangerText = Color(0xFFB42626);
  static const Color dangerDot = Color(0xFFDC3B3B);

  static const Color infoBg = Color(0xFFEEF3FF);
  static const Color infoText = Color(0xFF1D4ED8);
  static const Color infoDot = Color(0xFF2F5BEA);

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

  // Soft diffused elevation shadow (matching website --shadow-sm & --shadow)
  static const BoxShadow softShadow = BoxShadow(
    color: Color(0x0A101828),
    blurRadius: 10,
    offset: Offset(0, 3),
  );

  // High-Contrast Card Decoration (Pure White, 18px rounded corners, subtle border & soft shadow)
  static BoxDecoration cardDecoration({
    Color backgroundColor = pureWhite,
    Color borderColor = borderSubtle,
    double borderRadius = 18.0,
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
    Color shadowColor = const Color(0x0A101828),
    double borderRadius = 18.0,
  }) {
    return BoxDecoration(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(color: borderColor, width: 1.0),
      boxShadow: shadowOffset > 0 ? const [softShadow] : null,
    );
  }

  // Semantic Status Badge Decoration (Soft pastel pill, full pill corners)
  static BoxDecoration statusBadgeDecoration({
    required Color backgroundColor,
    double borderRadius = 999.0,
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
    double borderRadius = 999.0,
  }) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(borderRadius),
    );
  }

  // Signature Status Badge with 6px dot
  static Widget statusBadgeWidget({
    required String label,
    required Color backgroundColor,
    required Color textColor,
    Color? dotColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dotColor != null) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: body(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  // Signature Heading Style 1: Top Module Header on Light Canvas
  static Widget moduleHeader({
    required String title,
    String tag = 'PROJEQTA',
    List<Widget>? actions,
    VoidCallback? onBack,
    bool showBackButton = false,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Row(
        children: [
          if (showBackButton) ...[
            IconButton(
              icon: const Icon(Icons.arrow_back, color: deepSlate),
              onPressed: onBack,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    title,
                    style: heading(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: deepSlate,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: primary50,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: primary100),
                  ),
                  child: Text(
                    tag.toUpperCase(),
                    style: mono(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: electricBlue,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ...?actions,
        ],
      ),
    );
  }

  // Signature Heading Style 2: Section Header Row on Light Canvas
  static Widget sectionHeader({
    required String title,
    String? actionLabel,
    VoidCallback? onActionTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: heading(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: deepSlate,
            ),
          ),
          if (actionLabel != null && onActionTap != null)
            InkWell(
              onTap: onActionTap,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: pureWhite,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderSubtle),
                  boxShadow: const [softShadow],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      actionLabel,
                      style: heading(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: deepSlate,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      size: 13,
                      color: deepSlate,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Font Deferral & Cache for Smooth Frame-0 Startup
  static bool _deferGoogleFonts = false;
  static final Map<String, TextStyle> _headingCache = {};
  static final Map<String, TextStyle> _bodyCache = {};
  static final Map<FontWeight, TextStyle> _monoCache = {};
  static ThemeData? _themeData;

  /// Defers GoogleFonts initialization during the first startup frame so
  /// asset manifest parsing and font loading do not block window focus.
  static void setDeferGoogleFonts(bool defer) {
    if (_deferGoogleFonts == defer) return;
    _deferGoogleFonts = defer;
    _headingCache.clear();
    _bodyCache.clear();
    _monoCache.clear();
    _themeData = null;
  }

  // Typography Getters
  // Headings & Titles: Sora (600 / 700)
  static TextStyle heading({
    double fontSize = 20,
    FontWeight fontWeight = FontWeight.w700,
    Color color = deepSlate,
    double? letterSpacing,
    double? height,
  }) {
    final base = _deferGoogleFonts
        ? TextStyle(fontWeight: fontWeight)
        : _headingCache.putIfAbsent(
            fontWeight.toString(),
            () => GoogleFonts.sora(fontWeight: fontWeight),
          );
    return base.copyWith(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing ?? -0.3,
      height: height,
    );
  }

  // Body & Descriptions: IBM Plex Sans (400 / 500 / 600)
  static TextStyle body({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w400,
    Color color = deepSlate,
    double? letterSpacing,
    double? height,
  }) {
    final base = _deferGoogleFonts
        ? TextStyle(fontWeight: fontWeight)
        : _bodyCache.putIfAbsent(
            fontWeight.toString(),
            () => GoogleFonts.ibmPlexSans(fontWeight: fontWeight),
          );
    return base.copyWith(
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
    final base = _deferGoogleFonts
        ? TextStyle(fontWeight: fontWeight, fontFamily: 'monospace')
        : _monoCache.putIfAbsent(
            fontWeight,
            () => GoogleFonts.jetBrainsMono(fontWeight: fontWeight),
          );
    return base.copyWith(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
    );
  }

  // Global Enterprise ThemeData
  static ThemeData get themeData => _themeData ??= _buildThemeData();
  static ThemeData _buildThemeData() {
    final textTheme = TextTheme(
      displayLarge: heading(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: deepSlate,
        letterSpacing: -0.8,
      ),
      displayMedium: heading(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        color: deepSlate,
        letterSpacing: -0.5,
      ),
      displaySmall: heading(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: deepSlate,
        letterSpacing: -0.3,
      ),
      headlineMedium: heading(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: deepSlate,
        letterSpacing: -0.3,
      ),
      headlineSmall: heading(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: deepSlate,
      ),
      titleLarge: heading(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: deepSlate,
      ),
      titleMedium: heading(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: deepSlate,
      ),
      titleSmall: heading(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: deepSlate,
      ),
      bodyLarge: body(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: deepSlate,
      ),
      bodyMedium: body(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: deepSlate,
      ),
      bodySmall: body(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: mutedSlate,
      ),
      labelLarge: heading(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: deepSlate,
      ),
      labelMedium: body(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: mutedSlate,
      ),
      labelSmall: mono(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: mutedSlate,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: scaffoldBg,
      canvasColor: scaffoldBg,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: electricBlue,
        onPrimary: pureWhite,
        secondary: amber,
        onSecondary: deepInk,
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
        titleTextStyle: heading(
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
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: borderSubtle, width: 1.0),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: electricBlue,
          foregroundColor: pureWhite,
          elevation: 0,
          shadowColor: Colors.transparent,
          textStyle: heading(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: deepSlate,
          backgroundColor: pureWhite,
          elevation: 0,
          textStyle: heading(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          side: const BorderSide(color: borderSubtle, width: 1.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: electricBlue,
          textStyle: heading(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: softGreyFill,
        labelStyle: body(
          color: mutedSlate,
          fontWeight: FontWeight.w500,
        ),
        hintStyle: body(
          color: lightSlate,
          fontWeight: FontWeight.w400,
        ),
        prefixIconColor: electricBlue,
        suffixIconColor: mutedSlate,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: electricBlue, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: dangerText, width: 1.0),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: dangerText, width: 1.5),
        ),
        errorStyle: body(
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
        contentTextStyle: body(
          color: pureWhite,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
