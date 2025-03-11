import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../../../trip_tracking/presentation/screens/trip_tracking_screen.dart';

class ChildrenDetailsScreen extends StatefulWidget {
  const ChildrenDetailsScreen({super.key});

  @override
  State<ChildrenDetailsScreen> createState() => _ChildrenDetailsScreenState();
}

class _ChildrenDetailsScreenState extends State<ChildrenDetailsScreen> {
  int _numChildren = 0;
  final List<TextEditingController> _gradeControllers = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Children Details'),
      ),
      body: GestureDetector(
        // Close keyboard when tapping outside of a text field
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: BlocConsumer<AuthBloc, AuthState>(
            listener: (context, state) async {
              // Handle navigation when childrenDetails is successfully updated
              if (state.childrenDetails != null) {
                await _storeChildrenDetails(state.childrenDetails!);
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => TripTrackingScreen(userId: state.userId ?? ''),
                  ),
                );
              }

              // Show error messages if any
              if (state.error != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(state.error!)),
                );
              }
            },
            builder: (context, state) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Enter the number of children:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Number of children',
                    ),
                    onChanged: (value) {
                      int count = int.tryParse(value) ?? 0;
                      setState(() {
                        _numChildren = count;
                        _gradeControllers.clear();
                        for (int i = 0; i < count; i++) {
                          _gradeControllers.add(TextEditingController());
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  if (_numChildren > 0) ...[
                    const Text(
                      'Enter Grades of Children:',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    for (int i = 0; i < _numChildren; i++)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: TextField(
                          controller: _gradeControllers[i],
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: 'Grade of Child ${i + 1}',
                          ),
                        ),
                      ),
                  ],
                  const SizedBox(height: 32),
                  if (state.isLoading)
                    const Center(child: CircularProgressIndicator())
                  else
                    ElevatedButton(
                      onPressed: _numChildren > 0 &&
                              _gradeControllers.every((controller) => controller.text.isNotEmpty)
                          ? () {
                              List<int> grades = _gradeControllers
                                  .map((controller) => int.tryParse(controller.text) ?? 0)
                                  .toList();

                              context.read<AuthBloc>().add(
                                    UpdateUserProfile(
                                      childrenDetails: grades, // Pass children details
                                      context: context, // Provide context
                                    ),
                                  );
                            }
                          : null,
                      style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                      child: const Text('Continue'),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // Store children details in SharedPreferences
  Future<void> _storeChildrenDetails(List<int> childrenGrades) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('num_children', childrenGrades.length);
    await prefs.setStringList(
        'children_grades', childrenGrades.map((e) => e.toString()).toList());
  }
}
