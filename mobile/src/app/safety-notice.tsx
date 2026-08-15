import { useRouter } from 'expo-router';
import { useState } from 'react';
import { View } from 'react-native';

import { Button } from '@/components/ui/Button';
import { Callout } from '@/components/ui/Callout';
import { SafeAreaView } from '@/components/ui/SafeAreaView';
import { Text } from '@/components/ui/Text';
import { describeError } from '@/services/api/client';
import { useAuthStore } from '@/store/auth';

export default function SafetyNotice() {
  const router = useRouter();
  const acknowledge = useAuthStore((state) => state.acknowledgeSafetyNotice);
  const signOut = useAuthStore((state) => state.signOut);
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function accept() {
    setSubmitting(true);
    setError(null);

    try {
      await acknowledge();
      router.replace('/(tabs)');
    } catch (caught) {
      setError(describeError(caught));
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <SafeAreaView className="flex-1 bg-canvas">
      <View className="flex-1 justify-between gap-6 px-6 py-6">
        <View className="gap-5">
          <Text variant="title">How MedGuard works</Text>
          <Callout
            tone="attention"
            title="Please read before continuing"
            message="MedGuard does not provide medical diagnoses or change medication instructions. Always follow your medication label and advice from your healthcare professional."
          />
          <View className="gap-3 rounded-3xl border border-line bg-surface p-4">
            <Text className="text-ink-muted">• Medications are identified against trusted medication data, and you confirm every match.</Text>
            <Text className="text-ink-muted">• Safety checks are deterministic. MedGuard never claims medications are safe together.</Text>
            <Text className="text-ink-muted">• Reminder times are suggestions from the label wording until you confirm them.</Text>
            <Text className="text-ink-muted">• Nothing is shared with anyone unless you explicitly choose to share it.</Text>
          </View>
          {error ? <Text className="text-sm text-critical-700">{error}</Text> : null}
        </View>

        <View className="gap-3">
          <Button label="I understand and agree" loading={submitting} onPress={() => void accept()} />
          <Button label="Sign out" variant="ghost" size="md" onPress={() => void signOut()} />
        </View>
      </View>
    </SafeAreaView>
  );
}
