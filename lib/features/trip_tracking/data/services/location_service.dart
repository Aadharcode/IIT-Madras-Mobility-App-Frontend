import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:geolocator_android/geolocator_android.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/monument.dart';
import 'dart:io';

class LocationService {
  static const Duration locationUpdateInterval = Duration(seconds: 10);
  static const Duration idleTimeout = Duration(minutes: 15);

  final _locationController = StreamController<Position>.broadcast();
  final _monumentController = StreamController<Monument>.broadcast();
  Timer? _idleTimer;
  DateTime? _lastLocationUpdate;
  Position? _lastPosition;

  Stream<Position> get locationStream => _locationController.stream;
  Stream<Monument> get monumentStream => _monumentController.stream;

  Future<bool> requestLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }
    // Request background permission separately
    if (permission == LocationPermission.whileInUse) {
      permission = await Geolocator.requestPermission();
    }

    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  Future<Position?> getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      _lastPosition = position;
      _lastLocationUpdate = DateTime.now();
      return position;
    } catch (e) {
      return null;
    }
  }

void startLocationTracking() {
  final LocationSettings locationSettings = Platform.isIOS 
      ? AppleSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
          activityType: ActivityType.fitness,
          allowBackgroundLocationUpdates: true,
          pauseLocationUpdatesAutomatically: false,
        )
      : AndroidSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
          intervalDuration: locationUpdateInterval,
          foregroundNotificationConfig: const ForegroundNotificationConfig(
            notificationTitle: "IITM Mobility App",
            notificationText: "Tracking your trip in background",
            enableWakeLock: true,
          ),
        );

  Geolocator.getPositionStream(locationSettings: locationSettings)
      .listen((Position position) {
    _handleLocationUpdate(position);
  }, onError: (error) {
    print('Location tracking error: $error');
    // Implement error recovery logic here
  });
}

  void _handleLocationUpdate(Position position) {
    _lastPosition = position;
    final now = DateTime.now();
    _lastLocationUpdate = now;
    _locationController.add(position);

    // Reset idle timer
    _idleTimer?.cancel();
    _idleTimer = Timer(idleTimeout, _onIdle);

    // Check for monuments
    _checkMonuments(position);
  }

  void _checkMonuments(Position position) {
    final currentLocation = LatLng(position.latitude, position.longitude);

    for (final monument in sampleMonuments) {
      if (monument.isInRange(currentLocation)) {
        _monumentController.add(monument);
        break;
      }
    }
  }

  void _onIdle() {
    // Notify that the user has been idle
    // This will be handled by the trip tracking bloc
  }

  bool isIdle() {
    if (_lastLocationUpdate == null || _lastPosition == null) return true;
    return DateTime.now().difference(_lastLocationUpdate!) >= idleTimeout;
  }

  void dispose() {
    _locationController.close();
    _monumentController.close();
    _idleTimer?.cancel();
  }
}
