import 'dart:math';
import 'package:equatable/equatable.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class Monument extends Equatable {
  final String id;
  final String name;
  final LatLng position;
  final double radius; // in meters
  final String? description;

  const Monument({
    required this.id,
    required this.name,
    required this.position,
    this.radius = 50, // default radius of 50 meters
    this.description,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'latitude': position.latitude,
      'longitude': position.longitude,
      'radius': radius,
      'description': description,
    };
  }

  factory Monument.fromJson(Map<String, dynamic> json) {
    return Monument(
      id: json['id'],
      name: json['name'],
      position: LatLng(json['latitude'], json['longitude']),
      radius: json['radius'] ?? 50,
      description: json['description'],
    );
  }

  bool isInRange(LatLng point) {
    // Using the Haversine formula to calculate distance
    const double earthRadius = 6371000; // Earth's radius in meters

    double lat1 = position.latitude * (pi / 180);
    double lat2 = point.latitude * (pi / 180);
    double dLat = (point.latitude - position.latitude) * (pi / 180);
    double dLon = (point.longitude - position.longitude) * (pi / 180);

    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    double distance = earthRadius * c;

    return distance <= radius;
  }

  @override
  List<Object?> get props => [id, name, position, radius, description];
}

// Sample monuments data (to be replaced with actual data)
final List<Monument> sampleMonuments = [
  const Monument(
    id: 'gate1',
    name: 'Main Gate',
    position: LatLng(12.991214, 80.233276),
  ),
  const Monument(
    id: 'gate2',
    name: 'Krishna Hostel',
    position: LatLng(12.986681, 80.237733),
  ),
  // Add more monuments as needed
];
