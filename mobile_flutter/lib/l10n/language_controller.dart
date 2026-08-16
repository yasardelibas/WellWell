import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App-wide display language. Null means "follow the device locale" (System). This is the
/// mobile side of a two-part preference: `User.preferredLanguage` on the backend drives
/// server-generated text (safety findings, emails); this drives the ~400+ strings baked
/// into the UI itself. The two are kept in sync when the user changes this setting while
/// signed in — see AppSettingsScreen.
class AppLanguage {
  static const _prefsKey = 'appLocale';

  static final ValueNotifier<Locale?> localeNotifier = ValueNotifier(null);

  static Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_prefsKey);
      localeNotifier.value = saved == null ? null : Locale(saved);
    } catch (_) {
      // Best-effort: fall back to following the device locale.
    }
  }

  /// Pass null for "System" (follow the device locale).
  static Future<void> setLanguage(String? languageCode) async {
    localeNotifier.value = languageCode == null ? null : Locale(languageCode);
    try {
      final prefs = await SharedPreferences.getInstance();
      if (languageCode == null) {
        await prefs.remove(_prefsKey);
      } else {
        await prefs.setString(_prefsKey, languageCode);
      }
    } catch (_) {
      // Best-effort: the in-memory value above still applies for this session.
    }
  }

  /// The backend's wire format for the resolved language ("en"/"tr"), used to keep
  /// User.preferredLanguage in sync so server-generated text matches the UI language.
  static String wireLanguageFor(BuildContext context) {
    final explicit = localeNotifier.value;
    if (explicit != null) return explicit.languageCode;
    final deviceCode = View.of(context).platformDispatcher.locale.languageCode;
    return deviceCode == 'tr' ? 'tr' : 'en';
  }

  /// Context-free equivalent of [wireLanguageFor], for code that runs without a
  /// BuildContext (date formatting, API error mapping, scheduled local notifications).
  static String get currentCode {
    final explicit = localeNotifier.value;
    final deviceCode = explicit?.languageCode ?? PlatformDispatcher.instance.locale.languageCode;
    return deviceCode == 'tr' ? 'tr' : 'en';
  }
}
