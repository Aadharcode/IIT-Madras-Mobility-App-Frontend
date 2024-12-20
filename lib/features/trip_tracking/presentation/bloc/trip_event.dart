import 'package:equatable/equatable.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../data/models/trip.dart';
import '../../data/models/monument.dart';

abstract class TripEvent extends Equatable {
  const TripEvent();

  @override
  List<Object?> get props => [];
}

class StartTrip extends TripEvent {
  final String userId;
  final Monument startMonument;

  const StartTrip({
    required this.userId,
    required this.startMonument,
  });

  @override
  List<Object> get props => [userId, startMonument];
}

class EndTrip extends TripEvent {


  @override
  List<Object> get props => [];
}

class UpdateTripDetails extends TripEvent {
  final VehicleType vehicleType;
  final TripPurpose purpose;
  final int? occupancy;
  final List<Monument>? selectedMonuments;
  final String userId;
  final Monument endMonument;

  const UpdateTripDetails({
    required this.vehicleType,
    required this.purpose,
    this.occupancy,
    this.selectedMonuments,
    required this.userId,
    required this.endMonument,
  });

  @override
  List<Object?> get props => [vehicleType, purpose, occupancy, selectedMonuments];
}

class MonumentReached extends TripEvent {
  final Monument monument;
  final LatLng location;

  const MonumentReached({
    required this.monument,
    required this.location,
  });

  @override
  List<Object> get props => [monument, location];
}

class LocationUpdated extends TripEvent {
  final LatLng location;

  const LocationUpdated(this.location);

  @override
  List<Object> get props => [location];
}

class IdleTimeout extends TripEvent {}

class LoadPastTrips extends TripEvent {
  final String userId;

  const LoadPastTrips(this.userId);

  @override
  List<Object> get props => [userId];
} 

class TripErrorOccurred extends TripEvent {
  final String error;

  const TripErrorOccurred(this.error);
}

class CheckLocation extends TripEvent {
  @override
  List<Object?> get props => [];
}
