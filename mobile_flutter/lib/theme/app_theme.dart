import 'package:flutter/material.dart';

import 'palette.dart';

/// Builds a theme for the given brightness. Safe to call for both brightnesses back-to-back
/// (e.g. `theme: buildTheme(Brightness.light), darkTheme: buildTheme(Brightness.dark)`) since
/// it sets [Palette]'s mode before reading any colour, independent of call order — the caller
/// (`MedGuardApp.build`) is still responsible for setting the *live* mode afterward, since this
/// function's job is only to produce a fixed [ThemeData] snapshot for one brightness.
ThemeData buildTheme(Brightness brightness) {
  Palette.setBrightness(brightness);
  final dark = brightness == Brightness.dark;

  final text = TextTheme(
    displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: Palette.ink, height: 1.15),
    headlineMedium: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: Palette.ink, height: 1.2),
    titleMedium: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Palette.ink),
    bodyLarge: TextStyle(fontSize: 15, fontWeight: FontWeight.w400, color: Palette.ink, height: 1.4),
    bodyMedium: TextStyle(fontSize: 15, color: Palette.inkMuted, height: 1.4),
    labelLarge: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Palette.inkMuted),
    labelSmall: TextStyle(fontSize: 12, color: Palette.inkSubtle),
  );

  final colorScheme = dark
      ? ColorScheme.dark(
          primary: Palette.brand,
          secondary: Palette.teal,
          surface: Palette.surface,
          error: Palette.critical,
          onPrimary: Colors.white,
          onSurface: Palette.ink,
        )
      : ColorScheme.light(
          primary: Palette.brand,
          secondary: Palette.teal,
          surface: Palette.surface,
          error: Palette.critical,
          onPrimary: Colors.white,
          onSurface: Palette.ink,
        );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    scaffoldBackgroundColor: Palette.canvas,
    colorScheme: colorScheme,
    textTheme: text,
    appBarTheme: AppBarTheme(
      backgroundColor: Palette.canvas,
      foregroundColor: Palette.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Palette.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Palette.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Palette.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Palette.brand, width: 1.5),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: Palette.brand,
        foregroundColor: Colors.white,
        minimumSize: const Size(64, 56),
        shape: const StadiumBorder(),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: Palette.ink,
        minimumSize: const Size(64, 56),
        side: BorderSide(color: Palette.line),
        shape: const StadiumBorder(),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
  );
}
