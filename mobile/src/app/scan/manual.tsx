import { useRouter } from 'expo-router';
import { useState } from 'react';
import { KeyboardAvoidingView, Platform, TextInput, View } from 'react-native';

import { BackLink } from '@/components/ui/Screen';
import { Button } from '@/components/ui/Button';
import { Callout } from '@/components/ui/Callout';
import { SafeAreaView } from '@/components/ui/SafeAreaView';
import { Text } from '@/components/ui/Text';
import { useScanStore } from '@/features/scanner/store';
import { describeError } from '@/services/api/client';
import { scanApi } from '@/services/api/endpoints';
import { useAuthStore } from '@/store/auth';
import { palette } from '@/theme/tokens';

const demoLabel = `PAROL
Paracetamol 500 mg
Film coated tablet
Active ingredients: Paracetamol 500 mg
Take 1 tablet every 6 hours as needed.
Atabay`;

export default function ManualLabelEntry() {
  const router = useRouter();
  const setScan = useScanStore((state) => state.setScan);
  const isDemo = useAuthStore((state) => state.user?.isDemoAccount === true);
  const [text, setText] = useState('');
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function submit() {
    if (text.trim().length === 0) {
      setError('Type the text printed on the label first.');
      return;
    }

    setBusy(true);
    setError(null);

    try {
      const result = await scanApi.submit({ ocrText: text });
      setScan(result);
      router.replace('/scan/review');
    } catch (caught) {
      setError(describeError(caught));
    } finally {
      setBusy(false);
    }
  }

  return (
    <SafeAreaView className="flex-1 bg-canvas">
      <KeyboardAvoidingView className="flex-1" behavior={Platform.OS === 'ios' ? 'padding' : undefined}>
        <View className="flex-1 gap-4 px-5 pb-5">
          <BackLink label="Scanner" />
          <Text variant="title">Type the label text</Text>
          <Text className="text-ink-muted">
            Copy the medication name, the active ingredients and the directions exactly as printed. MedGuard matches
            them against trusted medication data and you confirm the result.
          </Text>

          <TextInput
            value={text}
            onChangeText={setText}
            multiline
            textAlignVertical="top"
            accessibilityLabel="Label text"
            placeholder={'Brand name\nActive ingredient 500 mg\nDirections'}
            placeholderTextColor={palette.inkSubtle}
            className="min-h-44 flex-1 rounded-3xl border border-line bg-surface p-4 text-base text-ink"
          />

          {error ? <Text className="text-sm text-critical-700">{error}</Text> : null}

          {isDemo ? (
            <Callout tone="info" title="Demo walkthrough">
              <Button label="Use the sample label" variant="secondary" size="md" onPress={() => setText(demoLabel)} />
            </Callout>
          ) : null}

          <Button label="Continue" loading={busy} onPress={() => void submit()} />
        </View>
      </KeyboardAvoidingView>
    </SafeAreaView>
  );
}
