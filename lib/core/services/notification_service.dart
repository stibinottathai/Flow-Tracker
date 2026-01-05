import 'package:flutter/foundation.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io' show Platform;

// Top-level callback function for alarm manager
@pragma('vm:entry-point')
void alarmCallback() {
  debugPrint('🔔 Alarm triggered! Period reminder notification');
  // The alarm has triggered - in a real app, you could show a notification here
  // For now, we're just using alarms to track the reminders
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static const String _lastPeriodKey = 'last_period_date';
  static const String _cycleLengthKey = 'cycle_length';
  static const String _daysBeforeKey = 'days_before_reminder';
  static const String _alarmIdsKey = 'scheduled_alarm_ids';

  Future<void> init() async {
    // Initialize android_alarm_manager_plus only on Android
    if (Platform.isAndroid) {
      try {
        await AndroidAlarmManager.initialize();
        debugPrint('✅ Android Alarm Manager initialized successfully');
      } catch (e) {
        debugPrint('❌ Error initializing Android Alarm Manager: $e');
      }
    } else {
      debugPrint('⚠️ Android Alarm Manager is only supported on Android');
    }
  }

  Future<void> requestPermissions() async {
    // Android alarm manager permissions are handled in AndroidManifest
    // No runtime permissions needed for exact alarms on Android 12 and below
    // For Android 13+, SCHEDULE_EXACT_ALARM permission is automatically granted
    debugPrint('✅ Alarm permissions configured in AndroidManifest');
  }

  Future<void> schedulePeriodReminders({
    required DateTime lastPeriodDate,
    required int cycleLength,
    required int daysBefore,
  }) async {
    if (!Platform.isAndroid) {
      debugPrint('⚠️ Reminders are only supported on Android');
      return;
    }

    await cancelAllNotifications();

    // Save settings to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastPeriodKey, lastPeriodDate.toIso8601String());
    await prefs.setInt(_cycleLengthKey, cycleLength);
    await prefs.setInt(_daysBeforeKey, daysBefore);

    // Calculate next period
    DateTime nextPeriod = lastPeriodDate.add(Duration(days: cycleLength));
    final now = DateTime.now();

    while (nextPeriod.isBefore(now) || nextPeriod.isAtSameMomentAs(now)) {
      nextPeriod = nextPeriod.add(Duration(days: cycleLength));
    }

    DateTime reminderDate = nextPeriod.subtract(Duration(days: daysBefore));

    // If the calculated reminder date is in the past, move to the next cycle
    final today = DateTime(now.year, now.month, now.day);
    final reminderDay = DateTime(
      reminderDate.year,
      reminderDate.month,
      reminderDate.day,
    );

    if (reminderDay.isBefore(today)) {
      nextPeriod = nextPeriod.add(Duration(days: cycleLength));
      reminderDate = nextPeriod.subtract(Duration(days: daysBefore));
    }

    debugPrint('📅 Next period: $nextPeriod');
    debugPrint('⏰ Reminder date: $reminderDate');

    // Schedule 3 reminders on that day
    // Morning (9:00 AM), Afternoon (2:00 PM), Evening (7:00 PM)
    final times = [
      {'hour': 9, 'minute': 0, 'label': 'Morning'},
      {'hour': 14, 'minute': 0, 'label': 'Afternoon'},
      {'hour': 19, 'minute': 0, 'label': 'Evening'},
    ];

    List<int> scheduledAlarmIds = [];

    for (int i = 0; i < times.length; i++) {
      final hour = times[i]['hour'] as int;
      final minute = times[i]['minute'] as int;
      final label = times[i]['label'] as String;

      DateTime scheduledTime = DateTime(
        reminderDate.year,
        reminderDate.month,
        reminderDate.day,
        hour,
        minute,
      );

      // If the time has passed, skip this reminder
      if (scheduledTime.isBefore(now)) {
        debugPrint('⏭️ Skipping $label reminder at $scheduledTime (in past)');
        continue;
      }

      final alarmId = 1000 + i; // Use unique IDs for each alarm
      final success = await AndroidAlarmManager.oneShotAt(
        scheduledTime,
        alarmId,
        alarmCallback,
        exact: true,
        wakeup: true,
        rescheduleOnReboot: true,
      );

      if (success) {
        scheduledAlarmIds.add(alarmId);
        debugPrint(
          '✅ Scheduled $label reminder (ID: $alarmId) at $scheduledTime',
        );
      } else {
        debugPrint('❌ Failed to schedule $label reminder at $scheduledTime');
      }
    }

    // Save scheduled alarm IDs
    await prefs.setStringList(
      _alarmIdsKey,
      scheduledAlarmIds.map((id) => id.toString()).toList(),
    );

    debugPrint('🎯 Scheduled ${scheduledAlarmIds.length} reminder(s)');
  }

  Future<List<int>> getScheduledAlarmIds() async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList(_alarmIdsKey) ?? [];
    return ids.map((id) => int.parse(id)).toList();
  }

  Future<void> cancelNotification(int id) async {
    if (!Platform.isAndroid) return;

    await AndroidAlarmManager.cancel(id);
    debugPrint('🚫 Cancelled alarm ID: $id');
  }

  Future<void> cancelAllNotifications() async {
    if (!Platform.isAndroid) return;

    final scheduledIds = await getScheduledAlarmIds();

    for (final id in scheduledIds) {
      await AndroidAlarmManager.cancel(id);
    }

    // Clear saved alarm IDs
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_alarmIdsKey);

    debugPrint('🚫 Cancelled all ${scheduledIds.length} alarm(s)');
  }

  Future<Map<String, dynamic>?> getSavedReminderSettings() async {
    final prefs = await SharedPreferences.getInstance();

    final lastPeriodStr = prefs.getString(_lastPeriodKey);
    final cycleLength = prefs.getInt(_cycleLengthKey);
    final daysBefore = prefs.getInt(_daysBeforeKey);

    if (lastPeriodStr == null || cycleLength == null || daysBefore == null) {
      return null;
    }

    return {
      'lastPeriodDate': DateTime.parse(lastPeriodStr),
      'cycleLength': cycleLength,
      'daysBefore': daysBefore,
    };
  }

  // For testing purposes - show an instant notification
  Future<void> showInstantNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    if (!Platform.isAndroid) {
      debugPrint('⚠️ Instant notifications only supported on Android');
      return;
    }

    // Schedule an alarm 2 seconds from now for testing
    final scheduledTime = DateTime.now().add(const Duration(seconds: 2));

    final success = await AndroidAlarmManager.oneShotAt(
      scheduledTime,
      id,
      alarmCallback,
      exact: true,
      wakeup: true,
    );

    if (success) {
      debugPrint('✅ Test alarm scheduled for $scheduledTime');
    } else {
      debugPrint('❌ Failed to schedule test alarm');
    }
  }

  // Get pending notifications (for UI display)
  Future<List<Map<String, dynamic>>> getPendingNotifications() async {
    final scheduledIds = await getScheduledAlarmIds();
    final settings = await getSavedReminderSettings();

    if (settings == null) {
      return [];
    }

    final notifications = <Map<String, dynamic>>[];

    for (final id in scheduledIds) {
      notifications.add({
        'id': id,
        'title': 'Period Reminder',
        'body': 'Your period is expected in ${settings['daysBefore']} day(s)',
      });
    }

    return notifications;
  }
}
