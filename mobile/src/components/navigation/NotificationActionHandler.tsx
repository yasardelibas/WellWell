import { useQueryClient } from '@tanstack/react-query';
import * as Notifications from 'expo-notifications';
import { useRouter } from 'expo-router';
import { useEffect } from 'react';

import { adherenceApi } from '@/services/api/endpoints';
import { REMINDER_ACTIONS, readReminderPayload } from '@/services/notifications';
import { queryKeys } from '@/services/query';
import { useAuthStore } from '@/store/auth';

/**
 * Reminder buttons never record a dose blindly: the app resolves today's dose for that
 * schedule through the API and only then applies the action the user chose.
 */
export function NotificationActionHandler() {
  const router = useRouter();
  const queryClient = useQueryClient();
  const signedIn = useAuthStore((state) => state.status === 'signedIn');

  useEffect(() => {
    if (!signedIn) {
      return;
    }

    async function handle(response: Notifications.NotificationResponse) {
      const payload = readReminderPayload(response.notification);

      if (!payload) {
        return;
      }

      const action = response.actionIdentifier;

      if (action === Notifications.DEFAULT_ACTION_IDENTIFIER) {
        router.navigate('/(tabs)');
        return;
      }

      try {
        const today = await adherenceApi.today();
        const dose = today.doses.find(
          (item) => item.scheduleId === payload.scheduleId && (item.status === 'pending' || item.status === 'snoozed'),
        );

        if (!dose) {
          router.navigate('/(tabs)');
          return;
        }

        if (action === REMINDER_ACTIONS.taken) {
          await adherenceApi.markTaken(dose.id);
        } else if (action === REMINDER_ACTIONS.skip) {
          await adherenceApi.markSkipped(dose.id);
        } else if (action === REMINDER_ACTIONS.snooze) {
          await adherenceApi.snooze(dose.id, 15);
        }

        await queryClient.invalidateQueries({ queryKey: queryKeys.today });
      } catch {
        // The dashboard remains the source of truth if the action could not be applied.
        router.navigate('/(tabs)');
      }
    }

    const last = Notifications.getLastNotificationResponse();
    if (last) {
      void handle(last);
    }

    const subscription = Notifications.addNotificationResponseReceivedListener((response) => {
      void handle(response);
    });

    return () => subscription.remove();
  }, [queryClient, router, signedIn]);

  return null;
}
