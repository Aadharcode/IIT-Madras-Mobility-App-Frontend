import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import 'child_detail_screen.dart';
import 'employment_screen.dart';
import '../../../trip_tracking/presentation/screens/trip_tracking_screen.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  UserCategory? _selectedCategory;
  Gender? _selectedGenderCategory;
  ResidenceType? _selectedResidence;
  int? _ageController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Profile'),
        centerTitle: true,
      ),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
  print("👂 Listener triggered!");

  if (state.error != null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(state.error!)),
    );
    print("❌ Error encountered: ${state.error}");
  }

  print("📊 State values: "
      "userCategory = ${state.userCategory}, "
      "gender = ${state.gender}, "
      "residenceType = ${state.residenceType}, "
      "isAuthenticated = ${state.isAuthenticated}");

  if (state.userCategory != null &&
      state.gender != null &&
      state.residenceType != null &&
      state.isAuthenticated) {
    print("✅ All conditions met! Navigating...");

    if (state.userCategory == UserCategory.employee) {
      print("💼 User is an Employee, navigating to EmploymentScreen");
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => EmploymentScreen(),
        ),
      );
    } else if (state.userCategory == UserCategory.parent) {
      print("👨‍👩‍👧 User is a Parent, navigating to ChildrenDetailsScreen");
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ChildrenDetailsScreen(),
        ),
      );
    } else {
      print("🗺️ User is navigating to TripTrackingScreen");
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => TripTrackingScreen(
            userId: state.userId ?? '',
          ),
        ),
      );
    }
  } else {
    print("⚠️ Navigation block not triggered: Missing required fields.");
  }
},

        builder: (context, state) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Please select your user Group:',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ...UserCategory.values.map(
                  (category) => RadioListTile<UserCategory>(
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
                const SizedBox(height: 32),
                const Text(
                  'Please enter your age:',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Enter your age',
                  ),
                  onChanged: (value) {
                    setState(() {
                      _ageController = int.tryParse(value);
                    });
                  },
                ),
                const SizedBox(height: 16),
                const Text(
                  'Please select your Gender:',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ...Gender.values.map(
                  (category) => RadioListTile<Gender>(
                    title: Text(_getGenderTitle(category)),
                    value: category,
                    groupValue: _selectedGenderCategory,
                    onChanged: (value) {
                      setState(() {
                        _selectedGenderCategory = value;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Please select your residence type:',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ...ResidenceType.values.map(
                  (type) => RadioListTile<ResidenceType>(
                    title: Text(
                      type == ResidenceType.onCampus
                          ? 'On Campus'
                          : 'Off Campus',
                    ),
                    value: type,
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
                                        userCategory: _selectedCategory!,
                                        gender: _selectedGenderCategory!,
                                        residenceType: _selectedResidence!,
                                        age: _ageController!,
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

  String _getCategoryTitle(UserCategory category) {
    switch (category) {
      case UserCategory.student:
        return 'IITM Student';
      case UserCategory.employee:
        return 'Employee';
      case UserCategory.parent:
        return 'Campus School Parent';
      case UserCategory.relative:
        return 'Relative';
    }
  }
  String _getGenderTitle(Gender category) {
    switch (category) {
      case Gender.male:
        return 'Male';
      case Gender.female:
        return 'Female';
      case Gender.nonBinary:
        return 'Non-Binary';
      case Gender.noReveal:
        return 'Choose not to reveal';
    }
  }
}
