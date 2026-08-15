import type { Tone } from '@/theme/tokens';
import type { Dose, Medication, SafetyAnalysis, SafetyFinding } from '@/types/api';

export function safetyTone(status: SafetyAnalysis['status']): Tone {
  switch (status) {
    case 'high':
      return 'critical';
    case 'warning':
      return 'attention';
    case 'attention':
      return 'info';
    default:
      return 'safe';
  }
}

export function findingTone(severity: SafetyFinding['severity']): Tone {
  switch (severity) {
    case 'high':
      return 'critical';
    case 'warning':
      return 'attention';
    default:
      return 'info';
  }
}

export function verificationTone(status: Medication['verificationStatus']): Tone {
  switch (status) {
    case 'verified':
      return 'safe';
    case 'verification_unavailable':
      return 'attention';
    default:
      return 'neutral';
  }
}

export function verificationGlyph(status: Medication['verificationStatus']): string {
  return status === 'verified' ? '✓' : '?';
}

export function doseTone(status: Dose['status']): Tone {
  switch (status) {
    case 'taken':
      return 'safe';
    case 'missed':
      return 'attention';
    case 'skipped':
      return 'neutral';
    case 'snoozed':
      return 'info';
    default:
      return 'info';
  }
}

export function doseGlyph(status: Dose['status']): string {
  switch (status) {
    case 'taken':
      return '✓';
    case 'missed':
      return '!';
    case 'skipped':
      return '—';
    case 'snoozed':
      return '⏱';
    default:
      return '•';
  }
}

export function checkLabel(state: string): string {
  switch (state) {
    case 'completed':
      return 'Checked';
    case 'unavailable':
      return 'Unavailable';
    case 'not_configured':
      return 'Not available';
    default:
      return 'Skipped';
  }
}

export function checkTone(state: string): Tone {
  switch (state) {
    case 'completed':
      return 'safe';
    case 'unavailable':
      return 'attention';
    default:
      return 'neutral';
  }
}
