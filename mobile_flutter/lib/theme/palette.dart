import 'package:flutter/material.dart';

/// Colour tokens. Values are getters, not consts, so the same `Palette.x` call sites used
/// throughout the app resolve to the light or dark variant depending on [Palette.setBrightness] -
/// call sites don't need to know which mode is active.
class Palette {
  static Brightness _brightness = Brightness.light;

  static bool get _dark => _brightness == Brightness.dark;

  static void setBrightness(Brightness brightness) => _brightness = brightness;

  static Color get canvas => _dark ? const Color(0xFF0B0F19) : const Color(0xFFF9FAFB);
  static Color get surface => _dark ? const Color(0xFF151B2C) : const Color(0xFFFFFFFF);
  static Color get surfaceMuted => _dark ? const Color(0xFF1E2536) : const Color(0xFFF3F4F6);
  static Color get ink => _dark ? const Color(0xFFF3F4F6) : const Color(0xFF1F2937);
  static Color get inkMuted => _dark ? const Color(0xFFB4BAC9) : const Color(0xFF6B7280);
  static Color get inkSubtle => _dark ? const Color(0xFF7C8494) : const Color(0xFF9CA3AF);
  static Color get line => _dark ? const Color(0xFF2A3244) : const Color(0xFFE5E7EB);
  static Color get brand => const Color(0xFF2E63EB);
  static Color get brandDark => const Color(0xFF1E4ED8);
  static Color get brandSoft => _dark ? const Color(0xFF1B2A4D) : const Color(0xFFEBF1FF);
  static Color get teal => const Color(0xFF14B8A6);
  static Color get safe => _dark ? const Color(0xFF34D399) : const Color(0xFF10B981);
  static Color get attention => _dark ? const Color(0xFFFBBF24) : const Color(0xFFF59E0B);
  static Color get critical => _dark ? const Color(0xFFF87171) : const Color(0xFFEF4444);

  static List<Color> get hero => const [Color(0xFF2E63EB), Color(0xFF14B8A6)];
}

enum Tone { neutral, info, safe, attention, critical }

class ToneStyle {
  const ToneStyle({
    required this.background,
    required this.border,
    required this.foreground,
    required this.glyph,
  });

  final Color background;
  final Color border;
  final Color foreground;
  final String glyph;
}

Map<Tone, ToneStyle> get toneStyles => {
      Tone.neutral: ToneStyle(
        background: Palette.surfaceMuted,
        border: Palette.line,
        foreground: Palette.inkMuted,
        glyph: '•',
      ),
      Tone.info: ToneStyle(
        background: Palette.brandSoft,
        border: Palette._dark ? const Color(0x4D2E63EB) : const Color(0xFFD6E4FF),
        foreground: Palette._dark ? const Color(0xFF93B4FF) : const Color(0xFF1E40AF),
        glyph: 'i',
      ),
      Tone.safe: ToneStyle(
        background: Palette._dark ? const Color(0xFF0F2A20) : const Color(0xFFECFDF5),
        border: const Color(0x4D10B981),
        foreground: Palette._dark ? const Color(0xFF6EE7B7) : const Color(0xFF047857),
        glyph: '✓',
      ),
      Tone.attention: ToneStyle(
        background: Palette._dark ? const Color(0xFF332711) : const Color(0xFFFFFBEB),
        border: const Color(0x4DF59E0B),
        foreground: Palette._dark ? const Color(0xFFFCD34D) : const Color(0xFFB45309),
        glyph: '!',
      ),
      Tone.critical: ToneStyle(
        background: Palette._dark ? const Color(0xFF3A1414) : const Color(0xFFFEF2F2),
        border: const Color(0x4DEF4444),
        foreground: Palette._dark ? const Color(0xFFFCA5A5) : const Color(0xFFB91C1C),
        glyph: '!!',
      ),
    };

IconData findingIcon(String type) {
  switch (type) {
    case 'duplicate_active_ingredient':
      return Icons.content_copy;
    case 'unverified_medication':
      return Icons.help_outline;
    case 'interaction_check_unavailable':
      return Icons.science_outlined;
    case 'drug_interaction':
      return Icons.warning_amber_rounded;
    default:
      return Icons.error_outline;
  }
}

Tone findingTone(String severity) {
  switch (severity) {
    case 'high':
      return Tone.critical;
    case 'warning':
      return Tone.attention;
    default:
      return Tone.info;
  }
}

Tone safetyTone(String status) {
  switch (status) {
    case 'high':
      return Tone.critical;
    case 'warning':
      return Tone.attention;
    case 'attention':
      return Tone.info;
    default:
      return Tone.safe;
  }
}

Tone doseTone(String status) {
  switch (status) {
    case 'taken':
      return Tone.safe;
    case 'missed':
      return Tone.attention;
    case 'skipped':
      return Tone.neutral;
    default:
      return Tone.info;
  }
}

Tone verificationTone(String status) {
  return status.toLowerCase() == 'verified' ? Tone.safe : Tone.neutral;
}

Tone checkTone(String state) {
  switch (state) {
    case 'fail':
      return Tone.attention;
    case 'unknown':
      return Tone.neutral;
    default:
      return Tone.safe;
  }
}

String doseGlyph(String status) {
  switch (status) {
    case 'taken':
      return '✓';
    case 'missed':
      return '!';
    case 'skipped':
      return '—';
    default:
      return '•';
  }
}

String verificationGlyph(String status) => status.toLowerCase() == 'verified' ? '✓' : '?';
