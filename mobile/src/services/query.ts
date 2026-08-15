import { QueryClient } from '@tanstack/react-query';

import { ApiError } from '@/services/api/client';

export const queryKeys = {
  me: ['me'] as const,
  medications: ['medications'] as const,
  medication: (id: string) => ['medications', id] as const,
  safetyFindings: ['safety', 'findings'] as const,
  safetyAnalysis: ['safety', 'analysis'] as const,
  safetyExplanation: (findingId: string) => ['safety', 'findings', findingId, 'explanation'] as const,
  schedules: (medicationId?: string) => ['schedules', medicationId ?? 'all'] as const,
  scheduleSuggestion: (medicationId: string) => ['schedules', 'suggestion', medicationId] as const,
  today: ['adherence', 'today'] as const,
  history: (medicationId?: string) => ['adherence', 'history', medicationId ?? 'all'] as const,
  emergencyCard: ['emergency-card'] as const,
  caregivers: ['caregivers'] as const,
  sharedWithMe: ['caregivers', 'shared-with-me'] as const,
};

export function createQueryClient(): QueryClient {
  return new QueryClient({
    defaultOptions: {
      queries: {
        staleTime: 30_000,
        gcTime: 5 * 60_000,
        retry: (failureCount, error) => {
          // Authorisation and validation problems will not fix themselves on retry.
          if (error instanceof ApiError && error.status < 500) {
            return false;
          }

          return failureCount < 2;
        },
      },
      mutations: {
        retry: false,
      },
    },
  });
}
