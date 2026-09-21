import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Per-locale typography: **Inter** for English, **Kantumruy Pro Bold** for
/// Khmer — per product requirement, every piece of Khmer text in the app
/// uses the bold weight of Kantumruy Pro regardless of the weight an
/// individual `Text` widget asks for, for consistent, highly legible Khmer
/// typography (Khmer script needs a heavier stroke than Latin text at the
/// same size to stay readable at small sizes).
///
/// [appFont] is for one-off `Text` widgets that build their own `TextStyle`
/// inline (this app's original design used `GoogleFonts.inter(...)`
/// directly in many places); [appTextTheme] is for the app-wide `ThemeData`
/// built in `theme.dart`, which needs to know the language *before*
/// `MaterialApp` mounts (see `LocaleProvider`).
TextStyle appFont(
  BuildContext context, {
  double? fontSize,
  FontWeight? fontWeight,
  Color? color,
  double? height,
  FontStyle? fontStyle,
  double? letterSpacing,
  TextDecoration? decoration,
}) {
  final isKhmer = Localizations.localeOf(context).languageCode == 'km';
  if (isKhmer) {
    return GoogleFonts.kantumruyPro(
      fontSize: fontSize,
      fontWeight: FontWeight.bold,
      color: color,
      height: height,
      fontStyle: fontStyle,
      letterSpacing: letterSpacing,
      decoration: decoration,
    );
  }
  return GoogleFonts.inter(
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
    height: height,
    fontStyle: fontStyle,
    letterSpacing: letterSpacing,
    decoration: decoration,
  );
}

/// Builds a full [TextTheme] for the given language: Inter for English, or
/// every style remapped to bold Kantumruy Pro for Khmer.
TextTheme appTextTheme({required bool khmer, required TextTheme base}) {
  if (!khmer) return GoogleFonts.interTextTheme(base);

  TextStyle? bold(TextStyle? style) =>
      style == null ? null : GoogleFonts.kantumruyPro(textStyle: style, fontWeight: FontWeight.bold);

  return base.copyWith(
    displayLarge: bold(base.displayLarge),
    displayMedium: bold(base.displayMedium),
    displaySmall: bold(base.displaySmall),
    headlineLarge: bold(base.headlineLarge),
    headlineMedium: bold(base.headlineMedium),
    headlineSmall: bold(base.headlineSmall),
    titleLarge: bold(base.titleLarge),
    titleMedium: bold(base.titleMedium),
    titleSmall: bold(base.titleSmall),
    bodyLarge: bold(base.bodyLarge),
    bodyMedium: bold(base.bodyMedium),
    bodySmall: bold(base.bodySmall),
    labelLarge: bold(base.labelLarge),
    labelMedium: bold(base.labelMedium),
    labelSmall: bold(base.labelSmall),
  );
}
