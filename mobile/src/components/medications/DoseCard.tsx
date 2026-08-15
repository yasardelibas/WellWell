import { Ionicons } from '@expo/vector-icons';
import { Pressable, View } from 'react-native';

import { Badge } from '@/components/ui/Badge';
import { Text } from '@/components/ui/Text';
import { doseGlyph, doseTone } from '@/features/safety/presentation';
import { palette } from '@/theme/tokens';
import type { Dose } from '@/types/api';

export interface DoseCardProps {
  dose: Dose;
  onTaken?: () => void;
  onSkip?: () => void;
  onDetails?: () => void;
  busy?: boolean;
}

export function DoseCard({ dose, onTaken, onSkip, onDetails, busy = false }: DoseCardProps) {
  const actionable = dose.status === 'pending' || dose.status === 'snoozed';

  return (
    <View className="gap-3 rounded-3xl border border-line bg-surface p-4">
      <View className="flex-row items-start justify-between gap-3">
        <View className="flex-1 gap-1">
          <Text variant="caption">{dose.scheduledTime}</Text>
          <Text variant="heading">{dose.medicationName}</Text>
          <Text className="text-ink-muted">
            {[dose.strengthText, dose.doseAmountText].filter(Boolean).join(' · ') || 'Dose details on the label'}
          </Text>
        </View>
        <Badge label={dose.statusLabel} tone={doseTone(dose.status)} glyph={doseGlyph(dose.status)} />
      </View>

      {actionable && (onTaken || onSkip) ? (
        <View className="flex-row gap-2">
          {onTaken ? (
            <Pressable
              onPress={onTaken}
              disabled={busy}
              accessibilityRole="button"
              accessibilityLabel={`Mark ${dose.medicationName} as taken`}
              className="min-h-11 flex-1 flex-row items-center justify-center gap-1.5 rounded-2xl bg-brand-500 px-3 active:bg-brand-600"
            >
              <Ionicons name="checkmark" size={18} color="#FFFFFF" />
              <Text className="font-semibold text-white">Taken</Text>
            </Pressable>
          ) : null}
          {onSkip ? (
            <Pressable
              onPress={onSkip}
              disabled={busy}
              accessibilityRole="button"
              accessibilityLabel={`Skip ${dose.medicationName}`}
              className="min-h-11 flex-1 flex-row items-center justify-center gap-1.5 rounded-2xl border border-line px-3 active:bg-surface-muted"
            >
              <Ionicons name="remove" size={18} color={palette.inkMuted} />
              <Text className="font-semibold text-ink-muted">Skip</Text>
            </Pressable>
          ) : null}
          {onDetails ? (
            <Pressable
              onPress={onDetails}
              accessibilityRole="button"
              accessibilityLabel={`Open ${dose.medicationName} details`}
              className="min-h-11 items-center justify-center rounded-2xl border border-line px-3 active:bg-surface-muted"
            >
              <Ionicons name="chevron-forward" size={18} color={palette.inkMuted} />
            </Pressable>
          ) : null}
        </View>
      ) : null}

      {!actionable && dose.completedAt ? (
        <Text variant="caption">
          {dose.statusLabel} at {new Date(dose.completedAt).toLocaleTimeString(undefined, { hour: '2-digit', minute: '2-digit' })}
        </Text>
      ) : null}
    </View>
  );
}
