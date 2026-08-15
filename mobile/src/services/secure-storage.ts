import * as SecureStore from 'expo-secure-store';
import { Platform } from 'react-native';

/**
 * Tokens and other secrets never touch AsyncStorage. On web (used only for quick
 * previews) SecureStore is unavailable, so the values stay in memory for the session.
 */
const memoryFallback = new Map<string, string>();

const canUseSecureStore = Platform.OS !== 'web';

export async function readSecret(key: string): Promise<string | null> {
  if (!canUseSecureStore) {
    return memoryFallback.get(key) ?? null;
  }

  try {
    return await SecureStore.getItemAsync(key);
  } catch {
    return null;
  }
}

export async function writeSecret(key: string, value: string): Promise<void> {
  if (!canUseSecureStore) {
    memoryFallback.set(key, value);
    return;
  }

  await SecureStore.setItemAsync(key, value, {
    keychainAccessible: SecureStore.WHEN_UNLOCKED_THIS_DEVICE_ONLY,
  });
}

export async function deleteSecret(key: string): Promise<void> {
  if (!canUseSecureStore) {
    memoryFallback.delete(key);
    return;
  }

  try {
    await SecureStore.deleteItemAsync(key);
  } catch {
    // Deleting a key that was never written is not an error worth surfacing.
  }
}

export const secureKeys = {
  accessToken: 'medguard.accessToken',
  refreshToken: 'medguard.refreshToken',
  user: 'medguard.user',
  preferences: 'medguard.preferences',
} as const;
