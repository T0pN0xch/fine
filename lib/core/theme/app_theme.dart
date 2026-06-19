import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Category colors — pastel palette (shared look across categories app-wide, theme-independent)
  static const List<Color> categoryColors = [
    Color(0xFFCDC8F5), // lavender
    Color(0xFFA8E6CF), // mint
    Color(0xFFFFB8C6), // blush pink
    Color(0xFFFFE08A), // butter yellow
    Color(0xFFAEE0F2), // sky blue
    Color(0xFFD8C2EC), // lilac
    Color(0xFFC6E8A0), // light green
    Color(0xFFFFC9A8), // peach
    Color(0xFFD8D8E8), // soft gray
    Color(0xFFA9D2F0), // periwinkle
  ];

  // Pastel palette for Goals cards (kept as alias of the same family for consistency)
  static const List<Color> goalColors = categoryColors;

  // Solid, vivid palette (no grey/black) for charts where pastel/desaturated
  // colors are hard to tell apart, e.g. the pie chart slices.
  static const List<Color> vividColors = [
    Color(0xFF8B7CF6), // purple
    Color(0xFF34C98E), // green
    Color(0xFFFF6B8A), // pink
    Color(0xFFFFC542), // yellow
    Color(0xFF45C4E8), // sky blue
    Color(0xFFB07CF0), // violet
    Color(0xFF7ED957), // lime green
    Color(0xFFFF935E), // orange
    Color(0xFFE05DD0), // magenta
    Color(0xFF5B8CF0), // periwinkle blue
  ];

  // Darker, more saturated variant of a pastel, for progress-bar fills on top of it.
  static Color progressFillFor(Color pastel) {
    final hsl = HSLColor.fromColor(pastel);
    return hsl
        .withLightness((hsl.lightness - 0.30).clamp(0.0, 1.0))
        .withSaturation((hsl.saturation + 0.25).clamp(0.0, 1.0))
        .toColor();
  }
}

/// Theme-aware neutral/semantic colors, resolved per-context via `context.colors`.
class AppColorsExt extends ThemeExtension<AppColorsExt> {
  final Color primary;
  final Color primaryLight;
  final Color primaryLighter;
  final Color primarySurface;

  final Color income;
  final Color incomeLight;
  final Color incomeSurface;

  final Color expense;
  final Color expenseLight;
  final Color expenseSurface;

  final Color warning;
  final Color warningSurface;

  final Color background;
  final Color surface;
  final Color surfaceVariant;
  final Color border;

  final Color textPrimary;
  final Color textSecondary;
  final Color textHint;

  const AppColorsExt({
    required this.primary,
    required this.primaryLight,
    required this.primaryLighter,
    required this.primarySurface,
    required this.income,
    required this.incomeLight,
    required this.incomeSurface,
    required this.expense,
    required this.expenseLight,
    required this.expenseSurface,
    required this.warning,
    required this.warningSurface,
    required this.background,
    required this.surface,
    required this.surfaceVariant,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.textHint,
  });

  static const light = AppColorsExt(
    primary: Color(0xFF8B7FE8),
    primaryLight: Color(0xFFB3A9F2),
    primaryLighter: Color(0xFFE2DCFB),
    primarySurface: Color(0xFFF1EEFD),
    income: Color(0xFF4CAF8D),
    incomeLight: Color(0xFFA8E6CF),
    incomeSurface: Color(0xFFE6F7EF),
    expense: Color(0xFFE8716E),
    expenseLight: Color(0xFFFFB8C6),
    expenseSurface: Color(0xFFFDECEC),
    warning: Color(0xFFEFB75E),
    warningSurface: Color(0xFFFFF3DC),
    background: Color(0xFFF8F6FE),
    surface: Color(0xFFFFFFFF),
    surfaceVariant: Color(0xFFF1EEFD),
    border: Color(0xFFEAE5FB),
    textPrimary: Color(0xFF2B2640),
    textSecondary: Color(0xFF73698F),
    textHint: Color(0xFFB3ABCB),
  );

  static const dark = AppColorsExt(
    primary: Color(0xFF9B8FF0),
    primaryLight: Color(0xFF7A6FCB),
    primaryLighter: Color(0xFF5B5391),
    primarySurface: Color(0xFF2A2640),
    income: Color(0xFF5FCBA3),
    incomeLight: Color(0xFF3F8C6E),
    incomeSurface: Color(0xFF1C3A2E),
    expense: Color(0xFFF08A87),
    expenseLight: Color(0xFFB5524F),
    expenseSurface: Color(0xFF3A2222),
    warning: Color(0xFFF0C272),
    warningSurface: Color(0xFF3A2E1A),
    background: Color(0xFF121018),
    surface: Color(0xFF1C1A28),
    surfaceVariant: Color(0xFF26223A),
    border: Color(0xFF332F4A),
    textPrimary: Color(0xFFEDEAF7),
    textSecondary: Color(0xFFA9A2C4),
    textHint: Color(0xFF6E6790),
  );

  @override
  AppColorsExt copyWith({
    Color? primary,
    Color? primaryLight,
    Color? primaryLighter,
    Color? primarySurface,
    Color? income,
    Color? incomeLight,
    Color? incomeSurface,
    Color? expense,
    Color? expenseLight,
    Color? expenseSurface,
    Color? warning,
    Color? warningSurface,
    Color? background,
    Color? surface,
    Color? surfaceVariant,
    Color? border,
    Color? textPrimary,
    Color? textSecondary,
    Color? textHint,
  }) {
    return AppColorsExt(
      primary: primary ?? this.primary,
      primaryLight: primaryLight ?? this.primaryLight,
      primaryLighter: primaryLighter ?? this.primaryLighter,
      primarySurface: primarySurface ?? this.primarySurface,
      income: income ?? this.income,
      incomeLight: incomeLight ?? this.incomeLight,
      incomeSurface: incomeSurface ?? this.incomeSurface,
      expense: expense ?? this.expense,
      expenseLight: expenseLight ?? this.expenseLight,
      expenseSurface: expenseSurface ?? this.expenseSurface,
      warning: warning ?? this.warning,
      warningSurface: warningSurface ?? this.warningSurface,
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceVariant: surfaceVariant ?? this.surfaceVariant,
      border: border ?? this.border,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textHint: textHint ?? this.textHint,
    );
  }

  @override
  AppColorsExt lerp(ThemeExtension<AppColorsExt>? other, double t) {
    if (other is! AppColorsExt) return this;
    return AppColorsExt(
      primary: Color.lerp(primary, other.primary, t)!,
      primaryLight: Color.lerp(primaryLight, other.primaryLight, t)!,
      primaryLighter: Color.lerp(primaryLighter, other.primaryLighter, t)!,
      primarySurface: Color.lerp(primarySurface, other.primarySurface, t)!,
      income: Color.lerp(income, other.income, t)!,
      incomeLight: Color.lerp(incomeLight, other.incomeLight, t)!,
      incomeSurface: Color.lerp(incomeSurface, other.incomeSurface, t)!,
      expense: Color.lerp(expense, other.expense, t)!,
      expenseLight: Color.lerp(expenseLight, other.expenseLight, t)!,
      expenseSurface: Color.lerp(expenseSurface, other.expenseSurface, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningSurface: Color.lerp(warningSurface, other.warningSurface, t)!,
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceVariant: Color.lerp(surfaceVariant, other.surfaceVariant, t)!,
      border: Color.lerp(border, other.border, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textHint: Color.lerp(textHint, other.textHint, t)!,
    );
  }
}

extension AppColorsContext on BuildContext {
  AppColorsExt get colors => Theme.of(this).extension<AppColorsExt>()!;
}

class AppTheme {
  static ThemeData _build(AppColorsExt c, Brightness brightness) {
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme.fromSeed(
        seedColor: c.primary,
        brightness: brightness,
        surface: c.surface,
        primary: c.primary,
      ),
      scaffoldBackgroundColor: c.background,
      extensions: [c],
      textTheme: GoogleFonts.poppinsTextTheme(
        brightness == Brightness.dark ? ThemeData.dark().textTheme : null,
      ).copyWith(
        displayLarge: GoogleFonts.poppins(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: c.textPrimary,
        ),
        displayMedium: GoogleFonts.poppins(
          fontSize: 26,
          fontWeight: FontWeight.w700,
          color: c.textPrimary,
        ),
        headlineLarge: GoogleFonts.poppins(
          fontSize: 23,
          fontWeight: FontWeight.w700,
          color: c.textPrimary,
        ),
        headlineMedium: GoogleFonts.poppins(
          fontSize: 19,
          fontWeight: FontWeight.w700,
          color: c.textPrimary,
        ),
        titleLarge: GoogleFonts.poppins(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: c.textPrimary,
        ),
        titleMedium: GoogleFonts.poppins(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: c.textPrimary,
        ),
        bodyLarge: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: c.textPrimary,
        ),
        bodyMedium: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: c.textSecondary,
        ),
        bodySmall: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: c.textHint,
        ),
        labelLarge: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: brightness == Brightness.dark ? c.textPrimary : c.surface,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: c.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 19,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
      cardTheme: CardThemeData(
        color: c.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: c.border, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: c.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: c.primary, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: GoogleFonts.poppins(
          fontSize: 14,
          color: c.textHint,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: c.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: c.surface,
        selectedItemColor: c.primary,
        unselectedItemColor: c.textHint,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),
      dividerTheme: DividerThemeData(
        color: c.border,
        thickness: 1,
        space: 1,
      ),
    );
  }

  static ThemeData get light => _build(AppColorsExt.light, Brightness.light);
  static ThemeData get dark => _build(AppColorsExt.dark, Brightness.dark);
}
