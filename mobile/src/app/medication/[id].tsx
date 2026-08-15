import { Ionicons } from '@expo/vector-icons';
import { useLocalSearchParams, useRouter } from 'expo-router';
import { useState } from 'react';
import { Alert, View } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';

import { Badge } from '@/components/ui/Badge';
import { Button } from '@/components/ui/Button';
import { Callout } from '@/components/ui/Callout';
import { Card, FieldRow } from '@/components/ui/Card';
import { BackLink, ErrorState, LoadingState, Screen } from '@/components/ui/Screen';
import { Text } from '@/components/ui/Text';
import { useDeleteMedication, useMedication } from '@/features/medications/hooks';
import { verificationGlyph, verificationTone } from '@/features/safety/presentation';
import { useSchedules } from '@/features/schedules/hooks';
import { describeError } from '@/services/api/client';
import { palette } from '@/theme/tokens';
import { formatDateTime } from '@/utils/format';

export default function MedicationDetail() {
  const router = useRouter();
  const insets = useSafeAreaInsets();
  const { id } = useLocalSearchParams<{ id: string }>();
  const medication = useMedication(id);
  const schedules = useSchedules(id);
  const remove = useDeleteMedication();
  const [error, setError] = useState<string | null>(null);

  function confirmRemoval() {
    Alert.alert(
      'Remove this medication?',
      'It will no longer appear in your list, reminders or safety checks. Your dose history stays intact.',
      [
        { text: 'Keep it', style: 'cancel' },
        {
          text: 'Remove',
          style: 'destructive',
          onPress: () => {
            void (async () => {
              setError(null);

              try {
                await remove.mutateAsync(id);
                router.replace('/(tabs)/medications');
              } catch (caught) {
                setError(describeError(caught));
              }
            })();
          },
        },
      ],
    );
  }

  if (medication.isPending) {
    return (
      <Screen style={{ paddingTop: insets.top }}>
        <BackLink label="Medications" />
        <LoadingState />
      </Screen>
    );
  }

  if (medication.isError || !medication.data) {
    return (
      <Screen style={{ paddingTop: insets.top }}>
        <BackLink label="Medications" />
        <ErrorState message={describeError(medication.error)} onRetry={() => void medication.refetch()} />
      </Screen>
    );
  }

  const item = medication.data;
  const activeSchedules = (schedules.data ?? []).filter((schedule) => schedule.isActive);

  return (
    <Screen style={{ paddingTop: insets.top }} refreshing={medication.isRefetching} onRefresh={() => void medication.refetch()}>
      <BackLink label="Medications" />

      <View className="gap-2">
        <Text variant="title">{item.displayName}</Text>
        <View className="flex-row flex-wrap gap-2">
          <Badge
            label={item.verificationLabel}
            tone={verificationTone(item.verificationStatus)}
            glyph={verificationGlyph(item.verificationStatus)}
          />
          {item.dosageForm ? <Badge label={item.dosageForm} tone="neutral" glyph="•" /> : null}
        </View>
      </View>

      {item.verificationStatus !== 'verified' ? (
        <Callout
          tone="attention"
          title="Not independently verified"
          message="MedGuard could not match this product against its medication data source. Check the label carefully; duplicate ingredient checks still run on what you entered."
        />
      ) : null}

      <Card className="gap-3">
        <Text variant="heading">Active ingredients</Text>
        {item.ingredients.length === 0 ? (
          <Text className="text-ink-muted">No active ingredients are recorded for this medication.</Text>
        ) : (
          item.ingredients.map((ingredient, index) => (
            <View
              key={ingredient.id}
              className={`gap-0.5 ${index < item.ingredients.length - 1 ? 'border-b border-line pb-3' : ''}`}
            >
              <Text className="font-semibold">{ingredient.normalizedName}</Text>
              <Text className="text-ink-muted">
                {ingredient.displayStrength || 'Strength not recorded'} · printed as “{ingredient.originalName}”
              </Text>
              {ingredient.rxCui ? <Text variant="caption">RxNorm identifier {ingredient.rxCui}</Text> : null}
            </View>
          ))
        )}
      </Card>

      <Card className="gap-1">
        <Text variant="heading" className="mb-2">
          Label information
        </Text>
        <FieldRow label="Brand" value={item.brandName} />
        <FieldRow label="Generic name" value={item.genericName} />
        <FieldRow label="Strength" value={item.strength} />
        <FieldRow label="Route" value={item.route} />
        <FieldRow label="Directions" value={item.labelDirections} />
        <FieldRow label="Manufacturer" value={item.manufacturer} />
        <FieldRow label="Notes" value={item.notes} divider={false} />
      </Card>

      <Card className="gap-1">
        <Text variant="heading" className="mb-2">
          Source
        </Text>
        <FieldRow label="Provider" value={item.provenance?.provider ?? 'Entered manually'} />
        <FieldRow label="Identifier" value={item.provenance?.externalIdentifier ?? item.rxCui} />
        <FieldRow label="Dataset version" value={item.provenance?.datasetVersion} />
        <FieldRow
          label="Last verified"
          value={item.provenance ? formatDateTime(item.provenance.retrievedAt) : 'Not verified'}
          divider={false}
        />
      </Card>

      <Card className="gap-3">
        <View className="flex-row items-center justify-between gap-2">
          <Text variant="heading">Reminders</Text>
          <Badge label={`${activeSchedules.length} active`} tone={activeSchedules.length > 0 ? 'info' : 'neutral'} glyph="⏰" />
        </View>

        {activeSchedules.length === 0 ? (
          <Text className="text-ink-muted">
            No reminders yet. Reminder times are only suggestions from the label until you confirm them.
          </Text>
        ) : (
          <View className="flex-row flex-wrap gap-2">
            {activeSchedules.map((schedule) => (
              <View key={schedule.id} className="rounded-xl bg-surface-muted px-3 py-2">
                <Text className="font-semibold">{schedule.time}</Text>
              </View>
            ))}
          </View>
        )}

        <Button
          label={activeSchedules.length === 0 ? 'Set up reminders' : 'Edit reminders'}
          variant="secondary"
          size="md"
          icon={<Ionicons name="alarm-outline" size={18} color={palette.ink} />}
          onPress={() => router.push(`/schedule/${item.id}`)}
        />
      </Card>

      {error ? <Text className="text-sm text-critical-700">{error}</Text> : null}

      <View className="gap-3">
        <Button
          label="View dose history"
          variant="secondary"
          onPress={() => router.push({ pathname: '/history', params: { medicationId: item.id } })}
        />
        <Button label="Remove medication" variant="danger" loading={remove.isPending} onPress={confirmRemoval} />
      </View>
    </Screen>
  );
}
