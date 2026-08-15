import { Ionicons } from '@expo/vector-icons';
import { useLocalSearchParams } from 'expo-router';
import { View } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';

import { Badge } from '@/components/ui/Badge';
import { Card, FieldRow } from '@/components/ui/Card';
import { Callout } from '@/components/ui/Callout';
import { BackLink, ErrorState, LoadingState, Screen } from '@/components/ui/Screen';
import { Text } from '@/components/ui/Text';
import { useSafetyExplanation, useSafetyFindings } from '@/features/safety/hooks';
import { findingTone } from '@/features/safety/presentation';
import { describeError } from '@/services/api/client';
import { palette } from '@/theme/tokens';
import { formatDateTime } from '@/utils/format';

export default function WhyAmISeeingThis() {
  const insets = useSafeAreaInsets();
  const { id } = useLocalSearchParams<{ id: string }>();
  const findings = useSafetyFindings();
  const explanation = useSafetyExplanation(id);

  const finding = (findings.data ?? []).find((item) => item.id === id);

  if (findings.isPending) {
    return (
      <Screen style={{ paddingTop: insets.top }}>
        <BackLink label="Safety" />
        <LoadingState />
      </Screen>
    );
  }

  if (!finding) {
    return (
      <Screen style={{ paddingTop: insets.top }}>
        <BackLink label="Safety" />
        <ErrorState message="This safety finding is no longer available." onRetry={() => void findings.refetch()} />
      </Screen>
    );
  }

  return (
    <Screen style={{ paddingTop: insets.top }}>
      <BackLink label="Safety" />

      <View className="gap-1">
        <Text variant="title">Why MedGuard flagged this</Text>
        <Text className="text-ink-muted">{finding.title}</Text>
      </View>

      <Card className="gap-3">
        <Text variant="heading">The saved facts behind this finding</Text>

        {finding.medications.map((medication, index) => (
          <View key={medication.id} className="gap-1">
            <View className="flex-row items-center gap-2">
              <Ionicons name="ellipse" size={8} color={palette.brand} />
              <Text className="flex-1 font-semibold">{medication.name}</Text>
              <Badge label={medication.verified ? 'Verified' : 'Unverified'} tone={medication.verified ? 'safe' : 'neutral'} glyph={medication.verified ? '✓' : '?'} />
            </View>
            <Text className="pl-4 text-ink-muted">
              contains {medication.ingredientOriginalName ?? finding.ingredient?.name ?? 'this ingredient'}
              {medication.strengthText ? ` · ${medication.strengthText}` : ''}
            </Text>
            {index < finding.medications.length - 1 ? <Text variant="caption" className="pl-4">and</Text> : null}
          </View>
        ))}

        {finding.ingredient ? (
          <Text className="text-ink-muted">
            MedGuard normalises ingredient names before comparing them, so both products resolve to the same active
            ingredient: <Text className="font-semibold">{finding.ingredient.name}</Text>
            {finding.ingredient.identifier
              ? ` (${finding.ingredient.identifierSystem ?? 'identifier'} ${finding.ingredient.identifier})`
              : ''}
            .
          </Text>
        ) : null}
      </Card>

      <Card className="gap-1">
        <Text variant="heading" className="mb-2">
          Provenance
        </Text>
        <FieldRow label="Data source" value={finding.source} />
        <FieldRow label="Dataset version" value={finding.datasetVersion} />
        <FieldRow label="Last checked" value={formatDateTime(finding.detectedAt)} />
        <FieldRow
          label="Verification"
          value={finding.verified ? 'Verified against trusted data' : 'Not independently verified'}
          divider={false}
        />
      </Card>

      <Card className="gap-3">
        <View className="flex-row items-center justify-between gap-2">
          <Text variant="heading">In plain language</Text>
          <Badge
            label={explanation.data?.generatedByAi ? 'AI explanation' : 'Standard explanation'}
            tone="info"
            glyph="i"
          />
        </View>

        {explanation.isPending ? (
          <LoadingState label="Preparing the explanation" />
        ) : explanation.isError ? (
          <Text className="text-ink-muted">
            The explanation is unavailable right now. The finding above stays available and unchanged.
          </Text>
        ) : (
          <>
            <Text>{explanation.data?.explanation}</Text>
            <Text variant="caption">Explanation source: {explanation.data?.source}</Text>
          </>
        )}
      </Card>

      <Callout
        tone={findingTone(finding.severity)}
        title="What to do next"
        message={
          explanation.data?.disclaimer ??
          'Review the medication labels and confirm with a pharmacist or healthcare professional if you are unsure.'
        }
      />

      {findings.isError ? <Text className="text-sm text-critical-700">{describeError(findings.error)}</Text> : null}
    </Screen>
  );
}
