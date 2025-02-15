import 'dart:convert';
import 'dart:math';
import 'package:equatable/equatable.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

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
    this.radius = 100,
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
      radius: json['radius'] ?? 100,
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

// Sample monuments data
List<Monument> sampleMonuments = [];

// Fetch monuments from API and update sampleMonuments
Future<void> fetchMonuments() async {
  const url =
      'http://ec2-13-232-246-85.ap-south-1.compute.amazonaws.com/api/monument/';

  try {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);

      // Update sampleMonuments with the fetched data
      sampleMonuments = data.map((item) {
        return Monument.fromJson(item);
      }).toList();
      print(sampleMonuments);
      print(
          "Loaded Monuments: ${sampleMonuments.map((m) => m.name).join(", ")}");
    } else {
      throw Exception('Failed to load monuments');
    }
  } catch (e) {
    print('Error loading monuments: $e');
    // Handle error if fetching fails, no fallback for local data since we're not using SharedPreferences
  }
}

void main() async {
  await fetchMonuments(); // Fetch and update sampleMonuments
}
