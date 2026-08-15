import * as Notifications from 'expo-notifications';
import { Platform } from 'react-native';

import type { Schedule } from '@/types/api';

export const REMINDER_CATEGORY = 'medguard_reminder';
export const REMINDER_ACTIONS = {
  taken: 'MEDGUARD_TAKEN',
  skip: 'MEDGUARD_SKIP',
  snooze: 'MEDGUARD_SNOOZE',
} as const;

export interface ReminderPayload {
  kind: 'medication_reminder';
  scheduleId: string;
  medicationId: string;
}

let configured = false;

export async function configureNotifications(): Promise<void> {
  if (configured) {
    return;
  }

  configured = true;

  try {
    Notifications.setNotificationHandler({
      handleNotification: async () => ({
        shouldShowBanner: true,
        shouldShowList: true,
        shouldPlaySound: true,
        shouldSetBadge: false,
      }),
    });

    if (Platform.OS === 'android') {
      await Notifications.setNotificationChannelAsync('medication-reminders', {
        name: 'Medication reminders',
        importance: Notifications.AndroidImportance.HIGH,
        vibrationPattern: [0, 200, 150, 200],
        lightColor: '#2F6FED',
      });
    }

    // Every action opens the app so the dose is recorded through the API rather than guessed.
    await Notifications.setNotificationCategoryAsync(REMINDER_CATEGORY, [
      { identifier: REMINDER_ACTIONS.taken, buttonTitle: 'Taken', options: { opensAppToForeground: true } },
      { identifier: REMINDER_ACTIONS.skip, buttonTitle: 'Skip', options: { opensAppToForeground: true } },
      { identifier: REMINDER_ACTIONS.snooze, buttonTitle: 'Remind me later', options: { opensAppToForeground: true } },
    ]);
  } catch (error) {
    // Leave the door open for a later retry rather than silently skipping setup forever.
    configured = false;
    throw error;
  }
}

export async function requestNotificationPermission(): Promise<boolean> {
  const current = await Notifications.getPermissionsAsync();

  if (current.granted || current.ios?.status === Notifications.IosAuthorizationStatus.PROVISIONAL) {
    return true;
  }

  const requested = await Notifications.requestPermissionsAsync();
  return requested.granted || requested.ios?.status === Notifications.IosAuthorizationStatus.PROVISIONAL;
}

function buildContent(schedule: Schedule, privacyMode: boolean): Notifications.NotificationContentInput {
  const payload: ReminderPayload = {
    kind: 'medication_reminder',
    scheduleId: schedule.id,
    medicationId: schedule.medicationId,
  };

  // Privacy mode keeps medication names off the lock screen.
  const body = privacyMode
    ? 'You have a medication reminder.'
    : [schedule.medicationName, schedule.doseAmountText].filter(Boolean).join(' · ');

  return {
    title: 'Medication reminder',
    body,
    data: payload as unknown as Record<string, unknown>,
    categoryIdentifier: REMINDER_CATEGORY,
    sound: true,
  };
}

/**
 * Rebuilds the local reminder set from the confirmed schedules. Reminders exist only for
 * schedules the user explicitly confirmed and left active.
 */
export async function syncReminders(schedules: Schedule[], privacyMode: boolean): Promise<number> {
  await configureNotifications();

  const granted = await requestNotificationPermission();
  if (!granted) {
    return 0;
  }

  await Notifications.cancelAllScheduledNotificationsAsync();

  const active = schedules.filter((schedule) => schedule.isActive && schedule.userConfirmed);

  for (const schedule of active) {
    const [hourText, minuteText] = schedule.time.split(':');
    const hour = Number.parseInt(hourText ?? '', 10);
    const minute = Number.parseInt(minuteText ?? '', 10);

    if (Number.isNaN(hour) || Number.isNaN(minute)) {
      continue;
    }

    await Notifications.scheduleNotificationAsync({
      content: buildContent(schedule, privacyMode),
      trigger: {
        type: Notifications.SchedulableTriggerInputTypes.DAILY,
        hour,
        minute,
        ...(Platform.OS === 'android' ? { channelId: 'medication-reminders' } : {}),
      },
    });
  }

  return active.length;
}

export async function cancelAllReminders(): Promise<void> {
  await Notifications.cancelAllScheduledNotificationsAsync();
}

export function readReminderPayload(notification: Notifications.Notification): ReminderPayload | null {
  const data = notification.request.content.data as Partial<ReminderPayload> | undefined;

  if (data?.kind !== 'medication_reminder' || typeof data.scheduleId !== 'string') {
    return null;
  }

  return { kind: 'medication_reminder', scheduleId: data.scheduleId, medicationId: data.medicationId ?? '' };
}
