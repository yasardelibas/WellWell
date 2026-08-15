import { create } from 'zustand';

import { clearTokens, loadStoredTokens, persistTokens, setSessionExpiredHandler } from '@/services/api/client';
import { authApi } from '@/services/api/endpoints';
import { deleteSecret, readSecret, secureKeys, writeSecret } from '@/services/secure-storage';
import type { AuthResponse, UpdateProfileRequest, User } from '@/types/api';

type Status = 'idle' | 'loading' | 'signedIn' | 'signedOut';

interface AuthState {
  status: Status;
  user: User | null;
  sessionExpired: boolean;
  bootstrap: () => Promise<void>;
  signIn: (email: string, password: string) => Promise<void>;
  signUp: (input: { email: string; password: string; displayName: string }) => Promise<void>;
  signInWithDemo: () => Promise<void>;
  signOut: () => Promise<void>;
  refreshUser: () => Promise<void>;
  updateProfile: (input: UpdateProfileRequest) => Promise<void>;
  acknowledgeSafetyNotice: () => Promise<void>;
}

function deviceTimeZone(): string {
  try {
    return Intl.DateTimeFormat().resolvedOptions().timeZone ?? 'UTC';
  } catch {
    return 'UTC';
  }
}

async function cacheUser(user: User): Promise<void> {
  await writeSecret(secureKeys.user, JSON.stringify(user));
}

async function readCachedUser(): Promise<User | null> {
  const raw = await readSecret(secureKeys.user);

  if (!raw) {
    return null;
  }

  try {
    return JSON.parse(raw) as User;
  } catch {
    return null;
  }
}

export const useAuthStore = create<AuthState>((set, get) => ({
  status: 'idle',
  user: null,
  sessionExpired: false,

  bootstrap: async () => {
    set({ status: 'loading' });

    setSessionExpiredHandler(() => {
      void deleteSecret(secureKeys.user);
      set({ status: 'signedOut', user: null, sessionExpired: true });
    });

    let cached: User | null = null;

    try {
      const tokens = await loadStoredTokens();

      if (!tokens) {
        set({ status: 'signedOut', user: null });
        return;
      }

      // Show the cached profile immediately, then reconcile with the server.
      cached = await readCachedUser();
      if (cached) {
        set({ status: 'signedIn', user: cached });
      }

      const user = await authApi.me();
      await cacheUser(user);
      set({ status: 'signedIn', user, sessionExpired: false });
    } catch {
      // An unreadable store or an unreachable server must still resolve to a usable state.
      if (!cached) {
        await clearTokens().catch(() => undefined);
        set({ status: 'signedOut', user: null });
      }
    }
  },

  signIn: async (email, password) => {
    const auth = await authApi.login({ email: email.trim(), password });
    await applySession(auth);
    set({ status: 'signedIn', user: auth.user, sessionExpired: false });
  },

  signUp: async ({ email, password, displayName }) => {
    const auth = await authApi.register({
      email: email.trim(),
      password,
      displayName: displayName.trim(),
      timeZoneId: deviceTimeZone(),
    });
    await applySession(auth);
    set({ status: 'signedIn', user: auth.user, sessionExpired: false });
  },

  signInWithDemo: async () => {
    const auth = await authApi.demoLogin();
    await applySession(auth);
    set({ status: 'signedIn', user: auth.user, sessionExpired: false });
  },

  signOut: async () => {
    const refreshToken = await readSecret(secureKeys.refreshToken);

    try {
      await authApi.logout(refreshToken);
    } catch {
      // Signing out locally must succeed even when the server cannot be reached.
    }

    await Promise.all([clearTokens(), deleteSecret(secureKeys.user)]);
    set({ status: 'signedOut', user: null, sessionExpired: false });
  },

  refreshUser: async () => {
    if (get().status !== 'signedIn') {
      return;
    }

    const user = await authApi.me();
    await cacheUser(user);
    set({ user });
  },

  updateProfile: async (input) => {
    const user = await authApi.updateProfile(input);
    await cacheUser(user);
    set({ user });
  },

  acknowledgeSafetyNotice: async () => {
    const user = await authApi.acknowledgeSafetyNotice();
    await cacheUser(user);
    set({ user });
  },
}));

async function applySession(auth: AuthResponse): Promise<void> {
  await persistTokens({ accessToken: auth.accessToken, refreshToken: auth.refreshToken });
  await cacheUser(auth.user);
}
