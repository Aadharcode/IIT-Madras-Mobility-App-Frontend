import 'package:equatable/equatable.dart';

enum VehicleType {
  walk,
  cycle,
  twoWheeler,
  threeWheeler,
  fourWheeler,
  iitmBus
}

enum TripPurpose {
  class_,
  work,
  school,
  recreation,
  shopping,
  food
}

class Trip extends Equatable {
  final String id;
  final String userId;
  final DateTime startTime;
  final DateTime? endTime;
  final String startMonumentId;
  final String? endMonumentId;
  final List<TripCheckpoint> checkpoints;
  final VehicleType? vehicleType;
  final TripPurpose? purpose;
  final int? occupancy;
  final bool isActive;

  const Trip({
    required this.id,
    required this.userId,
    required this.startTime,
    this.endTime,
    required this.startMonumentId,
    this.endMonumentId,
    this.checkpoints = const [],
    this.vehicleType,
    this.purpose,
    this.occupancy,
    this.isActive = true,
  });

  Trip copyWith({
    String? id,
    String? userId,
    DateTime? startTime,
    DateTime? endTime,
    String? startMonumentId,
    String? endMonumentId,
    List<TripCheckpoint>? checkpoints,
    VehicleType? vehicleType,
    TripPurpose? purpose,
    int? occupancy,
    bool? isActive,
  }) {
    return Trip(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      startMonumentId: startMonumentId ?? this.startMonumentId,
      endMonumentId: endMonumentId ?? this.endMonumentId,
      checkpoints: checkpoints ?? this.checkpoints,
      vehicleType: vehicleType ?? this.vehicleType,
      purpose: purpose ?? this.purpose,
      occupancy: occupancy ?? this.occupancy,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'startMonumentId': startMonumentId,
      'endMonumentId': endMonumentId,
      'checkpoints': checkpoints.map((c) => c.toJson()).toList(),
      'vehicleType': vehicleType?.index,
      'purpose': purpose?.index,
      'occupancy': occupancy,
      'isActive': isActive,
    };
  }

  factory Trip.fromJson(Map<String, dynamic> json) {
    return Trip(
      id: json['id'],
      userId: json['userId'],
      startTime: DateTime.parse(json['startTime']),
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
      startMonumentId: json['startMonumentId'],
      endMonumentId: json['endMonumentId'],
      checkpoints: (json['checkpoints'] as List)
          .map((c) => TripCheckpoint.fromJson(c))
          .toList(),
      vehicleType: json['vehicleType'] != null
          ? VehicleType.values[json['vehicleType']]
          : null,
      purpose:
          json['purpose'] != null ? TripPurpose.values[json['purpose']] : null,
      occupancy: json['occupancy'],
      isActive: json['isActive'],
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        startTime,
        endTime,
        startMonumentId,
        endMonumentId,
        checkpoints,
        vehicleType,
        purpose,
        occupancy,
        isActive,
      ];
}

class TripCheckpoint extends Equatable {
  final String monumentId;
  final DateTime timestamp;
  final double latitude;
  final double longitude;

  const TripCheckpoint({
    required this.monumentId,
    required this.timestamp,
    required this.latitude,
    required this.longitude,
  });

  Map<String, dynamic> toJson() {
    return {
      'monumentId': monumentId,
      'timestamp': timestamp.toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  factory TripCheckpoint.fromJson(Map<String, dynamic> json) {
    return TripCheckpoint(
      monumentId: json['monumentId'],
      timestamp: DateTime.parse(json['timestamp']),
      latitude: json['latitude'],
      longitude: json['longitude'],
    );
  }

  @override
  List<Object?> get props => [monumentId, timestamp, latitude, longitude];
} 