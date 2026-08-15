import { useRouter } from 'expo-router';
import { View } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';

import { FindingCard } from '@/components/safety/FindingCard';
import { SafetyChecks, SafetySummary } from '@/components/safety/SafetySummary';
import { Badge } from '@/components/ui/Badge';
import { Button } from '@/components/ui/Button';
import { Card, FieldRow } from '@/components/ui/Card';
import { Callout } from '@/components/ui/Callout';
import { Screen } from '@/components/ui/Screen';
import { Text } from '@/components/ui/Text';
import { verificationGlyph, verificationTone } from '@/features/safety/presentation';
import { useScanStore } from '@/features/scanner/store';

export default function ScanResult() {
  const router = useRouter();
  const insets = useSafeAreaInsets();
  const outcome = useScanStore((state) => state.outcome);
  const clear = useScanStore((state) => state.clear);

  if (!outcome) {
    return (
      <Screen style={{ paddingTop: insets.top }}>
        <Callout tone="info" title="Nothing to show" message="Scan and confirm a medication to see its safety result." />
        <Button label="Open the scanner" onPress={() => router.replace('/(tabs)/scan')} />
      </Screen>
    );
  }

  const { medication, safety, scheduleSuggestion } = outcome;

  function done() {
    clear();
    router.replace('/(tabs)');
  }

  return (
    <Screen style={{ paddingTop: insets.top }}>
      <View className="gap-1 pt-2">
        <Text variant="title">{medication.displayName} was saved</Text>
        <Text className="text-ink-muted">MedGuard checked it against the medications already in your list.</Text>
      </View>

      <SafetySummary analysis={safety} />

      {safety.findings.map((finding) => (
        <FindingCard key={finding.id} finding={finding} />
      ))}

      <Card className="gap-1">
        <View className="mb-2 flex-row items-center justify-between gap-3">
          <Text variant="heading">Saved medication</Text>
          <Badge
            label={medication.verificationLabel}
            tone={verificationTone(medication.verificationStatus)}
            glyph={verificationGlyph(medication.verificationStatus)}
          />
        </View>
        <FieldRow label="Brand" value={medication.brandName} />
        <FieldRow label="Generic name" value={medication.genericName} />
        <FieldRow
          label="Active ingredients"
          value={medication.ingredients.map((ingredient) => `${ingredient.normalizedName} ${ingredient.displayStrength}`.trim()).join('\n')}
        />
        <FieldRow label="Label directions" value={medication.labelDirections} divider={false} />
      </Card>

      <SafetyChecks analysis={safety} />

      <View className="gap-3">
        {scheduleSuggestion ? (
          <Button
            label="Create reminders from the label"
            onPress={() => router.replace(`/schedule/${medication.id}`)}
          />
        ) : null}
        <Button
          label="View medication"
          variant="secondary"
          onPress={() => router.replace(`/medication/${medication.id}`)}
        />
        <Button label="Back to home" variant="ghost" onPress={done} />
      </View>
    </Screen>
  );
}
