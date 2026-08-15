import { useRouter, useSegments } from 'expo-router';
import { useEffect } from 'react';

import { useAuthStore } from '@/store/auth';
import { usePreferencesStore } from '@/store/preferences';

/**
 * Keeps the visible route in step with the session: onboarding before sign-in, the safety
 * notice before the app itself, and no protected screen while signed out.
 */
export function AuthGate({ children }: { children: React.ReactNode }) {
  const router = useRouter();
  const segments = useSegments();
  const status = useAuthStore((state) => state.status);
  const user = useAuthStore((state) => state.user);
  const onboardingCompleted = usePreferencesStore((state) => state.onboardingCompleted);
  const hydrated = usePreferencesStore((state) => state.hydrated);

  useEffect(() => {
    if (!hydrated || status === 'idle' || status === 'loading') {
      return;
    }

    const root = segments[0];
    const inAuthGroup = root === '(auth)';
    const onOnboarding = root === 'onboarding';
    const onSafetyNotice = root === 'safety-notice';

    if (status === 'signedOut') {
      if (!onboardingCompleted && !onOnboarding) {
        router.replace('/onboarding');
        return;
      }

      if (onboardingCompleted && !inAuthGroup) {
        router.replace('/(auth)/sign-in');
      }

      return;
    }

    if (user && !user.safetyNoticeAcknowledged) {
      if (!onSafetyNotice) {
        router.replace('/safety-notice');
      }

      return;
    }

    if (inAuthGroup || onOnboarding || onSafetyNotice) {
      router.replace('/(tabs)');
    }
  }, [hydrated, onboardingCompleted, router, segments, status, user]);

  return <>{children}</>;
}
