import { create } from 'zustand';

/** After this long in the background the app asks for the device credential again. */
export const INACTIVITY_TIMEOUT_MS = 2 * 60 * 1000;

interface AppLockState {
  locked: boolean;
  backgroundedAt: number | null;
  lock: () => void;
  unlock: () => void;
  noteBackgrounded: (at: number) => void;
  resumeFromBackground: (at: number, lockEnabled: boolean) => void;
}

export const useAppLockStore = create<AppLockState>((set, get) => ({
  locked: false,
  backgroundedAt: null,

  lock: () => set({ locked: true }),
  unlock: () => set({ locked: false, backgroundedAt: null }),
  noteBackgrounded: (at) => set({ backgroundedAt: at }),

  resumeFromBackground: (at, lockEnabled) => {
    const { backgroundedAt } = get();

    if (!lockEnabled || backgroundedAt === null) {
      set({ backgroundedAt: null });
      return;
    }

    set({ locked: at - backgroundedAt >= INACTIVITY_TIMEOUT_MS, backgroundedAt: null });
  },
}));
