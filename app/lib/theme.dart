import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'utils/constants.dart';

/// Light and dark themes built from the app's deep-blue palette. Centralized
/// here so every screen inherits consistent spacing, radii, and typography
/// rather than hand-rolling styles per widget.
class AppTheme {
  AppTheme._();

  static ThemeData light() {
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
      textTheme: GoogleFonts.interTextTheme(),
    );
    return _shared(base);
  }

  static ThemeData dark() {
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
      textTheme: GoogleFonts.interTextTheme(ThemeData(brightness: Brightness.dark).textTheme),
    );
    return _shared(base);
  }

  static ThemeData _shared(ThemeData base) {
    return base.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: base.brightness == Brightness.dark ? AppColors.surfaceDark : AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
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
          textStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: Spacing.lg, vertical: Spacing.md),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.button)),
          textStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: base.brightness == Brightness.dark ? AppColors.cardDark : Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: Spacing.md, vertical: Spacing.md),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.button),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.button),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.button),
          borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: base.brightness == Brightness.dark ? AppColors.cardDark : Colors.white,
        selectedItemColor: AppColors.accent,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
      ),
    );
  }
}
