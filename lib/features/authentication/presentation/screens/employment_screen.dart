import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../../../trip_tracking/presentation/screens/trip_tracking_screen.dart';
import '../../../authentication/presentation/screens/user_profile_screen.dart';

class EmploymentScreen extends StatefulWidget{
  const EmploymentScreen({super.key});

  @override
  State<EmploymentScreen> createState() => _EmploymentScreenState();
}

class _EmploymentScreenState extends State<EmploymentScreen> {
  EmploymentCategory? _selectedCategory;
  EmploymentType? _selectedResidence;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Profile'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => const UserProfileScreen(),
              ),
            );
          },
        ),
      ),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) async {
          print('📬 ${state.employmentCategory}, ${state.employmentType}, ${state.error}');
          
          if (state.error != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.error!)),
            );
          }

          if (state.employmentCategory != null &&
              state.employmentType != null &&
              state.employmentType != null &&
              state.isAuthenticated) {
            
            // Store values in SharedPreferences before navigating
            await _storeEmploymentDetails(state.employmentCategory!, state.employmentType!);

            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => TripTrackingScreen(
                  userId: state.userId ?? '',
                ),
              ),
            );
          }
        },  
        builder: (context, state) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Please select your employment type:',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ...EmploymentCategory.values.map(
                  (category) => RadioListTile<EmploymentCategory>(
                    title: Text(_getCategoryTitle(category)),
                    value: category,
                    groupValue: _selectedCategory,
                    onChanged: (value) {
                      setState(() {
                        _selectedCategory = value;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Please select your Employment type:',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ...EmploymentType.values.map(
                  (category) => RadioListTile<EmploymentType>(
                    title: Text(_getEmploymentTypeTitle(category)),
                    value: category,
                    groupValue: _selectedResidence,
                    onChanged: (value) {
                      setState(() {
                        _selectedResidence = value;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 32),
                if (state.isLoading)
                  const Center(child: CircularProgressIndicator())
                else
                  ElevatedButton(
                    onPressed:
                        _selectedCategory != null && _selectedResidence != null
                            ? () {
                                context.read<AuthBloc>().add(
                                      UpdateUserProfile(
                                        employmentCategory: _selectedCategory!,
                                        employmentType: _selectedResidence!,
                                        context: context,
                                      ),
                                    );
                              }
                            : null,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: const Text('Continue'),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Store employment details in SharedPreferences
  Future<void> _storeEmploymentDetails(EmploymentCategory category, EmploymentType type) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('employment_category', category.toString());
    await prefs.setString('employment_type', type.toString());
  }

  String _getCategoryTitle(EmploymentCategory category) {
    switch (category) {
      case EmploymentCategory.admin:
        return 'Admin/Non-tech Staff';
      case EmploymentCategory.research:
        return 'Research Staff';
      case EmploymentCategory.school:
        return 'School';
      case EmploymentCategory.technical:
        return 'Technical Staff';
      case EmploymentCategory.other:
        return 'Other';
    }
  }

  String _getEmploymentTypeTitle(EmploymentType category) {
    switch (category) {
      case EmploymentType.contract:
        return 'Contract';
      case EmploymentType.intern:
        return 'Intern';
      case EmploymentType.permanent:
        return 'Permanent';
    }
  }
}
