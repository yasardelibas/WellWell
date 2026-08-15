import { BlurView } from 'expo-blur';
import * as ScreenCapture from 'expo-screen-capture';
import { useEffect, useState } from 'react';
import { AppState, StyleSheet, View, type AppStateStatus } from 'react-native';

import { Text } from '@/components/ui/Text';
import { useAuthStore } from '@/store/auth';

/**
 * Hides medication content from the app switcher and, where the platform supports it,
 * blocks screenshots while a session is open.
 */
export function PrivacyShield() {
  const signedIn = useAuthStore((state) => state.status === 'signedIn');
  const [obscured, setObscured] = useState(false);

  useEffect(() => {
    if (!signedIn) {
      return;
    }

    let active = true;

    void ScreenCapture.preventScreenCaptureAsync('medguard-session').catch(() => undefined);

    const subscription = AppState.addEventListener('change', (next: AppStateStatus) => {
      if (!active) {
        return;
      }

      setObscured(next !== 'active');
    });

    return () => {
      active = false;
      subscription.remove();
      void ScreenCapture.allowScreenCaptureAsync('medguard-session').catch(() => undefined);
    };
  }, [signedIn]);

  if (!signedIn || !obscured) {
    return null;
  }

  return (
    <View style={StyleSheet.absoluteFill} pointerEvents="none">
      <BlurView intensity={60} tint="light" style={StyleSheet.absoluteFill} />
      <View className="flex-1 items-center justify-center">
        <Text variant="heading">MedGuard</Text>
        <Text variant="caption">Content hidden</Text>
      </View>
    </View>
  );
}
