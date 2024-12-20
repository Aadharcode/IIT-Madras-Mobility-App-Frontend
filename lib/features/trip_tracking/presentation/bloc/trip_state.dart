import 'package:equatable/equatable.dart';
import '../../data/models/trip.dart';
// import '../../data/models/monument.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class TripState extends Equatable {
  final Trip? currentTrip;
  final List<Trip> pastTrips;
  final bool isTracking;
  final bool isLoading;
  final String? error;
  final LatLng? currentLocation;
  final Set<Marker> markers;
  final Set<Circle> monumentZones;
  final bool isActive;
  final String counter;

  const TripState({
    this.currentTrip,
    this.pastTrips = const [],
    this.isTracking = false,
    this.isLoading = false,
    this.error,
    this.currentLocation,
    this.markers = const {},
    this.monumentZones = const {},
    this.isActive = false,
    this.counter = '0',
  });

  TripState copyWith({
    Trip? currentTrip,
    List<Trip>? pastTrips,
    bool? isTracking,
    bool? isLoading,
    String? error,
    LatLng? currentLocation,
    Set<Marker>? markers,
    Set<Circle>? monumentZones,
    bool? isActive,
    String? counter,
  }) {
    return TripState(
      currentTrip: currentTrip ?? this.currentTrip,
      pastTrips: pastTrips ?? this.pastTrips,
      isTracking: isTracking ?? this.isTracking,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      currentLocation: currentLocation ?? this.currentLocation,
      markers: markers ?? this.markers,
      monumentZones: monumentZones ?? this.monumentZones,
      isActive: isActive ?? this.isActive,
      counter: counter ?? this.counter,
    );
  }

  @override
  List<Object?> get props => [
        currentTrip,
        pastTrips,
        isTracking,
        isLoading,
        error,
        currentLocation,
        markers,
        monumentZones,
      ];
} 