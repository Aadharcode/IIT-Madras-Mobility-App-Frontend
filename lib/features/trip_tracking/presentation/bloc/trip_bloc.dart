import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/trip.dart';
import '../../data/models/monument.dart';
import '../../data/services/location_service.dart';
import 'trip_event.dart';
import 'package:http/http.dart' as http;
import 'trip_state.dart';
import '../../../authentication/data/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';


class TripBloc extends Bloc<TripEvent, TripState> {
  static const String baseUrl = 'http://192.168.162.250:3000';
  final authService = AuthService();
  final LocationService _locationService;
  StreamSubscription<Position>? _locationSubscription;
  StreamSubscription<Monument>? _monumentSubscription;
  Timer? _locationTimer;
  Position? _previousPosition;
  List<Map<String, dynamic>> _availableMonuments = [];
  int _stationaryCounter = 0;
  final _uuid = const Uuid();

  TripBloc({required LocationService locationService})
      : _locationService = locationService,
        super(const TripState()) {
    on<StartTrip>(_onStartTrip);
    on<EndTrip>(_onEndTrip);
    on<UpdateTripDetails>(_onUpdateTripDetails);
    // on<MonumentReached>(_onMonumentReached);
    // on<LocationUpdated>(_onLocationUpdated);
    // on<IdleTimeout>(_onIdleTimeout);
    on<LoadPastTrips>(_onLoadPastTrips);
    on<CheckLocation>(_onCheckLocation);

    _initializeLocationTracking();
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
    if (state.isActive == true) {
      emit(state.copyWith(error: 'A trip is already in progress'));
      return;
    }

    // Periodically check location
    _locationTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      add(CheckLocation());
    });

    // Create the new trip, including startTime, startMonumentId, and userId
    final trip = Trip(
      id: _uuid.v4(),
      userId: event.userId, // User ID from the event
      startTime: DateTime.now(), // Store the current time as the start time
      startMonumentId: event.startMonument.id, // Get the startMonumentId from the event
    );

    // Print details with emojis for better clarity
    print('🚗 Trip Started! 📍');
    print('👤 User ID: ${event.userId}');
    print('🏛️ Start Monument ID: ${event.startMonument.id}');
    print('⏰ Start Time: ${trip.startTime}');

    emit(state.copyWith(
      currentTrip: trip,
      isTracking: true,
      error: null,
      isActive: true,
    ));
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
  );

  // Debugging endMonumentId
  print('🔍 Current endMonumentId: ${event.endMonument.id}'); 

  try {
    // Retrieve the token
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

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

    // Convert the monument IDs to _id
    List<Map<String, dynamic>> monumentsJson = [];
    if (event.selectedMonuments?.isNotEmpty ?? false) {
      monumentsJson = event.selectedMonuments!.map((monument) {
        // Convert each monument's id to _id
        return {
          '_id': monument.id, // Replace 'id' with '_id'
        };
      }).toList();
    }

    // Debugging endMonumentId before sending the request
    print('🔍 endMonumentId before sending to server: ${event.endMonument.id}'); 

    // Sending the updated trip details to the server with the token in headers
    print('🌐 Sending updated trip details to server: $baseUrl/trip/add');

    final body = jsonEncode({
        'userId': event.userId,
        'startTime': updatedTrip.startTime.toIso8601String(),
        'endTime': DateTime.now().toIso8601String(), 
        'startMonumentId': updatedTrip.startMonumentId,
        'endMonumentId': event.endMonument.id,  
        'monuments': monumentsJson, 
        'purpose': purposeAsString,
        'mode': vehicleTypeAsString,
      });
    print('🌐 $body');
    final response = await http.post(
      Uri.parse('$baseUrl/trip/add'),
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token', // Include the token in the Authorization header
      },
      body: body,
    );

    print('📥 Response status code: ${response.statusCode}');
    print('📥 Response body: ${response.body}');

    
      
    } 
  catch (e) {
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
    // Using a hardcoded token for now
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      emit(state.copyWith(error: 'Token not found. Please log in again.'));
      return;
    }
    final response = await http.get(
      Uri.parse('$baseUrl/trip/user'),
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final tripsJson = jsonDecode(response.body) as List<dynamic>;

      // Check if tripsJson is empty
      if (tripsJson.isEmpty) {
        emit(state.copyWith(error: 'No past trips found.'));
        return;
      }

      // Map each trip JSON to the Trip model
      final List<Trip> pastTrips = tripsJson.map((tripMap) {
        final tripData = tripMap as Map<String, dynamic>;

        final monuments = (tripData['monuments'] as List<dynamic>)
            .map((monumentId) => monumentId as String)
            .toList();

        final trip = Trip(
          id: tripData['_id'] as String,
          userId: tripData['userId'] as String,
          startTime: DateTime.parse(tripData['startTime'] as String),
          endTime: tripData['endTime'] != null
              ? DateTime.parse(tripData['endTime'] as String)
              : null,
          startMonumentId: tripData['startMonumentId'] as String?,
          endMonumentId: tripData['endMonumentId'] as String?,
          monuments: monuments.isEmpty ? null : monuments,
          purpose: TripPurpose.values.firstWhere(
            (e) => e.toString().split('.').last == tripData['purpose'],
          ),
          vehicleType: VehicleType.values.firstWhere(
            (e) => e.toString().split('.').last == tripData['mode'],
          ),
        );
        print('check 1');
        return trip;
      }).toList();
        print('check 2');
      emit(state.copyWith(
        pastTrips: pastTrips,
        error: null,
      ));
    } else {
      final errorResponse = jsonDecode(response.body) as Map<String, dynamic>;
      emit(state.copyWith(error: errorResponse['message'] as String?));
    }
  } catch (e) {
    emit(state.copyWith(error: 'Error loading past trips: $e'));
  }
}


  Future<void> _onCheckLocation(CheckLocation event, Emitter<TripState> emit) async {
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

  @override
  Future<void> close() {
     _locationTimer?.cancel();
    _locationSubscription?.cancel();
    _monumentSubscription?.cancel();
    _locationService.dispose();
    return super.close();
  }
}
