import { Ionicons } from '@expo/vector-icons';
import { View } from 'react-native';

import { Badge } from '@/components/ui/Badge';
import { Card } from '@/components/ui/Card';
import { Text } from '@/components/ui/Text';
import { checkLabel, checkTone, safetyTone } from '@/features/safety/presentation';
import { toneStyles } from '@/theme/tokens';
import { formatDateTime } from '@/utils/format';
import type { SafetyAnalysis } from '@/types/api';

/**
 * Renders the analysis exactly as the backend worded it. The UI never upgrades a result to
 * "safe": absence of findings only means the checks MedGuard can run found nothing.
 */
export function SafetySummary({ analysis }: { analysis: SafetyAnalysis }) {
  const tone = safetyTone(analysis.status);
  const style = toneStyles[tone];
  const clear = analysis.status === 'no_findings';

  return (
    <View className={`gap-3 rounded-3xl border p-5 ${style.container}`}>
      <View className="flex-row items-center gap-3">
        <Ionicons name={clear ? 'checkmark-circle-outline' : 'warning-outline'} size={26} color={style.color} />
        <Text className={`flex-1 text-lg font-semibold ${style.text}`} accessibilityRole="header">
          {analysis.headline}
        </Text>
      </View>
      <Text className={`text-sm ${style.text}`}>{analysis.subtext}</Text>
      <Text variant="caption">Last checked {formatDateTime(analysis.analyzedAt)}</Text>
    </View>
  );
}

export function SafetyChecks({ analysis }: { analysis: SafetyAnalysis }) {
  if (analysis.checks.length === 0) {
    return null;
  }

  return (
    <Card className="gap-3">
      <Text variant="heading">Checks MedGuard ran</Text>
      {analysis.checks.map((check, index) => (
        <View
          key={check.check}
          className={`gap-1 ${index < analysis.checks.length - 1 ? 'border-b border-line pb-3' : ''}`}
        >
          <View className="flex-row items-center justify-between gap-3">
            <Text className="flex-1 font-medium">{check.check}</Text>
            <Badge label={checkLabel(check.state)} tone={checkTone(check.state)} />
          </View>
          {check.detail ? <Text variant="caption">{check.detail}</Text> : null}
        </View>
      ))}
    </Card>
  );
}
