import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';

import { safetyApi } from '@/services/api/endpoints';
import { queryKeys } from '@/services/query';

export function useSafetyFindings() {
  return useQuery({ queryKey: queryKeys.safetyFindings, queryFn: safetyApi.findings });
}

export function useSafetyAnalysis() {
  return useQuery({ queryKey: queryKeys.safetyAnalysis, queryFn: () => safetyApi.analyze() });
}

export function useRunSafetyAnalysis() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (medicationId?: string) => safetyApi.analyze(medicationId),
    onSuccess: async (analysis) => {
      queryClient.setQueryData(queryKeys.safetyAnalysis, analysis);
      await queryClient.invalidateQueries({ queryKey: queryKeys.safetyFindings });
    },
  });
}

/**
 * The explanation is fetched only when the user asks for it, and it always describes a
 * finding the deterministic engine already produced.
 */
export function useSafetyExplanation(findingId: string | undefined) {
  return useQuery({
    queryKey: queryKeys.safetyExplanation(findingId ?? 'unknown'),
    queryFn: () => safetyApi.explanation(findingId as string),
    enabled: Boolean(findingId),
    staleTime: 5 * 60_000,
  });
}
