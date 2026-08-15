import { Ionicons } from '@expo/vector-icons';
import { useLocalSearchParams, useRouter } from 'expo-router';
import { useMemo, useState } from 'react';
import { Platform, Pressable, TextInput, View } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';

import { Button } from '@/components/ui/Button';
import { Callout } from '@/components/ui/Callout';
import { Card } from '@/components/ui/Card';
import { BackLink, LoadingState, Screen } from '@/components/ui/Screen';
import { Text } from '@/components/ui/Text';
import { useMedication } from '@/features/medications/hooks';
import { useSaveSchedule, useScheduleSuggestion, useSchedules } from '@/features/schedules/hooks';
import { describeError } from '@/services/api/client';
import { palette } from '@/theme/tokens';

const timePattern = /^([01]\d|2[0-3]):([0-5]\d)$/;

export default function ScheduleEditor() {
  const router = useRouter();
  const insets = useSafeAreaInsets();
  const { medicationId } = useLocalSearchParams<{ medicationId: string }>();

  const medication = useMedication(medicationId);
  const suggestion = useScheduleSuggestion(medicationId);
  const existing = useSchedules(medicationId);
  const save = useSaveSchedule();

  const [editedTimes, setEditedTimes] = useState<string[] | null>(null);
  const [editedDoseAmount, setEditedDoseAmount] = useState<string | null>(null);
  const [confirmed, setConfirmed] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const activeTimes = useMemo(
    () => (existing.data ?? []).filter((schedule) => schedule.isActive).map((schedule) => schedule.time),
    [existing.data],
  );

  const times = editedTimes ?? (activeTimes.length > 0 ? activeTimes : (suggestion.data?.suggestedTimes ?? []));
  const doseAmount =
    editedDoseAmount ??
    (existing.data ?? []).find((schedule) => schedule.doseAmountText)?.doseAmountText ??
    suggestion.data?.doseAmountText ??
    '';

  function updateTime(index: number, value: string) {
    setEditedTimes(times.map((time, position) => (position === index ? value : time)));
  }

  async function submit() {
    const cleaned = times.map((time) => time.trim()).filter((time) => time.length > 0);

    if (cleaned.length === 0) {
      setError('Add at least one reminder time, or remove the reminders for this medication.');
      return;
    }

    const invalid = cleaned.find((time) => !timePattern.test(time));
    if (invalid) {
      setError(`"${invalid}" is not a valid time. Use the 24-hour format, for example 08:00.`);
      return;
    }

    if (!confirmed) {
      setError('Confirm the reminder times before saving.');
      return;
    }

    setError(null);

    try {
      await save.mutateAsync({
        medicationId,
        times: cleaned,
        labelInstruction: suggestion.data?.labelInstruction ?? medication.data?.labelDirections ?? null,
        doseAmountText: doseAmount.trim() || null,
        userConfirmed: true,
      });

      router.replace(`/medication/${medicationId}`);
    } catch (caught) {
      setError(describeError(caught));
    }
  }

  if (medication.isPending || suggestion.isPending || existing.isPending) {
    return (
      <Screen style={{ paddingTop: insets.top }}>
        <BackLink />
        <LoadingState label="Reading the label instructions" />
      </Screen>
    );
  }

  return (
    <Screen style={{ paddingTop: insets.top }}>
      <BackLink />

      <View className="gap-1">
        <Text variant="title">Reminder times</Text>
        <Text className="text-ink-muted">{medication.data?.displayName}</Text>
      </View>

      <Card className="gap-2">
        <Text variant="label">Label instructions</Text>
        <Text variant="heading">
          {suggestion.data?.labelInstruction ?? medication.data?.labelDirections ?? 'No directions were read from the label.'}
        </Text>
        {suggestion.data && suggestion.data.timesPerDay > 0 ? (
          <Text variant="caption">
            MedGuard suggests {suggestion.data.timesPerDay} reminder{suggestion.data.timesPerDay === 1 ? '' : 's'} a day.
          </Text>
        ) : null}
      </Card>

      <Callout
        tone="info"
        title="These times are only a convenience suggestion"
        message="MedGuard cannot say which times are medically right for you. Adjust them to fit the instructions you were given, then confirm."
      />

      <Card className="gap-3">
        <Text variant="heading">Your reminder times</Text>

        {times.map((time, index) => (
          <View key={index} className="flex-row items-center gap-2">
            <TextInput
              value={time}
              onChangeText={(value) => updateTime(index, value)}
              accessibilityLabel={`Reminder time ${index + 1}`}
              placeholder="08:00"
              placeholderTextColor={palette.inkSubtle}
              keyboardType={Platform.OS === 'ios' ? 'numbers-and-punctuation' : 'default'}
              maxLength={5}
              className="min-h-12 flex-1 rounded-2xl border border-line bg-surface px-4 text-base text-ink"
            />
            <Pressable
              onPress={() => setEditedTimes(times.filter((_, position) => position !== index))}
              accessibilityRole="button"
              accessibilityLabel={`Remove reminder ${index + 1}`}
              className="h-12 w-12 items-center justify-center rounded-2xl border border-line active:bg-surface-muted"
            >
              <Ionicons name="trash-outline" size={18} color={palette.inkMuted} />
            </Pressable>
          </View>
        ))}

        <Pressable
          onPress={() => setEditedTimes([...times, ''])}
          accessibilityRole="button"
          accessibilityLabel="Add a reminder time"
          className="min-h-12 flex-row items-center justify-center gap-2 rounded-2xl border border-dashed border-line active:bg-surface-muted"
        >
          <Ionicons name="add" size={18} color={palette.brand} />
          <Text className="font-semibold text-brand-600">Add a time</Text>
        </Pressable>

        <View className="gap-1.5">
          <Text variant="label">Dose amount (optional)</Text>
          <TextInput
            value={doseAmount}
            onChangeText={setEditedDoseAmount}
            accessibilityLabel="Dose amount"
            placeholder="1 tablet"
            placeholderTextColor={palette.inkSubtle}
            className="min-h-12 rounded-2xl border border-line bg-surface px-4 text-base text-ink"
          />
        </View>
      </Card>

      <Pressable
        onPress={() => setConfirmed((value) => !value)}
        accessibilityRole="checkbox"
        accessibilityState={{ checked: confirmed }}
        accessibilityLabel="I confirm these reminder times"
        className="flex-row items-center gap-3 rounded-3xl border border-line bg-surface p-4"
      >
        <View
          className={`h-6 w-6 items-center justify-center rounded-md border ${
            confirmed ? 'border-brand-500 bg-brand-500' : 'border-line'
          }`}
        >
          {confirmed ? <Ionicons name="checkmark" size={16} color="#FFFFFF" /> : null}
        </View>
        <Text className="flex-1">
          I confirm these reminder times match the instructions I was given for this medication.
        </Text>
      </Pressable>

      {error ? <Text className="text-sm text-critical-700">{error}</Text> : null}

      <Button label="Save reminders" loading={save.isPending} onPress={() => void submit()} />
      <Text variant="caption" className="text-center">
        Reminders are stored on this device. Notification content follows your privacy setting.
      </Text>
    </Screen>
  );
}
