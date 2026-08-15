import '../../global.css';

import { QueryClientProvider } from '@tanstack/react-query';
import { Stack } from 'expo-router';
import * as SplashScreen from 'expo-splash-screen';
import { StatusBar } from 'expo-status-bar';
import { useEffect, useState } from 'react';
import { SafeAreaProvider } from 'react-native-css/components/react-native-safe-area-context';
import { GestureHandlerRootView } from 'react-native-gesture-handler';

import { AppLockGate } from '@/components/security/AppLockGate';
import { PrivacyShield } from '@/components/security/PrivacyShield';
import { AuthGate } from '@/components/navigation/AuthGate';
import { NotificationActionHandler } from '@/components/navigation/NotificationActionHandler';
import { createQueryClient } from '@/services/query';
import { configureNotifications } from '@/services/notifications';
import { useAuthStore } from '@/store/auth';
import { usePreferencesStore } from '@/store/preferences';

void SplashScreen.preventAutoHideAsync();

export default function RootLayout() {
  const [queryClient] = useState(createQueryClient);
  const bootstrap = useAuthStore((state) => state.bootstrap);
  const hydratePreferences = usePreferencesStore((state) => state.hydrate);
  const [ready, setReady] = useState(false);

  useEffect(() => {
    let cancelled = false;

    async function prepare() {
      // A failing startup task must never leave the user on a blank screen, so each one is
      // allowed to fail on its own and the app still opens on the signed-out state.
      try {
        await Promise.allSettled([hydratePreferences(), bootstrap(), configureNotifications()]);
      } finally {
        if (!cancelled) {
          setReady(true);
          await SplashScreen.hideAsync();
        }
      }
    }

    void prepare();

    return () => {
      cancelled = true;
    };
  }, [bootstrap, hydratePreferences]);

  if (!ready) {
    return null;
  }

  return (
    <GestureHandlerRootView style={{ flex: 1 }}>
      <SafeAreaProvider>
        <QueryClientProvider client={queryClient}>
          <StatusBar style="dark" />
          <AuthGate>
            <Stack
              screenOptions={{
                headerShown: false,
                contentStyle: { backgroundColor: '#F6F8FB' },
                animation: 'slide_from_right',
              }}
            >
              <Stack.Screen name="(tabs)" />
              <Stack.Screen name="scan/review" options={{ animation: 'slide_from_bottom' }} />
            </Stack>
          </AuthGate>
          <NotificationActionHandler />
          <AppLockGate />
          <PrivacyShield />
        </QueryClientProvider>
      </SafeAreaProvider>
    </GestureHandlerRootView>
  );
}
