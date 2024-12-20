import 'package:flutter/material.dart';
import '../../data/models/trip.dart';
import '../../data/services/monument_services.dart';
import '../../data/models/monument.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class TripDetailsForm extends StatefulWidget {
  final Function(VehicleType vehicleType, TripPurpose purpose, int? occupancy,
      List<Monument> selectedMonuments, Monument endMonument) onSubmit;

  const TripDetailsForm({
    super.key,
    required this.onSubmit,
  });

  @override
  State<TripDetailsForm> createState() => _TripDetailsFormState();
}

class _TripDetailsFormState extends State<TripDetailsForm> {
  final MonumentService monumentService = MonumentService();
  VehicleType? _selectedVehicleType;
  TripPurpose? _selectedPurpose;
  int? _occupancy;
  List<Monument> _availableMonuments = [];
  List<Monument> _selectedMonuments = [];
  Monument? _selectedEndMonument;
  String? _monumentError;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _loadMonuments();
  }

  Future<void> _loadMonuments() async {
    try {
      final monuments =
          await MonumentService.fetchMonuments(); // Fetching monuments
      setState(() {
        _availableMonuments = monuments;
      });
    } catch (e) {
      setState(() {
        _monumentError = 'Error fetching monuments: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Please provide trip details:',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            // Mode of Transport Dropdown
            DropdownButtonFormField<VehicleType>(
              value: _selectedVehicleType,
              decoration: const InputDecoration(
                labelText: 'Mode of Transport',
                border: OutlineInputBorder(),
              ),
              items: VehicleType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(_getVehicleTypeText(type)),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedVehicleType = value;
                  if (value != VehicleType.twoWheeler &&
                      value != VehicleType.fourWheeler) {
                    _occupancy = null;
                  }
                });
              },
              validator: (value) =>
                  value == null ? 'Please select a mode of transport' : null,
            ),
            const SizedBox(height: 16),
            // Trip Purpose Dropdown
            DropdownButtonFormField<TripPurpose>(
              value: _selectedPurpose,
              decoration: const InputDecoration(
                labelText: 'Trip Purpose',
                border: OutlineInputBorder(),
              ),
              items: TripPurpose.values.map((purpose) {
                return DropdownMenuItem(
                  value: purpose,
                  child: Text(_getPurposeText(purpose)),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedPurpose = value;
                });
              },
              validator: (value) =>
                  value == null ? 'Please select a trip purpose' : null,
            ),
            const SizedBox(height: 16),
            // Monuments Passed Dropdown
            _availableMonuments.isEmpty
                ? _monumentError != null
                    ? Text('Error: $_monumentError')
                    : const CircularProgressIndicator()
                : DropdownButtonFormField<Monument>(
                    decoration: const InputDecoration(
                      labelText: 'Monuments Passed',
                      border: OutlineInputBorder(),
                    ),
                    items: _availableMonuments.map((monument) {
                      return DropdownMenuItem<Monument>(
                        value: monument,
                        child: Text(monument.name),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        if (value != null &&
                            !_selectedMonuments.contains(value)) {
                          _selectedMonuments.add(value);
                        }
                      });
                    },
                  ),
            const SizedBox(height: 16),
            // Display Selected Monuments
            Wrap(
              children: _selectedMonuments.map((monument) {
                return Chip(
                  label: Text(monument.name),
                  onDeleted: () {
                    setState(() {
                      _selectedMonuments.remove(monument);
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    // Get current location
                    try {
                      final position = await Geolocator.getCurrentPosition(
                        desiredAccuracy: LocationAccuracy.high,
                      );
                      final currentLocation = LatLng(
                        position.latitude,
                        position.longitude,
                      );

                      // Find nearest monument
                      final nearestMonument =
                          await MonumentService.findNearestMonument(
                              currentLocation);

                      if (nearestMonument == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                'You must be near a monument to end the trip'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      widget.onSubmit(
                        _selectedVehicleType!,
                        _selectedPurpose!,
                        _occupancy,
                        _selectedMonuments,
                        nearestMonument,
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error: ${e.toString()}'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                child: const Text('Submit'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getVehicleTypeText(VehicleType type) {
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

  String _getPurposeText(TripPurpose purpose) {
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
