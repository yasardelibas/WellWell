import { Ionicons } from '@expo/vector-icons';
import * as LocalAuthentication from 'expo-local-authentication';
import { useCallback, useEffect, useState } from 'react';
import { AppState, StyleSheet, View, type AppStateStatus } from 'react-native';

import { Button } from '@/components/ui/Button';
import { Text } from '@/components/ui/Text';
import { useAppLockStore } from '@/store/app-lock';
import { useAuthStore } from '@/store/auth';
import { palette } from '@/theme/tokens';

export async function isBiometricLockAvailable(): Promise<boolean> {
  const [hasHardware, enrolled] = await Promise.all([
    LocalAuthentication.hasHardwareAsync(),
    LocalAuthentication.isEnrolledAsync(),
  ]);

  return hasHardware && enrolled;
}

/**
 * Covers the whole app when the biometric lock is on and the session has been idle in the
 * background. The prompt falls back to the device passcode so the user is never shut out.
 */
export function AppLockGate() {
  const signedIn = useAuthStore((state) => state.status === 'signedIn');
  const lockEnabled = useAuthStore((state) => state.user?.biometricLockEnabled === true);
  const locked = useAppLockStore((state) => state.locked);
  const lock = useAppLockStore((state) => state.lock);
  const unlock = useAppLockStore((state) => state.unlock);
  const noteBackgrounded = useAppLockStore((state) => state.noteBackgrounded);
  const resumeFromBackground = useAppLockStore((state) => state.resumeFromBackground);
  const [authenticating, setAuthenticating] = useState(false);
  const [failed, setFailed] = useState(false);

  useEffect(() => {
    if (!signedIn || !lockEnabled) {
      unlock();
      return;
    }

    lock();
  }, [lock, lockEnabled, signedIn, unlock]);

  useEffect(() => {
    const subscription = AppState.addEventListener('change', (next: AppStateStatus) => {
      if (next === 'background' || next === 'inactive') {
        noteBackgrounded(Date.now());
        return;
      }

      resumeFromBackground(Date.now(), signedIn && lockEnabled);
    });

    return () => subscription.remove();
  }, [lockEnabled, noteBackgrounded, resumeFromBackground, signedIn]);

  const authenticate = useCallback(async () => {
    setAuthenticating(true);
    setFailed(false);

    try {
      const result = await LocalAuthentication.authenticateAsync({
        promptMessage: 'Unlock MedGuard',
        cancelLabel: 'Cancel',
      });

      if (result.success) {
        unlock();
      } else {
        setFailed(true);
      }
    } catch {
      setFailed(true);
    } finally {
      setAuthenticating(false);
    }
  }, [unlock]);

  useEffect(() => {
    if (!locked || !signedIn || !lockEnabled) {
      return;
    }

    let cancelled = false;

    // The native prompt is its own progress indicator, so this path skips the button spinner.
    LocalAuthentication.authenticateAsync({ promptMessage: 'Unlock MedGuard', cancelLabel: 'Cancel' })
      .then((result) => {
        if (cancelled) {
          return;
        }

        if (result.success) {
          unlock();
        } else {
          setFailed(true);
        }
      })
      .catch(() => {
        if (!cancelled) {
          setFailed(true);
        }
      });

    return () => {
      cancelled = true;
    };
  }, [lockEnabled, locked, signedIn, unlock]);

  if (!signedIn || !lockEnabled || !locked) {
    return null;
  }

  return (
    <View style={StyleSheet.absoluteFill} className="items-center justify-center gap-4 bg-canvas px-8">
      <Ionicons name="lock-closed-outline" size={40} color={palette.brand} />
      <Text variant="title" className="text-center">
        MedGuard is locked
      </Text>
      <Text className="text-center text-ink-muted">
        Unlock with your device biometrics or passcode to see your medication information.
      </Text>
      {failed ? <Text className="text-center text-sm text-attention-700">Unlock was not completed.</Text> : null}
      <Button label="Unlock" loading={authenticating} onPress={() => void authenticate()} className="w-full" />
    </View>
  );
}
