import 'package:flutter/material.dart';

import 'palette.dart';

ThemeData buildTheme() {
  const text = TextTheme(
    displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: Palette.ink, height: 1.15),
    headlineMedium: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: Palette.ink, height: 1.2),
    titleMedium: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Palette.ink),
    bodyLarge: TextStyle(fontSize: 15, fontWeight: FontWeight.w400, color: Palette.ink, height: 1.4),
    bodyMedium: TextStyle(fontSize: 15, color: Palette.inkMuted, height: 1.4),
    labelLarge: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Palette.inkMuted),
    labelSmall: TextStyle(fontSize: 12, color: Palette.inkSubtle),
  );

  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: Palette.canvas,
    colorScheme: const ColorScheme.light(
      primary: Palette.brand,
      secondary: Palette.teal,
      surface: Palette.surface,
      error: Palette.critical,
      onPrimary: Colors.white,
      onSurface: Palette.ink,
    ),
    textTheme: text,
    appBarTheme: const AppBarTheme(
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
        borderSide: const BorderSide(color: Palette.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Palette.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Palette.brand, width: 1.5),
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
        side: const BorderSide(color: Palette.line),
        shape: const StadiumBorder(),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
  );
}
