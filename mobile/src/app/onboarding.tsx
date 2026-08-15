import { Ionicons } from '@expo/vector-icons';
import { useRouter } from 'expo-router';
import { useState } from 'react';
import { View } from 'react-native';

import { Button } from '@/components/ui/Button';
import { Callout } from '@/components/ui/Callout';
import { SafeAreaView } from '@/components/ui/SafeAreaView';
import { Text } from '@/components/ui/Text';
import { usePreferencesStore } from '@/store/preferences';
import { palette } from '@/theme/tokens';

const capabilities: { icon: keyof typeof Ionicons.glyphMap; label: string }[] = [
  { icon: 'time-outline', label: 'organise medication schedules' },
  { icon: 'flask-outline', label: 'identify active ingredients' },
  { icon: 'copy-outline', label: 'detect possible duplicate ingredients' },
  { icon: 'checkmark-done-outline', label: 'remember doses' },
  { icon: 'qr-code-outline', label: 'securely share emergency medication information' },
];

export default function Onboarding() {
  const router = useRouter();
  const setPreferences = usePreferencesStore((state) => state.set);
  const [step, setStep] = useState(0);

  async function finish() {
    await setPreferences({ onboardingCompleted: true });
    router.replace('/(auth)/sign-in');
  }

  return (
    <SafeAreaView className="flex-1 bg-canvas">
      <View className="flex-1 justify-between px-6 py-4">
        <View className="flex-row justify-center gap-2 pt-2" accessibilityLabel={`Step ${step + 1} of 3`}>
          {[0, 1, 2].map((index) => (
            <View
              key={index}
              className={`h-1.5 rounded-full ${index === step ? 'w-8 bg-brand-500' : 'w-4 bg-line'}`}
            />
          ))}
        </View>

        <View className="flex-1 justify-center gap-6">
          {step === 0 ? <WelcomeStep /> : null}
          {step === 1 ? <CapabilitiesStep /> : null}
          {step === 2 ? <SafetyStep /> : null}
        </View>

        <View className="gap-3">
          {step < 2 ? (
            <Button label="Continue" onPress={() => setStep((value) => value + 1)} />
          ) : (
            <Button label="I understand" onPress={() => void finish()} />
          )}
          {step < 2 ? (
            <Button label="Skip introduction" variant="ghost" size="md" onPress={() => setStep(2)} />
          ) : null}
        </View>
      </View>
    </SafeAreaView>
  );
}

function WelcomeStep() {
  return (
    <View className="gap-4">
      <View className="h-16 w-16 items-center justify-center rounded-3xl bg-brand-50">
        <Ionicons name="shield-checkmark-outline" size={32} color={palette.brand} />
      </View>
      <Text variant="caption" className="uppercase tracking-widest">
        MedGuard
      </Text>
      <Text variant="display">Medication safety in your pocket.</Text>
      <Text className="text-lg text-ink-muted">
        Scan your medicines, understand what you&apos;re taking, and keep your routine organised.
      </Text>
    </View>
  );
}

function CapabilitiesStep() {
  return (
    <View className="gap-5">
      <Text variant="title">MedGuard can help you</Text>
      <View className="gap-3">
        {capabilities.map((item) => (
          <View key={item.label} className="flex-row items-center gap-3 rounded-2xl border border-line bg-surface p-4">
            <Ionicons name={item.icon} size={22} color={palette.brand} />
            <Text className="flex-1">{item.label}</Text>
          </View>
        ))}
      </View>
    </View>
  );
}

function SafetyStep() {
  return (
    <View className="gap-5">
      <Text variant="title">Before you start</Text>
      <Callout
        tone="attention"
        title="MedGuard is not a diagnosis tool"
        message="MedGuard does not provide medical diagnoses or change medication instructions. Always follow your medication label and advice from your healthcare professional."
      />
      <Text className="text-ink-muted">
        Warnings are produced by deterministic checks against trusted medication data. Explanations written in plain
        language never add new findings of their own.
      </Text>
    </View>
  );
}
