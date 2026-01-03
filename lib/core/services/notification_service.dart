import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'dart:math';
import 'package:flutter/foundation.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();
    final timeZoneInfo = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZoneInfo.identifier));

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/launcher_icon');

    final DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    final InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsDarwin,
          macOS: initializationSettingsDarwin,
        );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        // Handle notification tap
        debugPrint('Notification tapped: ${response.payload}');
      },
      onDidReceiveBackgroundNotificationResponse:
          _notificationBackgroundHandler,
    );

    // Create notification channel for Android
    await _createNotificationChannel();
  }

  @pragma('vm:entry-point')
  static void _notificationBackgroundHandler(NotificationResponse response) {
    debugPrint('Background notification received: ${response.payload}');
  }

  Future<void> _createNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'period_tracker_channel',
      'Period Tracker Notifications',
      description: 'Notifications for period tracking reminders',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
  }

  Future<void> requestPermissions() async {
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    final androidImplementation = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    await androidImplementation?.requestNotificationsPermission();
    await androidImplementation?.requestExactAlarmsPermission();
  }

  Future<void> showInstantNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
          'period_tracker_channel',
          'Period Tracker Notifications',
          channelDescription: 'Notifications for period tracking',
          importance: Importance.max,
          priority: Priority.high,
        );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: DarwinNotificationDetails(),
    );

    await flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      notificationDetails,
    );
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    DateTimeComponents? matchDateTimeComponents,
  }) async {
    final tz.TZDateTime scheduledTZ = tz.TZDateTime.from(
      scheduledDate,
      tz.local,
    );

    debugPrint('Scheduling notification ID: $id at $scheduledTZ');

    try {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        scheduledTZ,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'period_tracker_channel',
            'Period Tracker Notifications',
            channelDescription: 'Notifications for period tracking',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
            visibility: NotificationVisibility.public,
            category: AndroidNotificationCategory.reminder,
            fullScreenIntent: true,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: matchDateTimeComponents,
      );
      debugPrint('Successfully scheduled notification ID: $id');
    } catch (e) {
      debugPrint('Error scheduling exact notification: $e. Trying inexact...');
      // Fallback to inexact scheduling if exact alarms are not permitted
      await flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        scheduledTZ,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'period_tracker_channel',
            'Period Tracker Notifications',
            channelDescription: 'Notifications for period tracking',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
            visibility: NotificationVisibility.public,
            category: AndroidNotificationCategory.reminder,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: matchDateTimeComponents,
      );
      debugPrint('Scheduled inexact notification ID: $id');
    }
  }

  Future<void> schedulePeriodReminders({
    required DateTime lastPeriodDate,
    required int cycleLength,
    required int daysBefore,
  }) async {
    await requestPermissions();
    await cancelAllNotifications();

    // Calculate next period
    DateTime nextPeriod = lastPeriodDate.add(Duration(days: cycleLength));
    final now = DateTime.now();

    while (nextPeriod.isBefore(now) || nextPeriod.isAtSameMomentAs(now)) {
      nextPeriod = nextPeriod.add(Duration(days: cycleLength));
    }

    DateTime reminderDate = nextPeriod.subtract(Duration(days: daysBefore));

    // If the calculated reminder date is in the past or today, move to the next cycle
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

    debugPrint('Next period: $nextPeriod');
    debugPrint('Reminder date: $reminderDate');

    // Schedule 3 notifications on that day at fixed times for reliability
    // Morning (9:00), Afternoon (14:00), Evening (19:00)
    final times = [
      {'hour': 9, 'minute': 0},
      {'hour': 14, 'minute': 0},
      {'hour': 19, 'minute': 0},
    ];

    int scheduledCount = 0;

    for (int i = 0; i < times.length; i++) {
      final hour = times[i]['hour']!;
      final minute = times[i]['minute']!;

      DateTime scheduledTime = DateTime(
        reminderDate.year,
        reminderDate.month,
        reminderDate.day,
        hour,
        minute,
      );

      // If today is the reminder day and the time has passed, skip
      if (scheduledTime.isBefore(now)) {
        debugPrint('Skipping notification at $scheduledTime (in past)');
        continue;
      }

      await scheduleNotification(
        id: 100 + i, // Use higher IDs to avoid conflicts
        title: 'Period Reminder 🩸',
        body:
            'Your period is expected in $daysBefore day${daysBefore > 1 ? 's' : ''}. Stay prepared!',
        scheduledDate: scheduledTime,
      );
      scheduledCount++;
    }

    debugPrint('Scheduled $scheduledCount reminder notifications');
  }

  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    final pending = await flutterLocalNotificationsPlugin
        .pendingNotificationRequests();
    debugPrint('Pending notifications: ${pending.length}');
    for (var notification in pending) {
      debugPrint('  - ID: ${notification.id}, Title: ${notification.title}');
    }
    return pending;
  }

  Future<void> cancelNotification(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
  }

  Future<void> cancelAllNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }
}
