import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import '../../data/models/trip.dart';
import '../../data/models/monument.dart';
import '../bloc/trip_bloc.dart';
import '../bloc/trip_event.dart';
import '../bloc/trip_state.dart';
import '../../data/services/monument_services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/services.dart';
import '../widgets/trip_details_form.dart';
import '../../../authentication/data/services/auth_service.dart';

class TripHistoryScreen extends StatefulWidget {
  final String userId;

  const TripHistoryScreen({
    super.key,
    required this.userId,
  });

  @override
  State<TripHistoryScreen> createState() => _TripHistoryScreenState();
}

class _TripHistoryScreenState extends State<TripHistoryScreen> {
  late Map<String, Monument> monumentMap;

  @override
  void initState() {
    super.initState();
    //debugPrint('Loading past trips for user: ${widget.userId}');
    BlocProvider.of<TripBloc>(context).add(LoadPastTrips(widget.userId));
    monumentMap = {};
    _loadMonuments();
  }

  Future<void> _loadMonuments() async {
    try {
      //debugPrint('Fetching monuments...');
      final monuments = await MonumentService.fetchMonuments();
      setState(() {
        monumentMap = {
          for (var monument in monuments) monument.id: monument,
        };
      });
      //debugPrint('Loaded monuments: ${monumentMap.keys}');
    } catch (e) {
      //debugPrint('Error fetching monuments: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    //debugPrint('Building TripHistoryScreen UI');

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Trip History'),
        centerTitle: true,
      ),
      body: BlocBuilder<TripBloc, TripState>(
        builder: (context, state) {
          if (state.isLoading) {
            //debugPrint('Loading trips...');
            return const Center(child: CircularProgressIndicator());
          }

          if (state.pastTrips.isEmpty) {
            //debugPrint('No trips found');
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
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start tracking your first trip!',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            );
          }

          //debugPrint('Displaying past trips, count: ${state.pastTrips.length}');
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: state.pastTrips.length,
            itemBuilder: (context, index) {
              final trip = state.pastTrips[index];
              //debugPrint('Displaying trip ${trip.id} at index $index');
              return _TripCard(
                trip: trip,
                monumentMap: monumentMap,
              );
            },
          );
        },
      ),
    );
  }
}

class _TripCard extends StatelessWidget {
  final Trip trip;
  final Map<String, Monument> monumentMap;

  const _TripCard({
    required this.trip,
    required this.monumentMap,
  });

  bool get _needsDetails => trip.vehicleType == null || trip.purpose == null;

  void _showTripDetailsForm(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set Trip Details'),
        content: TripDetailsForm(
          onSubmit: (vehicleType, purpose, occupancy, selectedMonuments,
              endMonument) async {
            try {
              final token = await AuthService().getToken();
              if (token == null) {
                throw Exception('Authentication token not found');
              }

              final response = await http.patch(
                Uri.parse('${TripBloc.baseUrl}/trip/update/${trip.id}'),
                headers: {
                  'Content-Type': 'application/json',
                  'Authorization': 'Bearer $token',
                },
                body: jsonEncode({
                  'mode': vehicleType?.toString().split('.').last,
                  'purpose': purpose?.toString().split('.').last,
                  'occupancy': occupancy,
                }),
              );

              if (response.statusCode == 200) {
                if (!context.mounted) return;
                Navigator.pop(context);
                // Refresh trip history
                context.read<TripBloc>().add(LoadPastTrips(trip.userId));
              } else {
                throw Exception('Failed to update trip details');
              }
            } catch (e) {
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error updating trip details: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM dd, yyyy');
    final timeFormat = DateFormat('hh:mm a');

    final startMonument = monumentMap[trip.startMonumentId] ??
        Monument(
          id: 'unknown',
          name: 'Unknown Location',
          position: LatLng(0, 0),
        );
    //debugPrint('Start monument: ${startMonument.name}');

    final endMonument = trip.endMonumentId != null
        ? monumentMap[trip.endMonumentId!] ??
            Monument(
              id: 'unknown',
              name: 'No End Trip Recorded',
              position: LatLng(0, 0),
            )
        : Monument(
            id: 'none',
            name: 'No End Trip Recorded',
            position: LatLng(0, 0),
          );
    //debugPrint('End monument: ${endMonument.name}');

    final monumentVisitsFormatted = trip.monumentVisits.map((visit) {
      final monumentName =
          monumentMap[visit.monumentId]?.name ?? 'Unknown Monument';
      final timeFormat = DateFormat('hh:mm a');
      return '$monumentName (${timeFormat.format(visit.timestamp)})';
    }).toList();

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: _needsDetails
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: theme.colorScheme.error,
                width: 2,
              ),
            )
          : null,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          leading: Stack(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _needsDetails
                      ? theme.colorScheme.error.withOpacity(0.1)
                      : theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getVehicleIcon(trip.vehicleType),
                  color: _needsDetails
                      ? theme.colorScheme.error
                      : theme.colorScheme.primary,
                ),
              ),
              if (_needsDetails)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.error,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.warning_rounded,
                      size: 14,
                      color: theme.colorScheme.onError,
                    ),
                  ),
                ),
            ],
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  dateFormat.format(trip.startTime),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (_needsDetails)
                Text(
                  'Details needed',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
          subtitle: Text(
            '${_getVehicleTypeText(trip.vehicleType)}${_getOccupancyText(trip.vehicleType, trip.occupancy)} • ${_getPurposeText(trip.purpose)}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: _needsDetails
                  ? theme.colorScheme.error.withOpacity(0.8)
                  : theme.colorScheme.onSurface.withOpacity(0.7),
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
            _buildInfoRow(
              context,
              icon: Icons.location_on,
              label: 'To',
              value: endMonument.name,
            ),
            const SizedBox(height: 8),
            if (monumentVisitsFormatted.isNotEmpty)
              _buildInfoRow(
                context,
                icon: Icons.flag,
                label: 'Monuments',
                value: monumentVisitsFormatted.join('\n'),
              ),
            if (trip.vehicleType == null || trip.purpose == null) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _showTripDetailsForm(context),
                child: const Text('Set Trip Details'),
              ),
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
    //debugPrint('Building info row for $label: $value');

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
                color: theme.colorScheme.onSurface.withOpacity(0.7),
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
    //debugPrint('Getting vehicle icon for type: $type');
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
    if (type == null) return 'Not Set';
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
    if (purpose == null) return 'Not Set';
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

  String _getOccupancyText(VehicleType? type, int? occupancy) {
    if (type == null || occupancy == null) return '';
    switch (type) {
      case VehicleType.twoWheeler:
        return ' (${occupancy} people)';
      case VehicleType.fourWheeler:
        return ' (${occupancy} people)';
      default:
        return '';
    }
  }
}
