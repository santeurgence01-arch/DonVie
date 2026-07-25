import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  AppColors._();

  static const primary = Color(0xFFB3261E);
  static const primaryDark = Color(0xFF8C1D16);
  static const primaryLight = Color(0xFFF9DEDC);
  static const secondary = Color(0xFF1A73E8);
  static const success = Color(0xFF1E8E3E);
  static const alert = Color(0xFFF9AB00);
  static const alertText = Color(0xFF7A5900);
  static const danger = Color(0xFFD93025);
  static const background = Color(0xFFF7F8FA);
  static const surface = Color(0xFFFFFFFF);
  static const border = Color(0xFFE1E3E6);
  static const textPrimary = Color(0xFF1C1B1F);
  static const textSecondary = Color(0xFF5F6368);
  static const textDisabled = Color(0xFF9AA0A6);
  static const successBg = Color(0xFFE6F4EA);
  static const alertBg = Color(0xFFFEF7E0);
  static const dangerBg = Color(0xFFFCE8E6);
}

class AppRadius {
  AppRadius._();

  static const card = 16.0;
  static const control = 12.0;
  static const pill = 24.0;
}

class AppSpacing {
  AppSpacing._();

  static const unit = 8.0;
  static const screenPaddingMobile = 16.0;
  static const screenPaddingWeb = 24.0;
  static const sectionGap = 24.0;
  static const fieldGap = 16.0;
}

/// Ombre standard des cartes : blur 8px, opacité 8%, offset (0,2).
const List<BoxShadow> kCardShadow = [
  BoxShadow(color: Color(0x14000000), blurRadius: 8, offset: Offset(0, 2)),
];

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    final baseTextTheme = GoogleFonts.interTextTheme();

    final textTheme = baseTextTheme.copyWith(
      // Display — titre d'accueil du dashboard
      headlineLarge: GoogleFonts.inter(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        height: 34 / 28,
        color: AppColors.textPrimary,
      ),
      // Headline — titre d'écran
      headlineSmall: GoogleFonts.inter(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        height: 28 / 22,
        color: AppColors.textPrimary,
      ),
      // Title — titre de section/carte
      titleLarge: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        height: 24 / 18,
        color: AppColors.textPrimary,
      ),
      // Body large — texte de formulaire, listes
      bodyLarge: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 22 / 16,
        color: AppColors.textPrimary,
      ),
      // Body medium — texte secondaire
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 20 / 14,
        color: AppColors.textSecondary,
      ),
      // Label — labels de champs, badges
      labelLarge: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 16 / 12,
        letterSpacing: 0.2,
        color: AppColors.textSecondary,
      ),
    );

    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      error: AppColors.danger,
      surface: AppColors.surface,
    );

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: colorScheme,
      textTheme: textTheme,
      fontFamily: GoogleFonts.inter().fontFamily,
      dividerColor: AppColors.border,
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return AppColors.border;
            }
            if (states.contains(WidgetState.pressed)) {
              return AppColors.primaryDark;
            }
            return AppColors.primary;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return AppColors.textDisabled;
            }
            return Colors.white;
          }),
          minimumSize: const WidgetStatePropertyAll(Size.fromHeight(48)),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.control),
            ),
          ),
          elevation: const WidgetStatePropertyAll(0),
          textStyle: WidgetStatePropertyAll(
            GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          foregroundColor: const WidgetStatePropertyAll(AppColors.primary),
          side: const WidgetStatePropertyAll(
            BorderSide(color: AppColors.primary, width: 1.5),
          ),
          minimumSize: const WidgetStatePropertyAll(Size.fromHeight(48)),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.control),
            ),
          ),
          textStyle: WidgetStatePropertyAll(
            GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          foregroundColor: const WidgetStatePropertyAll(AppColors.secondary),
          textStyle: WidgetStatePropertyAll(
            GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        labelStyle: GoogleFonts.inter(
          fontSize: 16,
          color: AppColors.textSecondary,
        ),
        hintStyle: GoogleFonts.inter(
          fontSize: 16,
          color: AppColors.textDisabled,
        ),
        errorStyle: GoogleFonts.inter(
          fontSize: 12,
          color: AppColors.danger,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.control),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.control),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.control),
          borderSide: const BorderSide(color: AppColors.secondary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.control),
          borderSide: const BorderSide(color: AppColors.danger, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.control),
          borderSide: const BorderSide(color: AppColors.danger, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.control),
          borderSide: const BorderSide(color: AppColors.border),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surface,
        selectedColor: AppColors.primary,
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        labelStyle: GoogleFonts.inter(
          fontSize: 14,
          color: AppColors.textPrimary,
        ),
        secondaryLabelStyle: GoogleFonts.inter(
          fontSize: 14,
          color: Colors.white,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
    );
  }
}
