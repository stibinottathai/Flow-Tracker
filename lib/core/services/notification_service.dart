import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'dart:math';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();
    final String timeZoneName =
        (await FlutterTimezone.getLocalTimezone()).identifier;
    tz.setLocalLocation(tz.getLocation(timeZoneName));

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/launcher_icon');

    final DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
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
      },
    );
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
    try {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(scheduledDate, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'period_tracker_channel',
            'Period Tracker Notifications',
            channelDescription: 'Notifications for period tracking',
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: matchDateTimeComponents,
      );
    } catch (e) {
      // Fallback to inexact scheduling if exact alarms are not permitted
      await flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(scheduledDate, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'period_tracker_channel',
            'Period Tracker Notifications',
            channelDescription: 'Notifications for period tracking',
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: matchDateTimeComponents,
      );
    }
  }

  Future<void> schedulePeriodReminders({
    required DateTime lastPeriodDate,
    required int cycleLength,
    required int daysBefore,
  }) async {
    await cancelAllNotifications();

    // Calculate next period
    DateTime nextPeriod = lastPeriodDate.add(Duration(days: cycleLength));
    while (nextPeriod.isBefore(DateTime.now())) {
      nextPeriod = nextPeriod.add(Duration(days: cycleLength));
    }

    DateTime reminderDate = nextPeriod.subtract(Duration(days: daysBefore));

    // If the calculated reminder date is in the past, move to the next cycle
    if (reminderDate.isBefore(DateTime.now())) {
      nextPeriod = nextPeriod.add(Duration(days: cycleLength));
      reminderDate = nextPeriod.subtract(Duration(days: daysBefore));
    }

    // Schedule 3 random notifications on that day
    final random = Random();
    // Define 3 windows: Morning (8-11), Afternoon (12-16), Evening (17-21)
    final times = [
      8 + random.nextInt(4), // 8, 9, 10, 11
      12 + random.nextInt(5), // 12, 13, 14, 15, 16
      17 + random.nextInt(5), // 17, 18, 19, 20, 21
    ];

    for (int i = 0; i < times.length; i++) {
      final hour = times[i];
      final minute = random.nextInt(60);

      final scheduledTime = DateTime(
        reminderDate.year,
        reminderDate.month,
        reminderDate.day,
        hour,
        minute,
      );

      // Ensure we don't schedule in the past
      if (scheduledTime.isBefore(DateTime.now())) {
        continue;
      }

      await scheduleNotification(
        id: i,
        title: 'Period Reminder',
        body: 'Your period is expected in $daysBefore days.',
        scheduledDate: scheduledTime,
      );
    }
  }

  Future<void> cancelNotification(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
  }

  Future<void> cancelAllNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }
}
