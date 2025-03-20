import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:workmanager/workmanager.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io' show Platform;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static const String baseUrl =
      'http://ec2-13-232-246-85.ap-south-1.compute.amazonaws.com/api';

  // Notification Channel creation for Android 8+
  static Future<void> createNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'trip_details_reminder', // Channel ID
      'Trip Details Reminder', // Channel name
      description: 'Reminds users to fill in missing trip details',
      importance: Importance.high,
      playSound: true,
    );

    try {
      await _notifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    } catch (e) {
      print("Error creating notification channel: ${e.toString()}");
    }
  }

  // Initialize the notification service
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
    await createNotificationChannel(); // Ensure the channel is created
    await requestNotificationPermission(); // Request permission if needed
  }

  // Request Notification permission for Android 13+ (API level 33+)
  static Future<void> requestNotificationPermission() async {
    if (Platform.isAndroid && await Permission.notification.isGranted) {
      return; // Notification permission already granted
    } else if (Platform.isAndroid) {
      await Permission.notification
          .request(); // Request notification permission
    }
  }

  // Schedule nightly check notification at 9 PM
  static Future<void> scheduleNightlyCheck() async {
    final now = DateTime.now();
    var scheduledTime = DateTime(
      now.year,
      now.month,
      now.day,
      21, // 9 PM
      00,
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
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  // Background task via WorkManager (to handle scheduling if app is in background)
  static void callbackDispatcher() {
    Workmanager().executeTask((task, inputData) {
      scheduleNightlyCheck(); // Call your scheduling function
      return Future.value(true);
    });
  }

  // Register WorkManager task on app startup
  static Future<void> registerWorkManager() async {
    WidgetsFlutterBinding.ensureInitialized();
    await Workmanager().initialize(callbackDispatcher);
    await Workmanager().registerOneOffTask(
      'id_unique',
      'simpleTask',
      initialDelay: Duration(seconds: 10),
      inputData: <String, dynamic>{'key': 'value'},
    );
  }
  static Future<void> showTripEndedNotification() async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'trip_end_channel',
      'Trip End Notification',
      channelDescription: 'Notifies when a trip ends',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    await _notifications.show(
      1,
      'Trip Ended',
      'Your trip has ended successfully.',
      details,
    );
  }
}