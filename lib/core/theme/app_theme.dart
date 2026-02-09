import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// CropAId App Theme
/// Replicates the styling from the React project
class AppTheme {
  AppTheme._();

  // ============================================
  // LIGHT THEME (Used in main app screens)
  // ============================================
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary: AppColors.primaryGreen,
        secondary: AppColors.secondaryGreen,
        tertiary: AppColors.accentGreen,
        surface: AppColors.white,
        error: AppColors.error,
      ),
      scaffoldBackgroundColor: AppColors.nature50,
      textTheme: _textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.gray800,
        ).copyWith(
          // US3: Fallback for Indic languages
          fontFamilyFallback: ['Noto Sans', 'Arial', 'sans-serif'],
        ),
        iconTheme: const IconThemeData(color: AppColors.gray600),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.nature600,
          foregroundColor: AppColors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryGreen,
          side: const BorderSide(color: AppColors.nature200),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.gray200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.gray200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.secondaryGreen, width: 2),
        ),
        hintStyle: GoogleFonts.inter(
          color: AppColors.gray400,
          fontSize: 16,
        ),
      ),
      cardTheme: const CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        color: AppColors.white,
      ),
    );
  }

  // ============================================
  // DARK THEME (Used in HomePage landing)
  // ============================================
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: AppColors.accentGreen,
        secondary: AppColors.emeraldGreen,
        tertiary: AppColors.greenLight,
        surface: AppColors.darkBg,
        error: AppColors.error,
      ),
      scaffoldBackgroundColor: AppColors.darkBgAlt,
      textTheme: _darkTextTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
    );
  }

  // ============================================
  // TEXT THEMES
  // ============================================
  static TextTheme get _textTheme {
    // Shared fallback fonts for Indic languages (US3)
    const fallbacks = ['Noto Sans', 'Arial', 'sans-serif'];

    return TextTheme(
      displayLarge: GoogleFonts.inter(
        fontSize: 72,
        fontWeight: FontWeight.w800,
        letterSpacing: -2,
        color: AppColors.gray800,
      ).copyWith(fontFamilyFallback: fallbacks),
      displayMedium: GoogleFonts.inter(
        fontSize: 48,
        fontWeight: FontWeight.w700,
        color: AppColors.gray800,
      ).copyWith(fontFamilyFallback: fallbacks),
      displaySmall: GoogleFonts.inter(
        fontSize: 36,
        fontWeight: FontWeight.w700,
        color: AppColors.gray800,
      ).copyWith(fontFamilyFallback: fallbacks),
      headlineLarge: GoogleFonts.inter(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: AppColors.gray800,
      ).copyWith(fontFamilyFallback: fallbacks),
      headlineMedium: GoogleFonts.inter(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: AppColors.gray800,
      ).copyWith(fontFamilyFallback: fallbacks),
      headlineSmall: GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: AppColors.gray800,
      ).copyWith(fontFamilyFallback: fallbacks),
      titleLarge: GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.gray800,
      ).copyWith(fontFamilyFallback: fallbacks),
      titleMedium: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.gray700,
      ).copyWith(fontFamilyFallback: fallbacks),
      titleSmall: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.gray700,
      ).copyWith(fontFamilyFallback: fallbacks),
      bodyLarge: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w400,
        height: 1.7,
        color: AppColors.gray600,
      ).copyWith(fontFamilyFallback: fallbacks),
      bodyMedium: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: AppColors.gray600,
      ).copyWith(fontFamilyFallback: fallbacks),
      bodySmall: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.gray500,
      ).copyWith(fontFamilyFallback: fallbacks),
      labelLarge: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.gray700,
      ).copyWith(fontFamilyFallback: fallbacks),
      labelMedium: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.gray600,
      ).copyWith(fontFamilyFallback: fallbacks),
      labelSmall: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 1,
        color: AppColors.gray500,
      ).copyWith(fontFamilyFallback: fallbacks),
    );
  }

  static TextTheme get _darkTextTheme {
    // Shared fallback fonts for Indic languages (US3)
    const fallbacks = ['Noto Sans', 'Arial', 'sans-serif'];

    return TextTheme(
      displayLarge: GoogleFonts.inter(
        fontSize: 72,
        fontWeight: FontWeight.w800,
        letterSpacing: -2,
        color: AppColors.textGreenLight,
      ).copyWith(fontFamilyFallback: fallbacks),
      displayMedium: GoogleFonts.inter(
        fontSize: 48,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ).copyWith(fontFamilyFallback: fallbacks),
      displaySmall: GoogleFonts.inter(
        fontSize: 36,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ).copyWith(fontFamilyFallback: fallbacks),
      headlineLarge: GoogleFonts.inter(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ).copyWith(fontFamilyFallback: fallbacks),
      headlineMedium: GoogleFonts.inter(
        fontSize: 28,
        fontWeight: FontWeight.w500,
        letterSpacing: 1,
        color: AppColors.textGreenSubtle,
      ).copyWith(fontFamilyFallback: fallbacks),
      headlineSmall: GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ).copyWith(fontFamilyFallback: fallbacks),
      titleLarge: GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ).copyWith(fontFamilyFallback: fallbacks),
      titleMedium: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ).copyWith(fontFamilyFallback: fallbacks),
      titleSmall: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
      ).copyWith(fontFamilyFallback: fallbacks),
      bodyLarge: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w400,
        height: 1.7,
        color: AppColors.textGreenSubtle,
      ).copyWith(fontFamilyFallback: fallbacks),
      bodyMedium: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
      ).copyWith(fontFamilyFallback: fallbacks),
      bodySmall: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
      ).copyWith(fontFamilyFallback: fallbacks),
      labelLarge: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.accentGreen,
      ).copyWith(fontFamilyFallback: fallbacks),
      labelMedium: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.accentGreen,
      ).copyWith(fontFamilyFallback: fallbacks),
      labelSmall: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: AppColors.accentGreen,
      ).copyWith(fontFamilyFallback: fallbacks),
    );
  }
}
