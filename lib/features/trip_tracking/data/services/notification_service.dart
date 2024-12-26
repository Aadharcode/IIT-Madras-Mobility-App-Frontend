import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  static const String baseUrl = 'http://ec2-13-232-246-85.ap-south-1.compute.amazonaws.com/api';

  static Future<void> initialize() async {
    tz.initializeTimeZones();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(settings);
  }

  static Future<void> scheduleNightlyCheck() async {
    final now = DateTime.now();
    var scheduledTime = DateTime(
      now.year,
      now.month,
      now.day,
      21, // 9 PM
      57,
    );

    if (now.isAfter(scheduledTime)) {
      scheduledTime = scheduledTime.add(const Duration(days: 1));
    }

    await _notifications.zonedSchedule(
      0,
      'Unfilled Trip Details',
      'You have trips with missing details. Please complete them.',
      tz.TZDateTime.from(scheduledTime, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'trip_details_reminder',
          'Trip Details Reminder',
          channelDescription: 'Reminds users to fill in missing trip details',
        ),
        iOS: DarwinNotificationDetails(),
      ),
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }
}