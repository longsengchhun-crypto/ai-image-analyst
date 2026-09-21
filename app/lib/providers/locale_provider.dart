import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Owns the user's chosen app language (English or Khmer), persisted across
/// launches. Deliberately app-level state — not just relying on the device's
/// system locale — so a user can pick Khmer even on a phone whose OS is set
/// to English, and so `AppTheme` can pick the right font (Kantumruy Pro Bold
/// for Khmer, Inter for English) *before* `MaterialApp` builds, when
/// `Localizations.of(context)` isn't available yet.
class LocaleProvider extends ChangeNotifier {
  static const _prefKey = 'app_locale';
  static const supportedLocales = [Locale('en'), Locale('km')];

  Locale _locale = const Locale('en');
  Locale get locale => _locale;
  bool get isKhmer => _locale.languageCode == 'km';

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefKey);
    if (saved != null && supportedLocales.any((l) => l.languageCode == saved)) {
      _locale = Locale(saved);
      notifyListeners();
      return;
    }
    // No saved preference yet: default to the device's language if it's one
    // we support (Khmer), otherwise fall back to English.
    final deviceCode = PlatformDispatcher.instance.locale.languageCode;
    if (supportedLocales.any((l) => l.languageCode == deviceCode)) {
      _locale = Locale(deviceCode);
      notifyListeners();
    }
  }

  Future<void> setLocale(Locale locale) async {
    if (locale.languageCode == _locale.languageCode) return;
    _locale = locale;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, locale.languageCode);
  }
}
