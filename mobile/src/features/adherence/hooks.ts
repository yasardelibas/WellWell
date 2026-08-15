import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';

import { adherenceApi } from '@/services/api/endpoints';
import { queryKeys } from '@/services/query';

export function useToday() {
  return useQuery({ queryKey: queryKeys.today, queryFn: adherenceApi.today });
}

export function useAdherenceHistory(medicationId?: string) {
  return useQuery({
    queryKey: queryKeys.history(medicationId),
    queryFn: () => adherenceApi.history(medicationId ? { medicationId } : undefined),
  });
}

type DoseAction = { doseId: string; action: 'taken' | 'skipped' | 'snoozed'; minutes?: number };

export function useRecordDose() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: ({ doseId, action, minutes }: DoseAction) => {
      if (action === 'taken') {
        return adherenceApi.markTaken(doseId);
      }

      if (action === 'skipped') {
        return adherenceApi.markSkipped(doseId);
      }

      return adherenceApi.snooze(doseId, minutes ?? 15);
    },
    onSuccess: async () => {
      await queryClient.invalidateQueries({ queryKey: queryKeys.today });
      await queryClient.invalidateQueries({ queryKey: ['adherence', 'history'] });
    },
  });
}
