import Constants from 'expo-constants';
import { Platform } from 'react-native';

/**
 * The Android emulator reaches the host machine through 10.0.2.2, so a localhost
 * base URL coming from app.json is rewritten rather than silently failing.
 */
function resolveBaseUrl(): string {
  const configured =
    (Constants.expoConfig?.extra?.apiBaseUrl as string | undefined) ??
    process.env.EXPO_PUBLIC_API_BASE_URL ??
    'http://localhost:5175';

  const trimmed = configured.replace(/\/+$/, '');

  if (Platform.OS === 'android') {
    return trimmed.replace('localhost', '10.0.2.2').replace('127.0.0.1', '10.0.2.2');
  }

  return trimmed;
}

export const config = {
  apiBaseUrl: resolveBaseUrl(),
  requestTimeoutMs: 20_000,
  /** Below this the scanner asks the user to review every field by hand. */
  manualReviewThreshold: 0.7,
} as const;
