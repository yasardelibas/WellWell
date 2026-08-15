import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';

import { medicationsApi } from '@/services/api/endpoints';
import { queryKeys } from '@/services/query';
import type { CreateMedicationRequest, UpdateMedicationRequest } from '@/types/api';

export function useMedications() {
  return useQuery({ queryKey: queryKeys.medications, queryFn: medicationsApi.list });
}

export function useMedication(id: string | undefined) {
  return useQuery({
    queryKey: queryKeys.medication(id ?? 'unknown'),
    queryFn: () => medicationsApi.get(id as string),
    enabled: Boolean(id),
  });
}

export function useCreateMedication() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (body: CreateMedicationRequest) => medicationsApi.create(body),
    onSuccess: async () => {
      await queryClient.invalidateQueries({ queryKey: queryKeys.medications });
      await queryClient.invalidateQueries({ queryKey: queryKeys.safetyFindings });
    },
  });
}

export function useUpdateMedication(id: string) {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (body: UpdateMedicationRequest) => medicationsApi.update(id, body),
    onSuccess: async () => {
      await queryClient.invalidateQueries({ queryKey: queryKeys.medications });
      await queryClient.invalidateQueries({ queryKey: queryKeys.medication(id) });
      await queryClient.invalidateQueries({ queryKey: queryKeys.safetyFindings });
    },
  });
}

export function useDeleteMedication() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (id: string) => medicationsApi.remove(id),
    onSuccess: async () => {
      await queryClient.invalidateQueries({ queryKey: queryKeys.medications });
      await queryClient.invalidateQueries({ queryKey: queryKeys.safetyFindings });
      await queryClient.invalidateQueries({ queryKey: queryKeys.today });
    },
  });
}
