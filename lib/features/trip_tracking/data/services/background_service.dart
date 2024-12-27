import 'dart:async';
import 'dart:ui';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'location_service.dart';

class BackgroundService {
  static Future<void> initializeService() async {
    final service = FlutterBackgroundService();

    // Ensure service isn't already running
    if (await service.isRunning()) {
      return;
    }

    // Configure service before starting
    await service.configure(
      iosConfiguration: IosConfiguration(
        autoStart: true,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: true,
        isForegroundMode: true,
        notificationChannelId: 'location_service',
        initialNotificationTitle: 'IITM Mobility Service',
        initialNotificationContent: 'Starting service...',
        foregroundServiceNotificationId: 888,
        // notificationChannelName: 'Location Service',
        // notificationChannelDescription: 'Location tracking service running',
        // notificationChannelImportance: 4, // Max importance
      ),
    );

    // Start the service
    await service.startService();
  }

  @pragma('vm:entry-point')
  static Future<bool> onIosBackground(ServiceInstance service) async {
    try {
      final locationService = LocationService();
      await locationService.requestLocationPermission();
      // await locationService.startLocationTracking();
      return true;
    } catch (e) {
      print('iOS background service error: $e');
      return false;
    }
  }

  @pragma('vm:entry-point')
  static void onStart(ServiceInstance service) async {
    // This is important to handle the Flutter Engine lifecycle
    DartPluginRegistrant.ensureInitialized();

    if (service is AndroidServiceInstance) {
      // Set as foreground immediately with initial notification
      await service.setAsForegroundService().then((_) async {
        // Update notification after setting foreground
        await service.setForegroundNotificationInfo(
          title: "IITM Mobility App",
          content: "Location tracking active",
        );
      });
    }

    try {
      final locationService = LocationService();

      // Request permissions and start tracking
      final hasPermission = await locationService.requestLocationPermission();
      if (hasPermission) {
       // await locationService.startLocationTracking();

        // Periodic updates
        Timer.periodic(const Duration(minutes: 15), (timer) async {
          if (service is AndroidServiceInstance) {
            await service.setForegroundNotificationInfo(
              title: "IITM Mobility App",
              content:
                  "Location tracking active - ${DateTime.now().toString()}",
            );
          }
        });
      } else {
        if (service is AndroidServiceInstance) {
          await service.setForegroundNotificationInfo(
            title: "IITM Mobility App",
            content: "Location permission denied",
          );
        }
      }
    } catch (e) {
      print('Background service error: $e');
      if (service is AndroidServiceInstance) {
        await service.setForegroundNotificationInfo(
          title: "IITM Mobility App",
          content: "Error in location tracking",
        );
      }
    }
  }
}
