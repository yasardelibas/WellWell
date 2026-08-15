import 'package:flutter/material.dart';

class Palette {
  static const canvas = Color(0xFFF9FAFB);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceMuted = Color(0xFFF3F4F6);
  static const ink = Color(0xFF1F2937);
  static const inkMuted = Color(0xFF6B7280);
  static const inkSubtle = Color(0xFF9CA3AF);
  static const line = Color(0xFFE5E7EB);
  static const brand = Color(0xFF2E63EB);
  static const brandDark = Color(0xFF1E4ED8);
  static const brandSoft = Color(0xFFEBF1FF);
  static const teal = Color(0xFF14B8A6);
  static const safe = Color(0xFF10B981);
  static const attention = Color(0xFFF59E0B);
  static const critical = Color(0xFFEF4444);

  static const hero = [Color(0xFF2E63EB), Color(0xFF14B8A6)];
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

const toneStyles = {
  Tone.neutral: ToneStyle(
    background: Palette.surfaceMuted,
    border: Palette.line,
    foreground: Palette.inkMuted,
    glyph: '•',
  ),
  Tone.info: ToneStyle(
    background: Palette.brandSoft,
    border: Color(0xFFD6E4FF),
    foreground: Color(0xFF1E40AF),
    glyph: 'i',
  ),
  Tone.safe: ToneStyle(
    background: Color(0xFFECFDF5),
    border: Color(0x4D10B981),
    foreground: Color(0xFF047857),
    glyph: '✓',
  ),
  Tone.attention: ToneStyle(
    background: Color(0xFFFFFBEB),
    border: Color(0x4DF59E0B),
    foreground: Color(0xFFB45309),
    glyph: '!',
  ),
  Tone.critical: ToneStyle(
    background: Color(0xFFFEF2F2),
    border: Color(0x4DEF4444),
    foreground: Color(0xFFB91C1C),
    glyph: '!!',
  ),
};

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

