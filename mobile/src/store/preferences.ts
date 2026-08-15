import { create } from 'zustand';

import { readSecret, secureKeys, writeSecret } from '@/services/secure-storage';

interface StoredPreferences {
  onboardingCompleted: boolean;
  /** Mirrors the server setting so notification content can be built while offline. */
  privacyNotifications: boolean;
  biometricLock: boolean;
}

const defaults: StoredPreferences = {
  onboardingCompleted: false,
  privacyNotifications: true,
  biometricLock: false,
};

interface PreferencesState extends StoredPreferences {
  hydrated: boolean;
  hydrate: () => Promise<void>;
  set: (patch: Partial<StoredPreferences>) => Promise<void>;
}

export const usePreferencesStore = create<PreferencesState>((set, get) => ({
  ...defaults,
  hydrated: false,

  hydrate: async () => {
    const raw = await readSecret(secureKeys.preferences);

    if (!raw) {
      set({ hydrated: true });
      return;
    }

    try {
      set({ ...defaults, ...(JSON.parse(raw) as Partial<StoredPreferences>), hydrated: true });
    } catch {
      set({ hydrated: true });
    }
  },

  set: async (patch) => {
    const next: StoredPreferences = {
      onboardingCompleted: patch.onboardingCompleted ?? get().onboardingCompleted,
      privacyNotifications: patch.privacyNotifications ?? get().privacyNotifications,
      biometricLock: patch.biometricLock ?? get().biometricLock,
    };

    set(next);
    await writeSecret(secureKeys.preferences, JSON.stringify(next));
  },
}));
