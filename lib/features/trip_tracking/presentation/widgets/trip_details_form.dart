import 'package:flutter/material.dart';
import '../../data/models/trip.dart';

class TripDetailsForm extends StatefulWidget {
  final Function(VehicleType vehicleType, TripPurpose purpose, int? occupancy)
      onSubmit;

  const TripDetailsForm({
    super.key,
    required this.onSubmit,
  });

  @override
  State<TripDetailsForm> createState() => _TripDetailsFormState();
}

class _TripDetailsFormState extends State<TripDetailsForm> {
  VehicleType? _selectedVehicleType;
  TripPurpose? _selectedPurpose;
  int? _occupancy;
  final _formKey = GlobalKey<FormState>();

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
              validator: (value) {
                if (value == null) {
                  return 'Please select a mode of transport';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
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
              validator: (value) {
                if (value == null) {
                  return 'Please select a trip purpose';
                }
                return null;
              },
            ),
            if (_selectedVehicleType == VehicleType.twoWheeler ||
                _selectedVehicleType == VehicleType.fourWheeler) ...[
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: _occupancy,
                decoration: const InputDecoration(
                  labelText: 'Number of Passengers',
                  border: OutlineInputBorder(),
                ),
                items: List.generate(
                  _selectedVehicleType == VehicleType.twoWheeler ? 2 : 4,
                  (index) => DropdownMenuItem(
                    value: index + 1,
                    child: Text('${index + 1}'),
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _occupancy = value;
                  });
                },
                validator: (value) {
                  if (_selectedVehicleType == VehicleType.twoWheeler ||
                      _selectedVehicleType == VehicleType.fourWheeler) {
                    if (value == null) {
                      return 'Please select number of passengers';
                    }
                  }
                  return null;
                },
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    widget.onSubmit(
                      _selectedVehicleType!,
                      _selectedPurpose!,
                      _occupancy,
                    );
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