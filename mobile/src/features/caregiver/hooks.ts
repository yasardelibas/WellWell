import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';

import { caregiversApi } from '@/services/api/endpoints';
import { queryKeys } from '@/services/query';

export const caregiverPermissions = [
  { value: 'VIEW_MEDICATION_LIST', label: 'See the medication list' },
  { value: 'VIEW_ADHERENCE', label: 'See taken and missed doses' },
  { value: 'VIEW_SCHEDULE', label: 'See reminder times' },
  { value: 'RECEIVE_MISSED_DOSE_ALERT', label: 'Be alerted about missed doses' },
] as const;

export function useCaregivers() {
  return useQuery({ queryKey: queryKeys.caregivers, queryFn: caregiversApi.list });
}

export function useSharedWithMe() {
  return useQuery({ queryKey: queryKeys.sharedWithMe, queryFn: caregiversApi.sharedWithMe });
}

export function useInviteCaregiver() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (body: { email: string; permissions: string[] }) => caregiversApi.invite(body),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: queryKeys.caregivers }),
  });
}

export function useUpdateCaregiverPermissions() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: ({ id, permissions }: { id: string; permissions: string[] }) =>
      caregiversApi.updatePermissions(id, permissions),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: queryKeys.caregivers }),
  });
}

export function useRevokeCaregiver() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (id: string) => caregiversApi.revoke(id),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: queryKeys.caregivers }),
  });
}
