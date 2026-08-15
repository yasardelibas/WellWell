import { Ionicons } from '@expo/vector-icons';
import { useRouter } from 'expo-router';
import { View } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';

import { Badge } from '@/components/ui/Badge';
import { Button } from '@/components/ui/Button';
import { PressableCard } from '@/components/ui/Card';
import { EmptyState, ErrorState, LoadingState, Screen, ScreenHeader } from '@/components/ui/Screen';
import { Text } from '@/components/ui/Text';
import { useMedications } from '@/features/medications/hooks';
import { verificationGlyph, verificationTone } from '@/features/safety/presentation';
import { describeError } from '@/services/api/client';
import { palette } from '@/theme/tokens';

export default function Medications() {
  const router = useRouter();
  const insets = useSafeAreaInsets();
  const medications = useMedications();

  return (
    <Screen
      style={{ paddingTop: insets.top }}
      refreshing={medications.isRefetching}
      onRefresh={() => void medications.refetch()}
    >
      <ScreenHeader
        title="Medications"
        subtitle="Everything you have confirmed and saved in MedGuard."
        action={
          <Button
            label="Add"
            size="md"
            icon={<Ionicons name="add" size={18} color="#FFFFFF" />}
            onPress={() => router.push('/medication/new')}
          />
        }
      />

      {medications.isPending ? (
        <LoadingState label="Loading your medications" />
      ) : medications.isError ? (
        <ErrorState message={describeError(medications.error)} onRetry={() => void medications.refetch()} />
      ) : (medications.data ?? []).length === 0 ? (
        <EmptyState
          icon="medkit-outline"
          title="No medications yet"
          description="Scan a label or add the details manually. Nothing is saved until you confirm it."
          action={<Button label="Scan a medication" size="md" onPress={() => router.push('/(tabs)/scan')} />}
        />
      ) : (
        <View className="gap-3">
          {(medications.data ?? []).map((medication) => (
            <PressableCard
              key={medication.id}
              accessibilityLabel={`${medication.displayName}, ${medication.verificationLabel}`}
              accessibilityHint="Opens the medication details"
              onPress={() => router.push(`/medication/${medication.id}`)}
              className="gap-2"
            >
              <View className="flex-row items-start justify-between gap-3">
                <View className="flex-1 gap-1">
                  <Text variant="heading">{medication.displayName}</Text>
                  <Text className="text-ink-muted">
                    {medication.ingredients.map((ingredient) => ingredient.normalizedName).join(', ') ||
                      'No active ingredients recorded'}
                  </Text>
                </View>
                <Ionicons name="chevron-forward" size={18} color={palette.inkSubtle} />
              </View>

              <View className="flex-row flex-wrap items-center gap-2">
                <Badge
                  label={medication.verificationStatus === 'verified' ? 'Verified' : 'Unverified'}
                  tone={verificationTone(medication.verificationStatus)}
                  glyph={verificationGlyph(medication.verificationStatus)}
                />
                {medication.strength ? <Badge label={medication.strength} tone="neutral" glyph="•" /> : null}
                <Badge
                  label={
                    medication.activeScheduleCount === 0
                      ? 'No reminders'
                      : `${medication.activeScheduleCount} reminder${medication.activeScheduleCount === 1 ? '' : 's'}`
                  }
                  tone={medication.activeScheduleCount === 0 ? 'neutral' : 'info'}
                  glyph="⏰"
                />
              </View>
            </PressableCard>
          ))}
        </View>
      )}
    </Screen>
  );
}
