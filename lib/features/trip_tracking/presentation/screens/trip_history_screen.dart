import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import '../../data/models/trip.dart';
import '../../data/models/monument.dart';
import '../bloc/trip_bloc.dart';
import '../bloc/trip_event.dart';
import '../bloc/trip_state.dart';

class TripHistoryScreen extends StatelessWidget {
  final String userId;

  const TripHistoryScreen({
    super.key,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip History'),
      ),
      body: BlocBuilder<TripBloc, TripState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.pastTrips.isEmpty) {
            return const Center(
              child: Text('No trips recorded yet'),
            );
          }

          return ListView.builder(
            itemCount: state.pastTrips.length,
            itemBuilder: (context, index) {
              final trip = state.pastTrips[index];
              return _TripCard(trip: trip);
            },
          );
        },
      ),
    );
  }
}

class _TripCard extends StatelessWidget {
  final Trip trip;

  const _TripCard({required this.trip});

  @override
  Widget build(BuildContext context) {
    final startMonument = sampleMonuments.firstWhere(
      (m) => m.id == trip.startMonumentId,
      orElse: () => const Monument(
        id: 'unknown',
        name: 'Unknown Location',
        position: LatLng(0, 0),
      ),
    );

    final endMonument = trip.endMonumentId != null
        ? sampleMonuments.firstWhere(
            (m) => m.id == trip.endMonumentId,
            orElse: () => const Monument(
              id: 'unknown',
              name: 'Unknown Location',
              position: LatLng(0, 0),
            ),
          )
        : null;

    final dateFormat = DateFormat('MMM dd, yyyy');
    final timeFormat = DateFormat('hh:mm a');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ExpansionTile(
        title: Text(
          '${dateFormat.format(trip.startTime)} Trip',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${_getVehicleTypeText(trip.vehicleType)} • ${_getPurposeText(trip.purpose)}',
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('Start Time', timeFormat.format(trip.startTime)),
                if (trip.endTime != null)
                  _buildInfoRow('End Time', timeFormat.format(trip.endTime!)),
                const SizedBox(height: 8),
                _buildInfoRow('From', startMonument.name),
                if (endMonument != null)
                  _buildInfoRow('To', endMonument.name),
                const SizedBox(height: 8),
                if (trip.vehicleType != null) ...[
                  _buildInfoRow(
                    'Mode',
                    _getVehicleTypeText(trip.vehicleType),
                  ),
                  if (trip.occupancy != null &&
                      (trip.vehicleType == VehicleType.twoWheeler ||
                          trip.vehicleType == VehicleType.fourWheeler))
                    _buildInfoRow(
                      'Occupancy',
                      '${trip.occupancy} passenger${trip.occupancy! > 1 ? 's' : ''}',
                    ),
                ],
                if (trip.purpose != null)
                  _buildInfoRow('Purpose', _getPurposeText(trip.purpose)),
                const SizedBox(height: 8),
                if (trip.checkpoints.isNotEmpty) ...[
                  const Text(
                    'Checkpoints:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  ...trip.checkpoints.map((checkpoint) {
                    final monument = sampleMonuments.firstWhere(
                      (m) => m.id == checkpoint.monumentId,
                      orElse: () => const Monument(
                        id: 'unknown',
                        name: 'Unknown Location',
                        position: LatLng(0, 0),
                      ),
                    );
                    return Padding(
                      padding: const EdgeInsets.only(left: 16, bottom: 4),
                      child: Text(
                        '${timeFormat.format(checkpoint.timestamp)} - ${monument.name}',
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  String _getVehicleTypeText(VehicleType? type) {
    if (type == null) return 'Unknown';
    switch (type) {
      case VehicleType.walk:
        return 'Walk';
      case VehicleType.cycle:
        return 'Cycle';
      case VehicleType.twoWheeler:
        return 'Two Wheeler';
      case VehicleType.threeWheeler:
        return 'Three Wheeler';
      case VehicleType.fourWheeler:
        return 'Four Wheeler';
      case VehicleType.iitmBus:
        return 'IITM Bus';
    }
  }

  String _getPurposeText(TripPurpose? purpose) {
    if (purpose == null) return 'Unknown';
    switch (purpose) {
      case TripPurpose.class_:
        return 'Class';
      case TripPurpose.work:
        return 'Work';
      case TripPurpose.school:
        return 'School';
      case TripPurpose.recreation:
        return 'Recreation';
      case TripPurpose.shopping:
        return 'Shopping';
      case TripPurpose.food:
        return 'Food';
    }
  }
} 