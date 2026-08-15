import { useRouter } from 'expo-router';
import { useState } from 'react';
import { View } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';

import { FindingCard } from '@/components/safety/FindingCard';
import { SafetyChecks, SafetySummary } from '@/components/safety/SafetySummary';
import { Button } from '@/components/ui/Button';
import { Callout } from '@/components/ui/Callout';
import { ErrorState, LoadingState, Screen, ScreenHeader } from '@/components/ui/Screen';
import { Text } from '@/components/ui/Text';
import { useRunSafetyAnalysis, useSafetyAnalysis } from '@/features/safety/hooks';
import { describeError } from '@/services/api/client';

export default function Safety() {
  const router = useRouter();
  const insets = useSafeAreaInsets();
  const analysis = useSafetyAnalysis();
  const runAnalysis = useRunSafetyAnalysis();
  const [error, setError] = useState<string | null>(null);

  async function recheck() {
    setError(null);

    try {
      await runAnalysis.mutateAsync(undefined);
    } catch (caught) {
      setError(describeError(caught));
    }
  }

  const data = analysis.data;

  return (
    <Screen style={{ paddingTop: insets.top }} refreshing={analysis.isRefetching} onRefresh={() => void analysis.refetch()}>
      <ScreenHeader title="Safety" subtitle="Deterministic checks across the medications saved in MedGuard." />

      {analysis.isPending ? (
        <LoadingState label="Running the safety checks" />
      ) : analysis.isError ? (
        <ErrorState message={describeError(analysis.error)} onRetry={() => void analysis.refetch()} />
      ) : data ? (
        <>
          <SafetySummary analysis={data} />

          {data.findings.length > 0 ? (
            <View className="gap-3">
              {data.findings.map((finding) => (
                <FindingCard key={finding.id} finding={finding} />
              ))}
            </View>
          ) : (
            <Callout
              tone="info"
              title="Unknown does not mean safe"
              message="MedGuard can only report what its current checks and data sources cover. Always read the label and ask a pharmacist if something is unclear."
            />
          )}

          <SafetyChecks analysis={data} />
        </>
      ) : null}

      {error ? <Text className="text-sm text-critical-700">{error}</Text> : null}

      <View className="gap-3">
        <Button label="Run the checks again" loading={runAnalysis.isPending} onPress={() => void recheck()} />
        <Button label="View medications" variant="secondary" onPress={() => router.push('/(tabs)/medications')} />
      </View>
    </Screen>
  );
}
