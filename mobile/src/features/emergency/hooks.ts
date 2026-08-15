import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';

import { emergencyApi } from '@/services/api/endpoints';
import { queryKeys } from '@/services/query';
import type { UpdateEmergencyCardRequest } from '@/types/api';

export function useEmergencyCard() {
  return useQuery({ queryKey: queryKeys.emergencyCard, queryFn: emergencyApi.get });
}

export function useUpdateEmergencyCard() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (body: UpdateEmergencyCardRequest) => emergencyApi.update(body),
    onSuccess: (card) => queryClient.setQueryData(queryKeys.emergencyCard, card),
  });
}

/** Regenerating issues a new opaque token and invalidates the previous QR immediately. */
export function useRegenerateEmergencyToken() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: () => emergencyApi.regenerate(),
    onSuccess: (card) => queryClient.setQueryData(queryKeys.emergencyCard, card),
  });
}
