import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../data/models/monument.dart';
import '../bloc/trip_bloc.dart';
import '../bloc/trip_event.dart';
import '../bloc/trip_state.dart';
import '../widgets/trip_details_form.dart';
import 'trip_history_screen.dart';

class TripTrackingScreen extends StatefulWidget {
  final String userId;

  const TripTrackingScreen({
    super.key,
    required this.userId,
  });

  @override
  State<TripTrackingScreen> createState() => _TripTrackingScreenState();
}

class _TripTrackingScreenState extends State<TripTrackingScreen> {
  GoogleMapController? _mapController;
  final Set<Circle> _monumentZones = {};
  final Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _initializeMonuments();
  }

  void _initializeMonuments() {
    for (final monument in sampleMonuments) {
      _monumentZones.add(
        Circle(
          circleId: CircleId(monument.id),
          center: monument.position,
          radius: monument.radius,
          fillColor: Colors.blue.withOpacity(0.3),
          strokeColor: Colors.blue,
          strokeWidth: 1,
        ),
      );
      _markers.add(
        Marker(
          markerId: MarkerId(monument.id),
          position: monument.position,
          infoWindow: InfoWindow(title: monument.name),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TripBloc, TripState>(
      listener: (context, state) {
        if (state.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.error!)),
          );
        }

        if (state.currentLocation != null && _mapController != null) {
          _mapController!.animateCamera(
            CameraUpdate.newLatLng(state.currentLocation!),
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Trip Tracking'),
            actions: [
              IconButton(
                icon: const Icon(Icons.history),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => TripHistoryScreen(userId: widget.userId),
                    ),
                  );
                },
              ),
              if (state.currentTrip != null)
                IconButton(
                  icon: const Icon(Icons.stop),
                  onPressed: () => _showTripEndDialog(context),
                ),
            ],
          ),
          body: Stack(
            children: [
              GoogleMap(
                initialCameraPosition: const CameraPosition(
                  target: LatLng(12.991214, 80.233276), // IIT Madras
                  zoom: 15,
                ),
                myLocationEnabled: true,
                myLocationButtonEnabled: true,
                zoomControlsEnabled: true,
                mapToolbarEnabled: true,
                compassEnabled: true,
                circles: _monumentZones,
                markers: _markers,
                mapType: MapType.normal,
                onMapCreated: (controller) {
                  _mapController = controller;
                  controller.setMapStyle('''
                    [
                      {
                        "featureType": "poi",
                        "elementType": "labels",
                        "stylers": [
                          {
                            "visibility": "off"
                          }
                        ]
                      }
                    ]
                  ''');
                },
              ),
              if (state.isLoading)
                const Center(child: CircularProgressIndicator()),
              if (!state.isTracking && state.currentTrip == null)
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 16,
                  child: ElevatedButton(
                    onPressed: () => _showTripStartDialog(context),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                    ),
                    child: const Text('Start Trip'),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _showTripStartDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Start Trip'),
        content: const Text('Are you ready to start tracking your trip?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<TripBloc>().add(
                    StartTrip(
                      userId: widget.userId,
                      startMonument:
                          sampleMonuments.first, // TODO: Detect nearest
                    ),
                  );
              Navigator.of(dialogContext).pop();
            },
            child: const Text('Start'),
          ),
        ],
      ),
    );
  }

  void _showTripEndDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => WillPopScope(
        onWillPop: () async => false,
        child: BlocProvider.value(
          value: context.read<TripBloc>(),
          child: BlocConsumer<TripBloc, TripState>(
            listener: (context, state) {
              if (state.currentTrip == null && !state.isLoading) {
                Navigator.of(dialogContext).pop();
              }
            },
            builder: (context, state) {
              return AlertDialog(
                title: const Text('End Trip'),
                content: state.isLoading
                    ? const SizedBox(
                        height: 100,
                        child: Center(child: CircularProgressIndicator()),
                      )
                    : TripDetailsForm(
                        onSubmit: (vehicleType, purpose, occupancy) {
                          final bloc = context.read<TripBloc>();

                          // Update trip details and end trip
                          bloc
                            ..add(UpdateTripDetails(
                              vehicleType: vehicleType,
                              purpose: purpose,
                              occupancy: occupancy,
                            ))
                            ..add(EndTrip(
                              endMonument:
                                  sampleMonuments.last, // TODO: Detect nearest
                            ));
                        },
                      ),
                actions: [
                  if (!state.isLoading)
                    TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      child: const Text('Cancel'),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
