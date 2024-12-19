import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/trip.dart';
import '../../data/models/monument.dart';
import '../../data/services/location_service.dart';
import 'trip_event.dart';
import 'trip_state.dart';

class TripBloc extends Bloc<TripEvent, TripState> {
  final LocationService _locationService;
  StreamSubscription<Position>? _locationSubscription;
  StreamSubscription<Monument>? _monumentSubscription;
  Timer? _locationTimer;
  Position? _previousPosition;
  int _stationaryCounter = 0;
  final _uuid = const Uuid();

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

    _initializeLocationTracking();
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
    _locationTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      add(CheckLocation());
    });

    final trip = Trip(
      id: _uuid.v4(),
      userId: event.userId,
      startTime: DateTime.now(),
      startMonumentId: event.startMonument.id,
      checkpoints: const [],
    );

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
      final currentTrips = state.currentTrip!;
      
      final endedTrip = currentTrips.copyWith(
        endTime: DateTime.now(),
        endMonumentId: event.endMonument.id,
        isActive: false,
      );

      // Add a small delay to show loading state
      await Future.delayed(const Duration(milliseconds: 500));
       _locationTimer?.cancel();
      // Reset all trip-related state
      emit(state.copyWith(
        pastTrips: [...state.pastTrips, endedTrip],
        isTracking: false,
        isLoading: false,
        error: null,
        currentLocation: state.currentLocation, 
        isActive: false
      ));
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
      return;
    }

    final updatedTrip = state.currentTrip!.copyWith(
      vehicleType: event.vehicleType,
      purpose: event.purpose,
      occupancy: event.occupancy,
    );

    emit(state.copyWith(
      currentTrip: updatedTrip,
      error: null,
    ));
  }

  Future<void> _onMonumentReached(
    MonumentReached event,
    Emitter<TripState> emit,
  ) async {
    if (state.currentTrip == null) return;

    final checkpoint = TripCheckpoint(
      monumentId: event.monument.id,
      timestamp: DateTime.now(),
      latitude: event.location.latitude,
      longitude: event.location.longitude,
    );

    final updatedTrip = state.currentTrip!.copyWith(
      checkpoints: [...state.currentTrip!.checkpoints, checkpoint],
    );

    emit(state.copyWith(
      currentTrip: updatedTrip,
      error: null,
    ));
  }

  Future<void> _onLocationUpdated(
    LocationUpdated event,
    Emitter<TripState> emit,
  ) async {
    emit(state.copyWith(
      currentLocation: event.location,
      error: null,
    ));
  }

  Future<void> _onIdleTimeout(
    IdleTimeout event,
    Emitter<TripState> emit,
  ) async {
    if (state.currentTrip != null) {
      // Auto-end the trip if it's been idle for too long
      final lastCheckpoint = state.currentTrip!.checkpoints.lastOrNull;
      if (lastCheckpoint != null) {
        add(EndTrip(
          endMonument: sampleMonuments.firstWhere(
            (m) => m.id == lastCheckpoint.monumentId,
          ),
        ));
      }
    }
  }

  Future<void> _onLoadPastTrips(
    LoadPastTrips event,
    Emitter<TripState> emit,
  ) async {
    // TODO: Implement loading past trips from storage
    emit(state.copyWith(
      pastTrips: [], // Load from storage
      error: null,
    ));
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
          add(EndTrip(endMonument: sampleMonuments.last));
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
