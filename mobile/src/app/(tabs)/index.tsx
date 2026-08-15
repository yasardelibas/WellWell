import { Ionicons } from '@expo/vector-icons';
import { useRouter } from 'expo-router';
import { useState } from 'react';
import { Pressable, View } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';

import { DoseCard } from '@/components/medications/DoseCard';
import { Badge } from '@/components/ui/Badge';
import { Button } from '@/components/ui/Button';
import { Card, SectionHeader } from '@/components/ui/Card';
import { EmptyState, ErrorState, LoadingState, Screen } from '@/components/ui/Screen';
import { Text } from '@/components/ui/Text';
import { useRecordDose, useToday } from '@/features/adherence/hooks';
import { useSafetyFindings } from '@/features/safety/hooks';
import { findingTone } from '@/features/safety/presentation';
import { describeError } from '@/services/api/client';
import { useAuthStore } from '@/store/auth';
import { palette } from '@/theme/tokens';
import { greeting } from '@/utils/format';

export default function Home() {
  const router = useRouter();
  const insets = useSafeAreaInsets();
  const user = useAuthStore((state) => state.user);
  const today = useToday();
  const findings = useSafetyFindings();
  const recordDose = useRecordDose();
  const [actionError, setActionError] = useState<string | null>(null);

  const doses = today.data?.doses ?? [];
  const upcoming = doses.filter((dose) => dose.status === 'pending' || dose.status === 'snoozed');
  const openFindings = findings.data ?? [];

  async function record(doseId: string, action: 'taken' | 'skipped') {
    setActionError(null);

    try {
      await recordDose.mutateAsync({ doseId, action });
    } catch (caught) {
      setActionError(describeError(caught));
    }
  }

  return (
    <Screen
      style={{ paddingTop: insets.top }}
      refreshing={today.isRefetching || findings.isRefetching}
      onRefresh={() => {
        void today.refetch();
        void findings.refetch();
      }}
    >
      <View className="flex-row items-start justify-between pt-2">
        <View className="flex-1">
          <Text variant="caption">{greeting()}</Text>
          <Text variant="title">{user?.displayName ?? 'Welcome'}</Text>
        </View>
        <Pressable
          onPress={() => router.push('/emergency')}
          accessibilityRole="button"
          accessibilityLabel="Open emergency card"
          className="h-11 w-11 items-center justify-center rounded-2xl border border-line bg-surface active:bg-surface-muted"
        >
          <Ionicons name="qr-code-outline" size={20} color={palette.ink} />
        </Pressable>
      </View>

      {openFindings.length > 0 ? (
        <Pressable
          onPress={() => router.push('/(tabs)/safety')}
          accessibilityRole="button"
          accessibilityLabel={`${openFindings.length} safety finding${openFindings.length === 1 ? '' : 's'} need review`}
          className="gap-2 rounded-3xl border border-attention-500/30 bg-attention-50 p-4 active:opacity-80"
        >
          <View className="flex-row items-center gap-2">
            <Ionicons name="alert-circle-outline" size={20} color={palette.attention} />
            <Text className="flex-1 font-semibold text-attention-700">
              {openFindings.length === 1 ? '1 safety finding to review' : `${openFindings.length} safety findings to review`}
            </Text>
            <Ionicons name="chevron-forward" size={18} color={palette.attention} />
          </View>
          <Text className="text-sm text-attention-700">{openFindings[0]?.title}</Text>
          <View className="flex-row gap-2">
            {openFindings.slice(0, 2).map((finding) => (
              <Badge key={finding.id} label={finding.severity === 'high' ? 'High priority' : 'Needs attention'} tone={findingTone(finding.severity)} />
            ))}
          </View>
        </Pressable>
      ) : null}

      <Card className="gap-3">
        <SectionHeader title="Today's adherence" />
        {today.isPending ? (
          <LoadingState label="Loading today's plan" />
        ) : (
          <>
            <Text className="text-ink-muted">{today.data?.progressLabel ?? 'No doses are scheduled for today.'}</Text>
            <ProgressBar completed={today.data?.completedCount ?? 0} total={today.data?.totalCount ?? 0} />
            <View className="flex-row gap-2">
              <Badge label={`${today.data?.completedCount ?? 0} completed`} tone="safe" glyph="✓" />
              <Badge label={`${upcoming.length} pending`} tone="info" glyph="•" />
            </View>
          </>
        )}
      </Card>

      <View>
        <SectionHeader
          title="Today's medications"
          action={
            <Pressable onPress={() => router.push('/history')} accessibilityRole="button" accessibilityLabel="Open history">
              <Text className="font-semibold text-brand-600">History</Text>
            </Pressable>
          }
        />

        {today.isPending ? (
          <LoadingState />
        ) : today.isError ? (
          <ErrorState message={describeError(today.error)} onRetry={() => void today.refetch()} />
        ) : doses.length === 0 ? (
          <EmptyState
            icon="alarm-outline"
            title="No reminders yet"
            description="Add a medication and confirm its reminder times to see your day here."
            action={<Button label="Scan a medication" size="md" onPress={() => router.push('/(tabs)/scan')} />}
          />
        ) : (
          <View className="gap-3">
            {doses.map((dose) => (
              <DoseCard
                key={dose.id}
                dose={dose}
                busy={recordDose.isPending}
                onTaken={() => void record(dose.id, 'taken')}
                onSkip={() => void record(dose.id, 'skipped')}
                onDetails={() => router.push(`/medication/${dose.medicationId}`)}
              />
            ))}
          </View>
        )}

        {actionError ? <Text className="mt-3 text-sm text-critical-700">{actionError}</Text> : null}
      </View>

      <Card className="gap-3">
        <Text variant="heading">Add a medication</Text>
        <Text className="text-ink-muted">
          Scan the label to read the name and active ingredients, then confirm the details before it is saved.
        </Text>
        <View className="flex-row gap-3">
          <Button label="Scan label" size="md" className="flex-1" onPress={() => router.push('/(tabs)/scan')} />
          <Button
            label="Enter manually"
            variant="secondary"
            size="md"
            className="flex-1"
            onPress={() => router.push('/medication/new')}
          />
        </View>
      </Card>
    </Screen>
  );
}

function ProgressBar({ completed, total }: { completed: number; total: number }) {
  const ratio = total === 0 ? 0 : Math.min(1, completed / total);

  return (
    <View
      className="h-2.5 w-full overflow-hidden rounded-full bg-surface-muted"
      accessibilityRole="progressbar"
      accessibilityValue={{ min: 0, max: total, now: completed }}
    >
      <View className="h-full rounded-full bg-safe-500" style={{ width: `${ratio * 100}%` }} />
    </View>
  );
}
