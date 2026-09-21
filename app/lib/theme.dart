import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'utils/app_fonts.dart';
import 'utils/constants.dart';

/// Light and dark themes built from the app's deep-blue palette. Centralized
/// here so every screen inherits consistent spacing, radii, and typography
/// rather than hand-rolling styles per widget.
///
/// [khmer] picks the app-wide font: Inter for English, bold Kantumruy Pro
/// for Khmer (see `utils/app_fonts.dart`). This has to be decided here,
/// before `MaterialApp` builds, rather than read from
/// `Localizations.of(context)` — the app's own [LocaleProvider] is the
/// source of truth for which language is active either way.
class AppTheme {
  AppTheme._();

  static ThemeData light({required bool khmer}) {
    final base = ThemeData(
      brightness: Brightness.light,
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: AppColors.surfaceLight,
      ),
      scaffoldBackgroundColor: AppColors.surfaceLight,
      textTheme: appTextTheme(khmer: khmer, base: ThemeData.light().textTheme),
    );
    return _shared(base, khmer: khmer);
  }

  static ThemeData dark({required bool khmer}) {
    final base = ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.dark,
        primary: Colors.white,
        secondary: AppColors.accent,
        surface: AppColors.surfaceDark,
      ),
      scaffoldBackgroundColor: AppColors.surfaceDark,
      textTheme: appTextTheme(khmer: khmer, base: ThemeData.dark().textTheme),
    );
    return _shared(base, khmer: khmer);
  }

  static TextStyle _titleFont(bool khmer, {required double fontSize, required FontWeight fontWeight, required Color color}) {
    return khmer
        ? GoogleFonts.kantumruyPro(fontSize: fontSize, fontWeight: FontWeight.bold, color: color)
        : GoogleFonts.inter(fontSize: fontSize, fontWeight: fontWeight, color: color);
  }

  static ThemeData _shared(ThemeData base, {required bool khmer}) {
    final isDark = base.brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final mutedColor = isDark ? AppColors.textMutedDark : AppColors.textMutedLight;
    return base.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: base.brightness == Brightness.dark ? AppColors.surfaceDark : AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: _titleFont(khmer, fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.card)),
        color: base.brightness == Brightness.dark ? AppColors.cardDark : AppColors.cardLight,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: Spacing.lg, vertical: Spacing.md),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.button)),
          textStyle: _titleFont(khmer, fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: Spacing.lg, vertical: Spacing.md),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.button)),
          textStyle: _titleFont(khmer, fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.primary),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: base.brightness == Brightness.dark ? AppColors.cardDark : Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: Spacing.md, vertical: Spacing.md),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.button),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.button),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.button),
          borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: base.brightness == Brightness.dark ? AppColors.cardDark : Colors.white,
        selectedItemColor: AppColors.accent,
        unselectedItemColor: mutedColor,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
      ),
    );
  }
}
