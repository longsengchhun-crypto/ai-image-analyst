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
        secondary: AppColors.primary,
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
        primary: const Color(0xFF9490F5), // lighter indigo tint for AA contrast on dark surfaces
        secondary: const Color(0xFF9490F5),
        surface: AppColors.surfaceDark,
      ),
      scaffoldBackgroundColor: AppColors.surfaceDark,
      textTheme: appTextTheme(khmer: khmer, base: ThemeData.dark().textTheme),
    );
    return _shared(base, khmer: khmer);
  }

  /// Product/heading font: **Plus Jakarta Sans** for English (a geometric,
  /// confident sans used across the "modern product" reference points this
  /// redesign targets — Linear, Stripe, Raycast — instead of the previous
  /// Inter, which is the single most common Flutter/web default and reads as
  /// generic on its own). Khmer stays bold Kantumruy Pro everywhere,
  /// unchanged, per the localization requirement.
  static TextStyle _titleFont(bool khmer, {required double fontSize, required FontWeight fontWeight, required Color color}) {
    return khmer
        ? GoogleFonts.kantumruyPro(fontSize: fontSize, fontWeight: FontWeight.bold, color: color)
        : GoogleFonts.plusJakartaSans(fontSize: fontSize, fontWeight: fontWeight, color: color);
  }

  static ThemeData _shared(ThemeData base, {required bool khmer}) {
    final isDark = base.brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final mutedColor = isDark ? AppColors.textMutedDark : AppColors.textMutedLight;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final cardColor = isDark ? AppColors.cardDark : AppColors.cardLight;
    final primaryColor = isDark ? const Color(0xFF9490F5) : AppColors.primary;

    return base.copyWith(
      splashFactory: InkSparkle.splashFactory,
      // A light, bordered-bottom header instead of a solid brand-color block
      // — the app's identity now comes from typography and the primary
      // color used deliberately (buttons, active states), not from painting
      // every top bar navy. This alone is one of the biggest visual breaks
      // from the previous design.
      appBarTheme: AppBarTheme(
        backgroundColor: surfaceColor,
        foregroundColor: textColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: _titleFont(khmer, fontSize: 18, fontWeight: FontWeight.w700, color: textColor),
        iconTheme: IconThemeData(color: textColor),
        actionsIconTheme: IconThemeData(color: textColor),
        shape: Border(bottom: BorderSide(color: borderColor)),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.card),
          side: BorderSide(color: borderColor),
        ),
        color: cardColor,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          disabledBackgroundColor: primaryColor.withValues(alpha: 0.4),
          padding: const EdgeInsets.symmetric(horizontal: Spacing.lg, vertical: Spacing.sm + 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.button)),
          textStyle: _titleFont(khmer, fontSize: 14.5, fontWeight: FontWeight.w600, color: Colors.white),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textColor,
          side: BorderSide(color: borderColor),
          padding: const EdgeInsets.symmetric(horizontal: Spacing.lg, vertical: Spacing.sm + 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.button)),
          textStyle: _titleFont(khmer, fontSize: 14.5, fontWeight: FontWeight.w600, color: textColor),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          textStyle: _titleFont(khmer, fontSize: 14, fontWeight: FontWeight.w600, color: primaryColor),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: Spacing.md, vertical: Spacing.sm + 2),
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
          borderSide: BorderSide(color: primaryColor, width: 1.5),
        ),
      ),
      dividerTheme: DividerThemeData(color: borderColor, space: 1, thickness: 1),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: cardColor,
        selectedItemColor: primaryColor,
        unselectedItemColor: mutedColor,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
        elevation: 0,
      ),
    );
  }
}
