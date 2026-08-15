import { Ionicons } from '@expo/vector-icons';
import { useRouter } from 'expo-router';
import { useState } from 'react';
import { Alert, Pressable, Switch, View } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';

import { isBiometricLockAvailable } from '@/components/security/AppLockGate';
import { Badge } from '@/components/ui/Badge';
import { Button } from '@/components/ui/Button';
import { Callout } from '@/components/ui/Callout';
import { Card } from '@/components/ui/Card';
import { Screen, ScreenHeader } from '@/components/ui/Screen';
import { Text } from '@/components/ui/Text';
import { useSchedules } from '@/features/schedules/hooks';
import { describeError } from '@/services/api/client';
import { syncReminders } from '@/services/notifications';
import { useAuthStore } from '@/store/auth';
import { usePreferencesStore } from '@/store/preferences';
import { palette } from '@/theme/tokens';
import { initials } from '@/utils/format';

export default function Profile() {
  const router = useRouter();
  const insets = useSafeAreaInsets();
  const user = useAuthStore((state) => state.user);
  const updateProfile = useAuthStore((state) => state.updateProfile);
  const signOut = useAuthStore((state) => state.signOut);
  const preferences = usePreferencesStore();
  const schedules = useSchedules();
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function setPrivacyNotifications(value: boolean) {
    setBusy(true);
    setError(null);

    try {
      await updateProfile({ privacyNotificationsEnabled: value });
      await preferences.set({ privacyNotifications: value });
      // Existing reminders are rebuilt so their wording follows the new setting.
      await syncReminders(schedules.data ?? [], value);
    } catch (caught) {
      setError(describeError(caught));
    } finally {
      setBusy(false);
    }
  }

  async function setBiometricLock(value: boolean) {
    setError(null);

    if (value && !(await isBiometricLockAvailable())) {
      Alert.alert(
        'Device lock not available',
        'Set up a passcode, fingerprint or face unlock on this device first, then enable the app lock.',
      );
      return;
    }

    setBusy(true);

    try {
      await updateProfile({ biometricLockEnabled: value });
      await preferences.set({ biometricLock: value });
    } catch (caught) {
      setError(describeError(caught));
    } finally {
      setBusy(false);
    }
  }

  function confirmSignOut() {
    Alert.alert('Sign out?', 'Your medication information stays on the server and is removed from this device.', [
      { text: 'Stay signed in', style: 'cancel' },
      { text: 'Sign out', style: 'destructive', onPress: () => void signOut() },
    ]);
  }

  return (
    <Screen style={{ paddingTop: insets.top }}>
      <ScreenHeader title="Profile" subtitle="Your account, privacy and sharing settings." />

      <Card className="flex-row items-center gap-4">
        <View className="h-14 w-14 items-center justify-center rounded-2xl bg-brand-50">
          <Text className="text-lg font-bold text-brand-700">{initials(user?.displayName ?? 'MG')}</Text>
        </View>
        <View className="flex-1 gap-1">
          <Text variant="heading">{user?.displayName}</Text>
          <Text variant="caption">{user?.email}</Text>
          {user?.isDemoAccount ? <Badge label="Demo account" tone="info" glyph="i" /> : null}
        </View>
      </Card>

      <Card className="gap-3">
        <Text variant="heading">Privacy and security</Text>

        <SettingRow
          label="Private notifications"
          hint="Lock-screen reminders say “You have a medication reminder” instead of naming the medication."
          value={user?.privacyNotificationsEnabled ?? true}
          disabled={busy}
          onChange={(value) => void setPrivacyNotifications(value)}
        />

        <SettingRow
          label="Biometric app lock"
          hint="Ask for Face ID, fingerprint or the device passcode after the app has been in the background."
          value={user?.biometricLockEnabled ?? false}
          disabled={busy}
          divider={false}
          onChange={(value) => void setBiometricLock(value)}
        />

        <Text variant="caption">
          Screenshots are blocked where the platform supports it, and medication content is hidden in the app switcher.
        </Text>
      </Card>

      {error ? <Text className="text-sm text-critical-700">{error}</Text> : null}

      <Card className="gap-1">
        <Text variant="heading" className="mb-2">
          Sharing
        </Text>
        <LinkRow icon="qr-code-outline" label="Emergency card" onPress={() => router.push('/emergency')} />
        <LinkRow icon="people-outline" label="Caregivers" onPress={() => router.push('/caregivers')} />
        <LinkRow icon="calendar-outline" label="Dose history" divider={false} onPress={() => router.push('/history')} />
      </Card>

      <Callout
        tone="info"
        title="How MedGuard makes decisions"
        message="Safety findings come from deterministic checks against trusted medication data. Plain-language explanations only describe findings that already exist; they never create or dismiss one."
      />

      <Button
        label="Sign out"
        variant="secondary"
        icon={<Ionicons name="log-out-outline" size={18} color={palette.ink} />}
        onPress={confirmSignOut}
      />
    </Screen>
  );
}

function SettingRow({
  label,
  hint,
  value,
  disabled,
  divider = true,
  onChange,
}: {
  label: string;
  hint: string;
  value: boolean;
  disabled?: boolean;
  divider?: boolean;
  onChange: (value: boolean) => void;
}) {
  return (
    <View className={`flex-row items-start justify-between gap-4 py-3 ${divider ? 'border-b border-line' : ''}`}>
      <View className="flex-1 gap-1">
        <Text className="font-medium">{label}</Text>
        <Text variant="caption">{hint}</Text>
      </View>
      <Switch
        value={value}
        disabled={disabled}
        onValueChange={onChange}
        accessibilityLabel={label}
        trackColor={{ true: palette.brand, false: palette.line }}
        thumbColor="#FFFFFF"
      />
    </View>
  );
}

function LinkRow({
  icon,
  label,
  divider = true,
  onPress,
}: {
  icon: keyof typeof Ionicons.glyphMap;
  label: string;
  divider?: boolean;
  onPress: () => void;
}) {
  return (
    <Pressable
      onPress={onPress}
      accessibilityRole="button"
      accessibilityLabel={label}
      className={`min-h-12 flex-row items-center gap-3 py-3 active:opacity-70 ${divider ? 'border-b border-line' : ''}`}
    >
      <Ionicons name={icon} size={20} color={palette.ink} />
      <Text className="flex-1 font-medium">{label}</Text>
      <Ionicons name="chevron-forward" size={18} color={palette.inkSubtle} />
    </Pressable>
  );
}
