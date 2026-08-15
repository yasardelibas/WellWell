import { useLocalSearchParams } from 'expo-router';
import { useState } from 'react';
import { Pressable, ScrollView, View } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';

import { Badge } from '@/components/ui/Badge';
import { Card } from '@/components/ui/Card';
import { BackLink, EmptyState, ErrorState, LoadingState, Screen } from '@/components/ui/Screen';
import { Text } from '@/components/ui/Text';
import { useAdherenceHistory } from '@/features/adherence/hooks';
import { useMedications } from '@/features/medications/hooks';
import { doseGlyph, doseTone } from '@/features/safety/presentation';
import { describeError } from '@/services/api/client';
import { formatDate, isToday } from '@/utils/format';

export default function History() {
  const insets = useSafeAreaInsets();
  const params = useLocalSearchParams<{ medicationId?: string }>();
  const [filter, setFilter] = useState<string | undefined>(params.medicationId);
  const medications = useMedications();
  const history = useAdherenceHistory(filter);

  const data = history.data;

  return (
    <Screen style={{ paddingTop: insets.top }} refreshing={history.isRefetching} onRefresh={() => void history.refetch()}>
      <BackLink />

      <View className="gap-1">
        <Text variant="title">Dose history</Text>
        <Text className="text-ink-muted">Completed, skipped and missed doses over the last two weeks.</Text>
      </View>

      <ScrollView horizontal showsHorizontalScrollIndicator={false} contentContainerStyle={{ gap: 8, paddingVertical: 4 }}>
        <FilterChip label="All medications" active={filter === undefined} onPress={() => setFilter(undefined)} />
        {(medications.data ?? []).map((medication) => (
          <FilterChip
            key={medication.id}
            label={medication.displayName}
            active={filter === medication.id}
            onPress={() => setFilter(medication.id)}
          />
        ))}
      </ScrollView>

      {history.isPending ? (
        <LoadingState label="Loading your history" />
      ) : history.isError ? (
        <ErrorState message={describeError(history.error)} onRetry={() => void history.refetch()} />
      ) : data ? (
        <>
          <Card className="gap-3">
            <Text variant="heading">Summary</Text>
            <View className="flex-row flex-wrap gap-2">
              <Badge label={`${data.takenCount} taken`} tone="safe" glyph="✓" />
              <Badge label={`${data.skippedCount} skipped`} tone="neutral" glyph="—" />
              <Badge label={`${data.missedCount} missed`} tone="attention" glyph="!" />
              <Badge label={`${data.pendingCount} pending`} tone="info" glyph="•" />
            </View>
            <Text variant="caption">
              These counts describe what happened, not how well you did. Talk to your healthcare professional if a
              pattern concerns you.
            </Text>
          </Card>

          {data.days.length === 0 ? (
            <EmptyState
              icon="calendar-outline"
              title="No doses recorded yet"
              description="Once reminders are confirmed, every taken, skipped or missed dose appears here."
            />
          ) : (
            <View className="gap-4">
              {data.days.map((day) => (
                <View key={day.date} className="gap-2">
                  <Text variant="label">
                    {isToday(day.date) ? 'Today' : formatDate(day.date)}
                  </Text>
                  <Card className="gap-3">
                    {day.doses.map((dose, index) => (
                      <View
                        key={dose.id}
                        className={`flex-row items-center gap-3 ${
                          index < day.doses.length - 1 ? 'border-b border-line pb-3' : ''
                        }`}
                      >
                        <Text className="w-14 font-semibold">{dose.scheduledTime}</Text>
                        <View className="flex-1">
                          <Text className="font-medium">{dose.medicationName}</Text>
                          {dose.doseAmountText ? <Text variant="caption">{dose.doseAmountText}</Text> : null}
                        </View>
                        <Badge label={dose.statusLabel} tone={doseTone(dose.status)} glyph={doseGlyph(dose.status)} />
                      </View>
                    ))}
                  </Card>
                </View>
              ))}
            </View>
          )}
        </>
      ) : null}
    </Screen>
  );
}

function FilterChip({ label, active, onPress }: { label: string; active: boolean; onPress: () => void }) {
  return (
    <Pressable
      onPress={onPress}
      accessibilityRole="button"
      accessibilityState={{ selected: active }}
      accessibilityLabel={`Filter by ${label}`}
      className={`min-h-10 justify-center rounded-full border px-4 ${
        active ? 'border-brand-500 bg-brand-50' : 'border-line bg-surface'
      }`}
    >
      <Text className={`text-sm font-semibold ${active ? 'text-brand-700' : 'text-ink-muted'}`}>{label}</Text>
    </Pressable>
  );
}
