import { create } from 'zustand';

import type { ConfirmScanResponse, ScanResponse } from '@/types/api';

interface ScanState {
  /** The most recent extraction awaiting the user's confirmation. */
  scan: ScanResponse | null;
  /** Result of the confirmation, kept so the safety screen can show it straight away. */
  outcome: ConfirmScanResponse | null;
  setScan: (scan: ScanResponse | null) => void;
  setOutcome: (outcome: ConfirmScanResponse | null) => void;
  clear: () => void;
}

export const useScanStore = create<ScanState>((set) => ({
  scan: null,
  outcome: null,
  setScan: (scan) => set({ scan, outcome: null }),
  setOutcome: (outcome) => set({ outcome }),
  clear: () => set({ scan: null, outcome: null }),
}));
