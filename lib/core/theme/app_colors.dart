import 'package:flutter/material.dart';

/// CropAId Color Palette
/// Extracted from the React project's tailwind.config.js and App.css
class AppColors {
  AppColors._();

  // ============================================
  // PRIMARY GRADIENT COLORS (from CSS)
  // ============================================
  static const Color primaryGreen = Color(0xFF0F5132);
  static const Color secondaryGreen = Color(0xFF2D6A4F);
  static const Color accentGreen = Color(0xFF4ADE80);
  static const Color emeraldGreen = Color(0xFF22C55E);
  static const Color greenLight = Color(0xFF16A34A);

  // Primary Gradient
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryGreen, secondaryGreen],
  );

  // Hero Gradient (for buttons)
  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accentGreen, emeraldGreen],
  );

  // ============================================
  // NATURE PALETTE (from tailwind.config.js)
  // ============================================
  static const Color nature50 = Color(0xFFF2FCF5);
  static const Color nature100 = Color(0xFFE1F8E8);
  static const Color nature200 = Color(0xFFC3ECD0);
  static const Color nature300 = Color(0xFF94D9AC);
  static const Color nature400 = Color(0xFF5BBC82);
  static const Color nature500 = Color(0xFF34A062);
  static const Color nature600 = Color(0xFF26814D);
  static const Color nature700 = Color(0xFF226740);
  static const Color nature800 = Color(0xFF1F5136);
  static const Color nature900 = Color(0xFF1A432E);
  static const Color nature950 = Color(0xFF0D2519);

  // ============================================
  // EARTH PALETTE (from tailwind.config.js)
  // ============================================
  static const Color earth50 = Color(0xFFFBF7F3);
  static const Color earth100 = Color(0xFFF5EFE6);
  static const Color earth200 = Color(0xFFEBDEC9);
  static const Color earth300 = Color(0xFFDEC49F);
  static const Color earth400 = Color(0xFFD0A775);
  static const Color earth500 = Color(0xFFC68D53);
  static const Color earth600 = Color(0xFFBA7444);
  static const Color earth700 = Color(0xFF9B5B3A);
  static const Color earth800 = Color(0xFF7F4B36);
  static const Color earth900 = Color(0xFF673E2E);
  static const Color earth950 = Color(0xFF371F17);

  // ============================================
  // DARK THEME COLORS (from App.css)
  // ============================================
  static const Color darkBg = Color(0xFF0F172A);
  static const Color darkBgAlt = Color(0xFF0A0F0A);
  static const Color darkBgSecondary = Color(0xFF0D1B0D);
  static const Color cardBg = Color(0xB31E293B); // rgba(30, 41, 59, 0.7)
  static const Color cardBgHover = Color(0xD91E293B); // rgba(30, 41, 59, 0.85)
  static const Color glassBorder = Color(0x14FFFFFF); // rgba(255, 255, 255, 0.08)
  static const Color glassBorderHover = Color(0x26FFFFFF); // rgba(255, 255, 255, 0.15)

  // ============================================
  // TEXT COLORS
  // ============================================
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textGreenLight = Color(0xFFE0FFE0);
  static const Color textGreenSubtle = Color(0xCCE0FFE0); // 0.8 opacity

  // ============================================
  // UI COLORS
  // ============================================
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color gray50 = Color(0xFFF9FAFB);
  static const Color gray100 = Color(0xFFF3F4F6);
  static const Color gray200 = Color(0xFFE5E7EB);
  static const Color gray300 = Color(0xFFD1D5DB);
  static const Color gray400 = Color(0xFF9CA3AF);
  static const Color gray500 = Color(0xFF6B7280);
  static const Color gray600 = Color(0xFF4B5563);
  static const Color gray700 = Color(0xFF374151);
  static const Color gray800 = Color(0xFF1F2937);

  // Status colors
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // Feature card colors
  static const Color blue100 = Color(0xFFDBEAFE);
  static const Color blue50 = Color(0xFFEFF6FF);
  static const Color blue500 = Color(0xFF3B82F6);
  static const Color blue600 = Color(0xFF2563EB);
  static const Color blue700 = Color(0xFF1D4ED8);

  static const Color purple100 = Color(0xFFF3E8FF);
  static const Color purple50 = Color(0xFFFAF5FF);
  static const Color purple600 = Color(0xFF9333EA);

  static const Color red100 = Color(0xFFFEE2E2);
  static const Color red50 = Color(0xFFFEF2F2);
  static const Color red500 = Color(0xFFEF4444);

  static const Color amber100 = Color(0xFFFEF3C7);
  static const Color amber50 = Color(0xFFFFFBEB);
  static const Color amber600 = Color(0xFFD97706);
  static const Color amber700 = Color(0xFFB45309);

  static const Color sky100 = Color(0xFFE0F2FE);
  static const Color sky50 = Color(0xFFF0F9FF);
  static const Color sky500 = Color(0xFF0EA5E9);

  static const Color teal50 = Color(0xFFF0FDFA);
  static const Color teal600 = Color(0xFF0D9488);

  // Additional gray shades
  static const Color gray900 = Color(0xFF111827);

  // Additional red shades
  static const Color red400 = Color(0xFFF87171);
  static const Color red600 = Color(0xFFDC2626);

  // Additional purple shades
  static const Color purple500 = Color(0xFFA855F7);
  static const Color purple700 = Color(0xFF7C3AED);
  // Additional shades for CropAdviceCard
  static const Color blue200 = Color(0xFFBFDBFE);
  static const Color purple200 = Color(0xFFE9D5FF);
  static const Color red200 = Color(0xFFFECACA);
  static const Color red300 = Color(0xFFFCA5A5);
  static const Color amber200 = Color(0xFFFDE68A);
  static const Color amber300 = Color(0xFFFCD34D);
  static const Color amber800 = Color(0xFF92400E);
  static const Color amber900 = Color(0xFF78350F);
}
