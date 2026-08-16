import 'dart:math';
import 'dart:ui' show Locale;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../l10n/generated/app_localizations.dart';
import '../l10n/language_controller.dart';
import '../models/models.dart';
import 'api.dart';

// Local notifications are scheduled ahead of time (sometimes weeks, for expiry alerts) with no
// BuildContext available, so they can't use AppLocalizations.of(context) like the rest of the
// app - this resolves the same AppLocalizations instance from the current app language directly.
AppLocalizations _l10n() => lookupAppLocalizations(Locale(AppLanguage.currentCode));

class ReminderSyncResult {
  const ReminderSyncResult({required this.scheduledCount, required this.permissionGranted});

  final int scheduledCount;
  final bool permissionGranted;
}

class Reminders {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _ready = false;

  // Set by WellWellApp once the router exists, so a tapped reminder can jump straight
  // to that medication's page instead of just opening the app.
  static void Function(String medicationId)? onNotificationTap;

  static Future<void> init() async {
    if (_ready) return;
    tzdata.initializeTimeZones();
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('Europe/Istanbul'));
    }

    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );
    await _plugin.initialize(settings: settings, onDidReceiveNotificationResponse: _handleTap);
    _ready = true;

    // The app may have been launched (cold start) by tapping a reminder; the response
    // above only fires for taps while the plugin is already running.
    final launchDetails = await _plugin.getNotificationAppLaunchDetails();
    if (launchDetails?.didNotificationLaunchApp == true) {
      _handleTap(launchDetails!.notificationResponse);
    }
  }

  static void _handleTap(NotificationResponse? response) {
    final medicationId = response?.payload;
    if (medicationId != null && medicationId.isNotEmpty) {
      onNotificationTap?.call(medicationId);
    }
  }

  static Future<bool> requestPermission() async {
    await init();
    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      return await android.requestNotificationsPermission() ?? false;
    }
    final ios = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    return await ios?.requestPermissions(alert: true, sound: true, badge: false) ?? false;
  }

  static Future<ReminderSyncResult> syncFromServer({required bool privacyMode}) async {
    try {
      // Medications are best-effort: refill reminders should never block dose reminders.
      final schedules = await Api.schedules();
      List<Medication> medications = const [];
      try {
        medications = await Api.medications();
      } catch (_) {
        // Ignore; dose reminders still schedule without refill data.
      }
      return sync(schedules, medications: medications, privacyMode: privacyMode);
    } catch (error) {
      debugPrint('WellWell reminder sync failed: $error');
      return const ReminderSyncResult(scheduledCount: 0, permissionGranted: true);
    }
  }

  static Future<ReminderSyncResult> sync(
    List<Schedule> schedules, {
    List<Medication> medications = const [],
    required bool privacyMode,
  }) async {
    await init();
    final granted = await requestPermission();
    if (!granted) {
      return const ReminderSyncResult(scheduledCount: 0, permissionGranted: false);
    }

    await _plugin.cancelAll();
    final active = schedules.where((schedule) => schedule.isActive && schedule.userConfirmed).toList();
    var count = 0;
    for (final schedule in active) {
      final parts = schedule.time.split(':');
      if (parts.length < 2) continue;
      final hour = int.tryParse(parts[0]);
      final minute = int.tryParse(parts[1]);
      if (hour == null || minute == null) continue;

      final l10n = _l10n();
      final body = privacyMode
          ? l10n.reminderNotificationPrivacyBody
          : [schedule.medicationName, schedule.doseAmountText].whereType<String>().where((v) => v.isNotEmpty).join(' · ');

      await _plugin.zonedSchedule(
        id: schedule.id.hashCode & 0x7fffffff,
        title: l10n.reminderNotificationTitle,
        body: body.isEmpty ? l10n.reminderNotificationPrivacyBody : body,
        scheduledDate: _nextInstance(hour, minute),
        payload: schedule.medicationId,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            'medication-reminders',
            'Medication reminders',
            channelDescription: 'Daily dose reminders from WellWell',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: const DarwinNotificationDetails(presentAlert: true, presentSound: true, presentBanner: true, presentList: true),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
      count++;
    }

    await _scheduleRefills(schedules: active, medications: medications, privacyMode: privacyMode);
    await _scheduleExpiring(medications: medications, privacyMode: privacyMode);

    return ReminderSyncResult(scheduledCount: count, permissionGranted: true);
  }

  // One-off "running low" reminders, a few days before the user's self-reported supply
  // runs out. Best-effort and non-clinical: a bad estimate never blocks dose reminders.
  static Future<void> _scheduleRefills({
    required List<Schedule> schedules,
    required List<Medication> medications,
    required bool privacyMode,
  }) async {
    const leadDays = 3;
    final now = tz.TZDateTime.now(tz.local);

    for (final med in medications) {
      final remaining = med.remainingQuantity;
      if (remaining == null || remaining <= 0) continue;

      final dosesPerDay = schedules.where((s) => s.medicationId == med.id).length;
      if (dosesPerDay <= 0) continue;

      final daysLeft = (remaining / dosesPerDay).floor();
      final remindInDays = max(0, daysLeft - leadDays);

      var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, 9, 0)
          .add(Duration(days: remindInDays));
      // If that moment already passed today, nudge tomorrow morning instead.
      if (!scheduled.isAfter(now)) {
        scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, 9, 0)
            .add(const Duration(days: 1));
      }

      final l10n = _l10n();
      final body = privacyMode
          ? l10n.reminderRefillPrivacyBody
          : l10n.reminderRefillBody(daysLeft, med.displayName);

      await _plugin.zonedSchedule(
        id: (med.id.hashCode ^ 0x5A5A5A5A) & 0x7fffffff,
        title: l10n.reminderRefillNotificationTitle,
        body: body,
        scheduledDate: scheduled,
        payload: med.id,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            'refill-reminders',
            'Refill reminders',
            channelDescription: 'Low-supply refill reminders from WellWell',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: const DarwinNotificationDetails(presentAlert: true, presentSound: true, presentBanner: true, presentList: true),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    }
  }

  // Expiration reminders: a "heads up" one week before the label's expiration date and a
  // separate "expired" alert on the expiration day itself. Best-effort and non-clinical:
  // a missing or unparsable date never blocks dose reminders.
  static Future<void> _scheduleExpiring({
    required List<Medication> medications,
    required bool privacyMode,
  }) async {
    const leadDays = 7;
    final now = tz.TZDateTime.now(tz.local);

    for (final med in medications) {
      final raw = med.expirationDate;
      if (raw == null) continue;
      final expiration = DateTime.tryParse(raw);
      if (expiration == null) continue;

      final dateLabel =
          '${expiration.year}-${expiration.month.toString().padLeft(2, '0')}-${expiration.day.toString().padLeft(2, '0')}';

      // 1) "Expiring soon" — one week before, at 09:00.
      var leadAt = tz.TZDateTime(tz.local, expiration.year, expiration.month, expiration.day, 9, 0)
          .subtract(const Duration(days: leadDays));
      // Already inside the lead window (but not yet expired): nudge tomorrow morning instead of never.
      final expiryMorning = tz.TZDateTime(tz.local, expiration.year, expiration.month, expiration.day, 9, 0);
      if (!leadAt.isAfter(now) && expiryMorning.isAfter(now)) {
        leadAt = tz.TZDateTime(tz.local, now.year, now.month, now.day, 9, 0).add(const Duration(days: 1));
      }
      if (leadAt.isAfter(now)) {
        final l10n = _l10n();
        final body = privacyMode
            ? l10n.reminderExpiringSoonPrivacyBody
            : l10n.reminderExpiringSoonBody(med.displayName, dateLabel);
        await _plugin.zonedSchedule(
          id: (med.id.hashCode ^ 0x3C3C3C3C) & 0x7fffffff,
          title: l10n.reminderExpiringSoonTitle,
          body: body,
          scheduledDate: leadAt,
          payload: med.id,
          notificationDetails: _expirationDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        );
      }

      // 2) "Expired" — on the expiration day at 09:00. Only scheduled when that moment is
      // still in the future; we don't fire retroactive alerts for long-expired items.
      if (expiryMorning.isAfter(now)) {
        final l10n = _l10n();
        final body = privacyMode
            ? l10n.reminderExpiredPrivacyBody
            : l10n.reminderExpiredBody(med.displayName, dateLabel);
        await _plugin.zonedSchedule(
          id: (med.id.hashCode ^ 0x5A5A5A5A) & 0x7fffffff,
          title: l10n.reminderExpiredTitle,
          body: body,
          scheduledDate: expiryMorning,
          payload: med.id,
          notificationDetails: _expirationDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        );
      }
    }
  }

  static const NotificationDetails _expirationDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      'expiration-reminders',
      'Expiration reminders',
      channelDescription: 'Label expiration-date reminders from WellWell',
      importance: Importance.high,
      priority: Priority.high,
    ),
    iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true, presentBanner: true, presentList: true),
  );

  static tz.TZDateTime _nextInstance(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}
