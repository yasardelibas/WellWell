import { Redirect } from 'expo-router';

import { useAuthStore } from '@/store/auth';
import { usePreferencesStore } from '@/store/preferences';

export default function Index() {
  const status = useAuthStore((state) => state.status);
  const user = useAuthStore((state) => state.user);
  const onboardingCompleted = usePreferencesStore((state) => state.onboardingCompleted);

  if (status === 'signedIn') {
    return user?.safetyNoticeAcknowledged ? <Redirect href="/(tabs)" /> : <Redirect href="/safety-notice" />;
  }

  return onboardingCompleted ? <Redirect href="/(auth)/sign-in" /> : <Redirect href="/onboarding" />;
}
