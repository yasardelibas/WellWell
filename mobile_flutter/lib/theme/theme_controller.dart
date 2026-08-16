import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App-wide dark/light/system preference. This is pure rendering, never sent to the
/// server (unlike biometricLockEnabled/privacyNotificationsEnabled, which are server-side
/// because server behaviour depends on them) — so it's stored locally, the same tier as
/// onboardingCompleted.
class AppTheme {
  static const _prefsKey = 'themeMode';

  static final ValueNotifier<ThemeMode> modeNotifier = ValueNotifier(ThemeMode.system);

  static Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_prefsKey);
      modeNotifier.value = switch (saved) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };
    } catch (_) {
      // Best-effort: fall back to following the system setting.
    }
  }

  static Future<void> setMode(ThemeMode mode) async {
    modeNotifier.value = mode;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, switch (mode) {
        ThemeMode.light => 'light',
        ThemeMode.dark => 'dark',
        ThemeMode.system => 'system',
      });
    } catch (_) {
      // Best-effort: the in-memory value above still applies for this session.
    }
  }
}
