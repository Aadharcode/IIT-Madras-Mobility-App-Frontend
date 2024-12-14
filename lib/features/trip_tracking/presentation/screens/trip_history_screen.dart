import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import '../../data/models/trip.dart';
import '../../data/models/monument.dart';
import '../bloc/trip_bloc.dart';
// import '../bloc/trip_event.dart';
import '../bloc/trip_state.dart';

class TripHistoryScreen extends StatelessWidget {
  final String userId;

  const TripHistoryScreen({
    super.key,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        title: const Text('Trip History'),
        centerTitle: true,
      ),
      body: BlocBuilder<TripBloc, TripState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.pastTrips.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history_rounded,
                    size: 64,
                    color: theme.colorScheme.primary.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No trips recorded yet',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: theme.colorScheme.onBackground.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start tracking your first trip!',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onBackground.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
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
    final theme = Theme.of(context);
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
      margin: const EdgeInsets.only(bottom: 16),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _getVehicleIcon(trip.vehicleType),
              color: theme.colorScheme.primary,
            ),
          ),
          title: Text(
            dateFormat.format(trip.startTime),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Text(
            '${_getVehicleTypeText(trip.vehicleType)} • ${_getPurposeText(trip.purpose)}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onBackground.withOpacity(0.7),
            ),
          ),
          children: [
            const Divider(),
            const SizedBox(height: 8),
            _buildInfoRow(
              context,
              icon: Icons.schedule,
              label: 'Start Time',
              value: timeFormat.format(trip.startTime),
            ),
            if (trip.endTime != null)
              _buildInfoRow(
                context,
                icon: Icons.schedule,
                label: 'End Time',
                value: timeFormat.format(trip.endTime!),
              ),
            const SizedBox(height: 8),
            _buildInfoRow(
              context,
              icon: Icons.location_on,
              label: 'From',
              value: startMonument.name,
            ),
            if (endMonument != null)
              _buildInfoRow(
                context,
                icon: Icons.location_on,
                label: 'To',
                value: endMonument.name,
              ),
            const SizedBox(height: 8),
            if (trip.vehicleType != null) ...[
              _buildInfoRow(
                context,
                icon: _getVehicleIcon(trip.vehicleType),
                label: 'Mode',
                value: _getVehicleTypeText(trip.vehicleType),
              ),
              if (trip.occupancy != null &&
                  (trip.vehicleType == VehicleType.twoWheeler ||
                      trip.vehicleType == VehicleType.fourWheeler))
                _buildInfoRow(
                  context,
                  icon: Icons.people,
                  label: 'Occupancy',
                  value: '${trip.occupancy} passenger${trip.occupancy! > 1 ? 's' : ''}',
                ),
            ],
            if (trip.purpose != null)
              _buildInfoRow(
                context,
                icon: Icons.category,
                label: 'Purpose',
                value: _getPurposeText(trip.purpose),
              ),
            if (trip.checkpoints.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Checkpoints',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
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
                  padding: const EdgeInsets.only(left: 32, bottom: 4),
                  child: Row(
                    children: [
                      Icon(
                        Icons.circle,
                        size: 8,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${timeFormat.format(checkpoint.timestamp)} - ${monument.name}',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onBackground.withOpacity(0.7),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getVehicleIcon(VehicleType? type) {
    switch (type) {
      case VehicleType.walk:
        return Icons.directions_walk;
      case VehicleType.cycle:
        return Icons.directions_bike;
      case VehicleType.twoWheeler:
        return Icons.motorcycle;
      case VehicleType.threeWheeler:
        return Icons.electric_rickshaw;
      case VehicleType.fourWheeler:
        return Icons.directions_car;
      case VehicleType.iitmBus:
        return Icons.directions_bus;
      default:
        return Icons.help_outline;
    }
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
