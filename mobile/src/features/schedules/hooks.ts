import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';

import { schedulesApi } from '@/services/api/endpoints';
import { syncReminders } from '@/services/notifications';
import { queryKeys } from '@/services/query';
import { usePreferencesStore } from '@/store/preferences';
import type { CreateScheduleRequest } from '@/types/api';

export function useSchedules(medicationId?: string) {
  return useQuery({
    queryKey: queryKeys.schedules(medicationId),
    queryFn: () => schedulesApi.list(medicationId),
  });
}

export function useScheduleSuggestion(medicationId: string | undefined) {
  return useQuery({
    queryKey: queryKeys.scheduleSuggestion(medicationId ?? 'unknown'),
    queryFn: () => schedulesApi.suggestion(medicationId as string),
    enabled: Boolean(medicationId),
  });
}

/** Local reminders are always rebuilt from the server's confirmed schedules. */
async function refreshReminders(): Promise<void> {
  const privacyMode = usePreferencesStore.getState().privacyNotifications;
  const schedules = await schedulesApi.list();
  await syncReminders(schedules, privacyMode);
}

export function useSaveSchedule() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (body: CreateScheduleRequest) => schedulesApi.create(body),
    onSuccess: async () => {
      await queryClient.invalidateQueries({ queryKey: ['schedules'] });
      await queryClient.invalidateQueries({ queryKey: queryKeys.today });
      await queryClient.invalidateQueries({ queryKey: queryKeys.medications });
      await refreshReminders();
    },
  });
}

export function useDeleteSchedule() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (id: string) => schedulesApi.remove(id),
    onSuccess: async () => {
      await queryClient.invalidateQueries({ queryKey: ['schedules'] });
      await queryClient.invalidateQueries({ queryKey: queryKeys.today });
      await refreshReminders();
    },
  });
}
