import 'package:equatable/equatable.dart';

enum VehicleType { walk, cycle, twoWheeler, threeWheeler, fourWheeler, iitmBus }

enum TripPurpose { class_, work, school, recreation, shopping, food }

class MonumentVisit {
  final String monumentId;
  final DateTime timestamp;

  MonumentVisit({
    required this.monumentId,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'monumentId': monumentId,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

class Trip extends Equatable {
  final String id;
  final String userId;
  final DateTime startTime;
  final DateTime? endTime;
  final String? startMonumentId;
  final String? endMonumentId;
  final List<String>? monuments;
  final List<TripCheckpoint> checkpoints;
  final VehicleType? vehicleType;
  final TripPurpose? purpose;
  final int? occupancy;
  final bool isActive;
  final List<MonumentVisit> monumentVisits;

  const Trip({
    required this.id,
    required this.userId,
    required this.startTime,
    this.endTime,
    this.startMonumentId,
    this.monuments,
    this.endMonumentId,
    this.checkpoints = const [],
    this.vehicleType,
    this.purpose,
    this.occupancy,
    this.isActive = true,
    this.monumentVisits = const [],
  });

  Trip copyWith({
    String? id,
    String? userId,
    DateTime? startTime,
    DateTime? endTime,
    String? startMonumentId,
    String? endMonumentId,
    List<String>? monuments,
    List<TripCheckpoint>? checkpoints,
    VehicleType? vehicleType,
    TripPurpose? purpose,
    int? occupancy,
    bool? isActive,
    List<MonumentVisit>? monumentVisits,
  }) {
    return Trip(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      startMonumentId: startMonumentId ?? this.startMonumentId,
      endMonumentId: endMonumentId ?? this.endMonumentId,
      monuments: monuments ?? this.monuments,
      checkpoints: checkpoints ?? this.checkpoints,
      vehicleType: vehicleType ?? this.vehicleType,
      purpose: purpose ?? this.purpose,
      occupancy: occupancy ?? this.occupancy,
      isActive: isActive ?? this.isActive,
      monumentVisits: monumentVisits ?? this.monumentVisits,
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
      'monumentVisits': monumentVisits.map((mv) => mv.toJson()).toList(),
    };
  }

  factory Trip.fromJson(Map<String, dynamic> json) {
    print('🌐 Monument Visits: ${json['monumentVisits']}');
    return Trip(
      id: json['id'],
      userId: json['userId'],
      startTime: DateTime.parse(json['startTime']),
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
      startMonumentId: json['startMonumentId'],
      endMonumentId: json['endMonumentId'],
      monuments: (json['monuments'] as List)
          .map((c) => c as String) // Cast each item to String
          .toList(),
      checkpoints: (json['checkpoints'] as List)
          .map((c) => TripCheckpoint.fromJson(c))
          .toList(),
      vehicleType: json['vehicleType'] != null
          ? VehicleType.values[json['vehicleType']]
          : null,
      purpose:
          json['purpose'] != null ? TripPurpose.values[json['purpose']] : null,
      occupancy: json['occupancy'] != null
          ? int.parse(json['occupancy'].toString())
          : null,
      isActive: json['isActive'],
      monumentVisits: (json['monumentVisits'] as List?)
              ?.map((mv) => MonumentVisit(
                    monumentId: mv['monument'].toString(),
                    timestamp: DateTime.parse(mv['timestamp']),
                  ))
              .toList() ??
          [],
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
        monumentVisits,
      ];
}

class TripCheckpoint extends Equatable {
  final String id;
  final String? monumentName;
  final DateTime? timestamp;
  final double? lat;
  final double? lng;

  const TripCheckpoint({
    required this.id,
    this.monumentName,
    this.timestamp,
    this.lat,
    this.lng,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'monumentName': monumentName,
      'timestamp': timestamp!.toIso8601String(),
      'latitude': lat,
      'longitude': lng,
    };
  }

  factory TripCheckpoint.fromJson(Map<String, dynamic> json) {
    return TripCheckpoint(
      id: json['Id'],
      monumentName: json['monumentName'],
      timestamp: DateTime.parse(json['timestamp']),
      lat: json['latitude'],
      lng: json['longitude'],
    );
  }

  @override
  List<Object?> get props => [id, monumentName, timestamp, lat, lng];
}
