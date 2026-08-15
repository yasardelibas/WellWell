/**
 * Colour values that also exist in global.css. Kept here for the few places that need a
 * raw value (icons, native components, QR rendering) rather than a Tailwind class.
 */
export const palette = {
  canvas: '#F6F8FB',
  surface: '#FFFFFF',
  surfaceMuted: '#EEF2F7',
  ink: '#0F172A',
  inkMuted: '#475569',
  inkSubtle: '#64748B',
  line: '#DBE3EC',
  brand: '#2F6FED',
  brandDark: '#1F57C9',
  safe: '#0F9D63',
  attention: '#C07806',
  critical: '#C2352B',
} as const;

/** Severity always travels with an icon and a written label, never colour alone. */
export type Tone = 'neutral' | 'info' | 'safe' | 'attention' | 'critical';

export const toneStyles: Record<Tone, { container: string; text: string; icon: string; color: string }> = {
  neutral: {
    container: 'bg-surface-muted border-line',
    text: 'text-ink-muted',
    icon: '•',
    color: palette.inkMuted,
  },
  info: {
    container: 'bg-brand-50 border-brand-100',
    text: 'text-brand-700',
    icon: 'i',
    color: palette.brand,
  },
  safe: {
    container: 'bg-safe-50 border-safe-500/30',
    text: 'text-safe-700',
    icon: '✓',
    color: palette.safe,
  },
  attention: {
    container: 'bg-attention-50 border-attention-500/30',
    text: 'text-attention-700',
    icon: '!',
    color: palette.attention,
  },
  critical: {
    container: 'bg-critical-50 border-critical-500/30',
    text: 'text-critical-700',
    icon: '!!',
    color: palette.critical,
  },
};
