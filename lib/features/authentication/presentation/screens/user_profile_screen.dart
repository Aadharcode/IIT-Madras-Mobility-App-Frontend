import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  UserCategory? _selectedCategory;
  ResidenceType? _selectedResidence;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Profile'),
        centerTitle: true,
      ),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state.error != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.error!)),
            );
          }
          if (state.userCategory != null &&
              state.residenceType != null &&
              state.isAuthenticated) {
            Navigator.of(context).popUntil((route) => route.isFirst);
          }
          
        },
        builder: (context, state) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Please select your category:',
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
                                        residenceType: _selectedResidence!,
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
        return 'Student';
      case UserCategory.faculty:
        return 'Faculty';
      case UserCategory.nonFaculty:
        return 'Non Faculty';
      case UserCategory.schoolRelative:
        return 'School Relative of IITM Resident';
      case UserCategory.others:
        return 'Others';
    }
  }
}
