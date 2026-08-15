import { Ionicons } from '@expo/vector-icons';
import { useRouter } from 'expo-router';
import { View } from 'react-native';

import { Badge } from '@/components/ui/Badge';
import { Button } from '@/components/ui/Button';
import { Text } from '@/components/ui/Text';
import { findingTone } from '@/features/safety/presentation';
import { toneStyles } from '@/theme/tokens';
import { formatDateTime } from '@/utils/format';
import type { SafetyFinding } from '@/types/api';

const severityLabels: Record<string, string> = {
  high: 'High priority',
  warning: 'Needs attention',
  info: 'Information',
};

export function FindingCard({ finding, showActions = true }: { finding: SafetyFinding; showActions?: boolean }) {
  const router = useRouter();
  const tone = findingTone(finding.severity);
  const style = toneStyles[tone];

  return (
    <View className={`gap-3 rounded-3xl border p-4 ${style.container}`}>
      <View className="flex-row items-start gap-2">
        <Ionicons
          name={finding.severity === 'info' ? 'information-circle-outline' : 'alert-circle-outline'}
          size={22}
          color={style.color}
        />
        <View className="flex-1 gap-1">
          <Text className={`text-base font-semibold ${style.text}`} accessibilityRole="header">
            {finding.title}
          </Text>
          <Badge label={severityLabels[finding.severity] ?? 'Information'} tone={tone} />
        </View>
      </View>

      <Text className={`text-sm ${style.text}`}>{finding.message}</Text>

      {finding.ingredient ? (
        <View className="gap-2 rounded-2xl bg-surface/70 p-3">
          <Text variant="label">Both products contain</Text>
          <Text variant="heading">{finding.ingredient.name}</Text>
          {finding.medications.map((medication) => (
            <View key={`${finding.id}-${medication.id}`} className="flex-row items-center justify-between gap-3">
              <Text className="flex-1">{medication.name}</Text>
              <Text className="text-ink-muted">{medication.strengthText ?? '—'}</Text>
            </View>
          ))}
        </View>
      ) : null}

      <Text variant="caption">
        Source: {finding.source}
        {finding.datasetVersion ? ` · dataset ${finding.datasetVersion}` : ''} · Detected {formatDateTime(finding.detectedAt)}
      </Text>

      {showActions ? (
        <View className="gap-2">
          <Button label="View medications" variant="secondary" size="md" onPress={() => router.push('/(tabs)/medications')} />
          <Button
            label="Why am I seeing this?"
            variant="ghost"
            size="md"
            onPress={() => router.push(`/safety/${finding.id}`)}
          />
        </View>
      ) : null}
    </View>
  );
}
