import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:iitm_mobility_app/features/trip_tracking/data/services/Monument_services.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/trip.dart';
import '../../data/models/monument.dart';
import '../../data/services/location_service.dart';
import 'trip_event.dart';
import 'package:http/http.dart' as http;
import 'trip_state.dart';
import '../../../authentication/data/services/auth_service.dart';
import 'dart:convert';

class TripBloc extends Bloc<TripEvent, TripState> {
  static const String baseUrl = 'https://temp-backend-mob.onrender.com';
  final authService = AuthService();
  final LocationService _locationService;
  StreamSubscription<Position>? _locationSubscription;
  StreamSubscription<Monument>? _monumentSubscription;
  Timer? _locationTimer;
  Position? _previousPosition;
  List<Map<String, dynamic>> _availableMonuments = [];
  int _stationaryCounter = 0;
  final _uuid = const Uuid();
  Timer? _monumentCheckTimer;
  final Map<String, DateTime> _monumentVisitTimes = {};

  TripBloc({required LocationService locationService})
      : _locationService = locationService,
        super(const TripState()) {
    on<StartTrip>(_onStartTrip);
    on<EndTrip>(_onEndTrip);
    on<UpdateTripDetails>(_onUpdateTripDetails);
    on<MonumentReached>(_onMonumentReached);
    on<LocationUpdated>(_onLocationUpdated);
    on<IdleTimeout>(_onIdleTimeout);
    on<LoadPastTrips>(_onLoadPastTrips);
    on<CheckLocation>(_onCheckLocation);
    on<CheckNearbyMonument>(_onCheckNearbyMonument);

    _initializeLocationTracking();
  }
  void _onLocationUpdated(
    LocationUpdated event,
    Emitter<TripState> emit,
  ) {
    emit(state.copyWith(
      currentLocation: event.location,
      error: null,
    ));
  }

  void _onMonumentReached(
    MonumentReached event,
    Emitter<TripState> emit,
  ) {
    if (state.isActive && state.currentTrip != null) {
      _monumentVisitTimes[event.monument.id] = DateTime.now();

      final monumentVisits = _monumentVisitTimes.entries
          .map((entry) => MonumentVisit(
                monumentId: entry.key,
                timestamp: entry.value,
              ))
          .toList();

      final updatedTrip = state.currentTrip!.copyWith(
        monumentVisits: monumentVisits,
      );

      emit(state.copyWith(
        currentTrip: updatedTrip,
        error: null,
      ));
    }
  }

  void _onIdleTimeout(
    IdleTimeout event,
    Emitter<TripState> emit,
  ) {
    if (state.isActive) {
      add(EndTrip());
    }
  }

  Future<LatLng?> _getUserLocation() async {
    // Check if location services are enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled, return null or handle accordingly
      return null;
    }

    // Request permission to access location
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      // Request permission if not granted yet
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Location permission denied, return null or handle accordingly
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Location permission is permanently denied, return null or handle accordingly
      return null;
    }

    // Fetch the current position (latitude and longitude)
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high, // Set the desired accuracy
    );

    // Return the location as LatLng
    return LatLng(position.latitude, position.longitude);
  }

  Future<void> _initializeLocationTracking() async {
    final hasPermission = await _locationService.requestLocationPermission();
    if (!hasPermission) {
      add(TripErrorOccurred('Location permission denied'));
      return;
    }

    _locationSubscription = _locationService.locationStream.listen(
      (position) {
        add(LocationUpdated(LatLng(position.latitude, position.longitude)));
      },
      onError: (error) {
        print('Location tracking error in bloc: $error');
        // Implement retry logic or error handling as needed
      },
    );

    _monumentSubscription = _locationService.monumentStream.listen(
      (monument) {
        if (state.currentLocation != null) {
          add(MonumentReached(
            monument: monument,
            location: state.currentLocation!,
          ));
        }
      },
    );

    _locationService.startLocationTracking();
  }

  Future<void> _onStartTrip(
    StartTrip event,
    Emitter<TripState> emit,
  ) async {
    print('🚀 Starting _onStartTrip method');

    if (state.isActive == true) {
      print('⚠️ Trip already active, emitting error state');
      emit(state.copyWith(error: 'A trip is already in progress'));
      return;
    }

    try {
      // Periodically check location
      _locationTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
        add(CheckLocation());
      });

      // Start monument checking timer
      _monumentCheckTimer = Timer.periodic(const Duration(seconds: 10), (_) {
        add(CheckNearbyMonument());
      });

      // Create the new trip
      final trip = Trip(
        id: _uuid.v4(),
        userId: event.userId,
        startTime: DateTime.now(),
        startMonumentId: event.startMonument.id,
      );

      print('🚗 Trip Started! 📍');
      print('👤 User ID: ${event.userId}');
      print('🏛️ Start Monument ID: ${event.startMonument.id}');
      print('⏰ Start Time: ${trip.startTime}');

      print('📤 Emitting new state with active trip');
      emit(state.copyWith(
        currentTrip: trip,
        isTracking: true,
        error: null,
        isActive: true,
      ));

      print('✅ State emitted successfully');

      // Verify the state was updated
      print(
          '🔍 New state - isActive: ${state.isActive}, isTracking: ${state.isTracking}');
    } catch (e) {
      print('❌ Error in _onStartTrip: $e');
      emit(state.copyWith(
        error: 'Failed to start trip: $e',
        isActive: false,
        isTracking: false,
      ));
    }
  }

  Future<void> _onEndTrip(
    EndTrip event,
    Emitter<TripState> emit,
  ) async {
    if (state.currentTrip == null) {
      emit(state.copyWith(error: 'No active trip to end'));
      return;
    }

    try {
      emit(state.copyWith(isLoading: true, error: null));

      // Get the current trip with all its details
      final currentTrip = state.currentTrip!;

      // Create the updated trip with the end monument and time
      final endedTrip = currentTrip.copyWith(
        endTime: DateTime.now(),
        isActive: false,
      );

      // Small delay to show loading state
      await Future.delayed(const Duration(milliseconds: 500));

      // Cancel the location timer
      _locationTimer?.cancel();

      // Reset all trip-related state
      emit(state.copyWith(
        pastTrips: [...state.pastTrips, endedTrip],
        isTracking: false,
        isLoading: false,
        error: null,
        currentLocation: state.currentLocation,
        isActive: false,
      ));

      // Reset the current trip state
      emit(state.copyWith(
        currentTrip: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onUpdateTripDetails(
    UpdateTripDetails event,
    Emitter<TripState> emit,
  ) async {
    if (state.currentTrip == null) {
      emit(state.copyWith(error: 'No active trip to update'));
      print('❌ No active trip found. Cannot update trip details.');
      return;
    }

    // Copy the current trip and update the required fields
    final updatedTrip = state.currentTrip!.copyWith(
      vehicleType: event.vehicleType,
      purpose: event.purpose,
      occupancy: event.occupancy,
      monumentVisits: _monumentVisitTimes.entries
          .map((entry) => MonumentVisit(
                monumentId: entry.key,
                timestamp: entry.value,
              ))
          .toList(),
    );

    // Debugging endMonumentId
    print('🔍 Current endMonumentId: ${event.endMonument.id}');

    try {
      // Get token using AuthService instead of SharedPreferences
      final token = await authService.getToken();

      if (token == null) {
        emit(state.copyWith(error: 'Token not found. Please log in again.'));
        return;
      }

      // Prepare the purpose and vehicle type as strings
      String purposeAsString;
      switch (event.purpose) {
        case TripPurpose.class_:
          purposeAsString = 'class';
          break;
        case TripPurpose.work:
          purposeAsString = 'work';
          break;
        case TripPurpose.school:
          purposeAsString = 'school';
          break;
        case TripPurpose.recreation:
          purposeAsString = 'recreation';
          break;
        case TripPurpose.shopping:
          purposeAsString = 'shopping';
          break;
        case TripPurpose.food:
          purposeAsString = 'food';
          break;
      }

      String vehicleTypeAsString;
      switch (event.vehicleType) {
        case VehicleType.walk:
          vehicleTypeAsString = 'walk';
          break;
        case VehicleType.cycle:
          vehicleTypeAsString = 'cycle';
          break;
        case VehicleType.twoWheeler:
          vehicleTypeAsString = 'twoWheeler';
          break;
        case VehicleType.threeWheeler:
          vehicleTypeAsString = 'threeWheeler';
          break;
        case VehicleType.fourWheeler:
          vehicleTypeAsString = 'fourWheeler';
          break;
        case VehicleType.iitmBus:
          vehicleTypeAsString = 'iitmBus';
          break;
      }

      final monumentVisitsJson = _monumentVisitTimes.entries
          .map((entry) => {
                'monument': entry.key,
                'timestamp': entry.value.toIso8601String(),
              })
          .toList();

      // Debugging endMonumentId before sending the request
      print(
          '🔍 endMonumentId before sending to server: ${event.endMonument.id}');

      // Sending the updated trip details to the server with the token in headers
      print('🌐 Sending updated trip details to server: $baseUrl/trip/add');

      final body = jsonEncode({
        'userId': event.userId,
        'startTime': updatedTrip.startTime.toIso8601String(),
        'endTime': DateTime.now().toIso8601String(),
        'startMonumentId': updatedTrip.startMonumentId,
        'endMonumentId': event.endMonument.id,
        'monumentVisits': monumentVisitsJson,
        'purpose': purposeAsString,
        'mode': vehicleTypeAsString,
        'occupancy': event.occupancy,
      });
      print('🌐 $body');
      final response = await http.post(
        Uri.parse('$baseUrl/trip/add'),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization':
              'Bearer $token', // Include the token in the Authorization header
        },
        body: body,
      );

      print('📥 Response status code: ${response.statusCode}');
      print('📥 Response body: ${response.body}');
    } catch (e) {
      // Handle network or request errors
      emit(state.copyWith(error: 'Error adding trip: $e'));
      print('❌ Network or request error: $e');
    }
  }

  Future<void> _onLoadPastTrips(
    LoadPastTrips event,
    Emitter<TripState> emit,
  ) async {
    try {
      emit(state.copyWith(isLoading: true));
      final token = await authService.getToken();

      if (token == null) {
        emit(state.copyWith(
          error: 'Token not found. Please log in again.',
          isLoading: false,
        ));
        return;
      }

      final response = await http.get(
        Uri.parse('$baseUrl/trip/user'),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final tripsJson = jsonDecode(response.body) as List<dynamic>;

        if (tripsJson.isEmpty) {
          emit(state.copyWith(
            pastTrips: [],
            isLoading: false,
          ));
          return;
        }

        final List<Trip> pastTrips = tripsJson.map((tripMap) {
          final tripData = tripMap as Map<String, dynamic>;

          // Handle the monuments array which contains ObjectIds from MongoDB
          List<String> monuments = [];
          if (tripData['monuments'] != null) {
            monuments = (tripData['monuments'] as List)
                .map((monument) => monument.toString())
                .toList();
          }

          print('Processing trip: $tripData');
          print('Purpose from API: ${tripData['purpose']}');
          print('Mode from API: ${tripData['mode']}');

          return Trip(
            id: tripData['_id'] as String,
            userId: tripData['userId'] as String,
            startTime: DateTime.parse(tripData['startTime'] as String),
            endTime: tripData['endTime'] != null
                ? DateTime.parse(tripData['endTime'] as String)
                : null,
            startMonumentId: tripData['startMonumentId']?.toString(),
            endMonumentId: tripData['endMonumentId']?.toString(),
            monuments: monuments.isEmpty ? null : monuments,
            purpose: _parseTripPurpose(tripData['purpose'] as String?),
            vehicleType: _parseVehicleType(tripData['mode'] as String?),
            occupancy: tripData['occupancy'] as int?,
            monumentVisits: (tripData['monumentVisits'] as List?)
                    ?.map((visit) => MonumentVisit(
                          monumentId: visit['monument'].toString(),
                          timestamp:
                              DateTime.parse(visit['timestamp'] as String),
                        ))
                    .toList() ??
                [],
          );
        }).toList();

        emit(state.copyWith(
          pastTrips: pastTrips,
          isLoading: false,
          error: null,
        ));
      } else {
        final errorResponse = jsonDecode(response.body) as Map<String, dynamic>;
        emit(state.copyWith(
          error: errorResponse['message'] as String?,
          isLoading: false,
        ));
      }
    } catch (e) {
      print('Error in _onLoadPastTrips: $e');
      emit(state.copyWith(
        error: 'Error loading past trips: $e',
        isLoading: false,
      ));
    }
  }

  Future<void> _onCheckLocation(
      CheckLocation event, Emitter<TripState> emit) async {
    try {
      final currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (_previousPosition == null) {
        _previousPosition = currentPosition;
        return;
      }

      double distance = Geolocator.distanceBetween(
        _previousPosition!.latitude,
        _previousPosition!.longitude,
        currentPosition.latitude,
        currentPosition.longitude,
      );

      if (distance < 10) {
        _stationaryCounter++;
        emit(state.copyWith(counter: _stationaryCounter.toString()));

        if (_stationaryCounter >= 5) {
          add(EndTrip());
        }
      } else {
        _stationaryCounter = 0;
        _previousPosition = currentPosition;
      }
    } catch (e) {
      emit(state.copyWith(error: 'Error checking location: $e'));
    }
  }

  Future<void> _onCheckNearbyMonument(
    CheckNearbyMonument event,
    Emitter<TripState> emit,
  ) async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final currentLocation = LatLng(position.latitude, position.longitude);

      final nearestMonument =
          await MonumentService.findNearestMonument(currentLocation);

      if (nearestMonument != null) {
        // Only add if not already in the set
        _monumentVisitTimes[nearestMonument.id] = DateTime.now();

        // Update the state with new monuments list
        if (state.currentTrip != null) {
          final updatedTrip = state.currentTrip!.copyWith(
            monumentVisits: _monumentVisitTimes.entries
                .map((entry) => MonumentVisit(
                      monumentId: entry.key,
                      timestamp: entry.value,
                    ))
                .toList(),
          );
          emit(state.copyWith(currentTrip: updatedTrip));
        }
      }
    } catch (e) {
      print('Error checking nearby monument: $e');
    }
  }

  @override
  Future<void> close() {
    _locationTimer?.cancel();
    _locationSubscription?.cancel();
    _monumentSubscription?.cancel();
    _locationService.dispose();
    _monumentCheckTimer?.cancel();
    return super.close();
  }

  TripPurpose _parseTripPurpose(String? purpose) {
    if (purpose == null) return TripPurpose.class_; // default value

    switch (purpose.toLowerCase()) {
      case 'class':
        return TripPurpose.class_;
      case 'work':
        return TripPurpose.work;
      case 'school':
        return TripPurpose.school;
      case 'recreation':
        return TripPurpose.recreation;
      case 'shopping':
        return TripPurpose.shopping;
      case 'food':
        return TripPurpose.food;
      default:
        return TripPurpose.class_; // default value
    }
  }

  VehicleType _parseVehicleType(String? mode) {
    if (mode == null) return VehicleType.walk; // default value

    switch (mode.toLowerCase()) {
      case 'walk':
        return VehicleType.walk;
      case 'cycle':
        return VehicleType.cycle;
      case 'twowheeler':
        return VehicleType.twoWheeler;
      case 'threewheeler':
        return VehicleType.threeWheeler;
      case 'fourwheeler':
        return VehicleType.fourWheeler;
      case 'iitmbus':
        return VehicleType.iitmBus;
      default:
        return VehicleType.walk; // default value
    }
  }
}
