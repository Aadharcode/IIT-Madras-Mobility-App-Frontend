import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../authentication/presentation/bloc/auth_bloc.dart';
import '../../../authentication/presentation/bloc/auth_event.dart';
import '../../../authentication/presentation/bloc/auth_state.dart';
import '../../../../main.dart';
import '../../../authentication/data/services/auth_service.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late AuthService authService;
  Map<String, dynamic>? userProfile;
  bool isLoading = true;
  bool isDownloading = false;
  String errorMessage = '';
  bool canDownloadData = false;

  @override
  void initState() {
    super.initState();
    authService = AuthService();
    _loadUserProfile();
    _checkDataAccess();
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Future<void> _loadUserProfile() async {
    try {
      final token = await authService.getToken();
      if (token == null) {
        print("No token found, fetching data from AuthState");
        final authState = context.read<AuthBloc>().state;
        if (authState.isAuthenticated) {
          setState(() {
            userProfile = {
              'number': authState.phoneNumber ?? '',
              'category': authState.userCategory ?? '',
              'residentType': authState.residenceType ?? '',
              'age': authState.age != null ? authState.age.toString() : '',
              'gender': authState.gender ?? '',
              'employmentCategory': authState.employmentCategory ?? '',
              'employmentType': authState.employmentType ?? '',
            };
            isLoading = false;
          });
        } else {
          setState(() {
            isLoading = false;
            errorMessage = 'User not authenticated';
          });
          _showSnackBar('User not authenticated', isError: true);
        }
        return;
      }

      final profile = await authService.getUserProfile();

      // Create a new map with sanitized values
      final sanitizedProfile = <String, dynamic>{};
      if (profile != null) {
        profile.forEach((key, value) {
          if (value != null) {
            if (key == 'childrenDetails' && value is List) {
              // Keep childrenDetails as a List
              sanitizedProfile[key] = value;
            } else if (value is int) {
              sanitizedProfile[key] = value.toString();
            } else if (value is String) {
              sanitizedProfile[key] = value;
            } else {
              sanitizedProfile[key] = value.toString();
            }
          } else {
            sanitizedProfile[key] = '';
          }
        });
      }

      setState(() {
        userProfile = sanitizedProfile;
        isLoading = false;
      });
    } catch (e) {
      print('Error loading profile: $e');
      setState(() {
        isLoading = false;
        errorMessage = e.toString();
      });
      _showSnackBar('Failed to load profile: ${e.toString()}', isError: true);
    }
  }

  Future<void> _checkDataAccess() async {
    try {
      final token = await authService.getToken();
      if (token == null) {
        _showSnackBar('Authentication token not found', isError: true);
        return;
      }

      final response = await http.head(
        Uri.parse(
            'http://ec2-13-232-246-85.ap-south-1.compute.amazonaws.com/api/trip/getData'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      setState(() {
        canDownloadData = response.statusCode == 200;
      });
    } catch (e) {
      print('Error checking data access: $e');
      _showSnackBar('Failed to check data access', isError: true);
    }
  }

  Future<void> _downloadTripData() async {
    if (isDownloading) return;

    setState(() {
      isDownloading = true;
    });

    try {
      final token = await authService.getToken();
      if (token == null) {
        _showSnackBar('Authentication token not found', isError: true);
        return;
      }

      final response = await http.get(
        Uri.parse(
            'http://ec2-13-232-246-85.ap-south-1.compute.amazonaws.com/api/trip/getData'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final directory = await getApplicationDocumentsDirectory();
        final now = DateFormat('yyyy-MM-dd_HH-mm-ss').format(DateTime.now());
        final file = File('${directory.path}/trip_data_$now.csv');
        await file.writeAsBytes(response.bodyBytes);

        await Share.shareXFiles(
          [XFile(file.path)],
          text: 'Your trip data',
        );

        _showSnackBar('Trip data downloaded successfully');
      } else {
        throw Exception('Failed to download data: ${response.statusCode}');
      }
    } catch (e) {
      print('Error downloading trip data: $e');
      _showSnackBar('Failed to download trip data: ${e.toString()}',
          isError: true);
    } finally {
      setState(() {
        isDownloading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Profile'),
        centerTitle: true,
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 48,
                        color: theme.colorScheme.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error: $errorMessage',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadUserProfile,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 24),
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: theme.colorScheme.primary.withOpacity(0.2),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 60,
                          backgroundColor:
                              theme.colorScheme.primary.withOpacity(0.1),
                          child: Icon(
                            Icons.person,
                            size: 60,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildProfileItem(
                                icon: Icons.person_outline,
                                label: 'Name',
                                value: userProfile?['name'] ?? 'Not Available',
                                theme: theme,
                              ),
                              const Divider(height: 24),
                              _buildProfileItem(
                                icon: Icons.phone_outlined,
                                label: 'Phone',
                                value: userProfile?['number']?.toString() ??
                                    'Not Available',
                                theme: theme,
                              ),
                              const Divider(height: 24),
                              _buildProfileItem(
                                icon: Icons.category_outlined,
                                label: 'Category',
                                value:
                                    _formatCategory(userProfile?['category']),
                                theme: theme,
                              ),
                              const Divider(height: 24),
                              _buildProfileItem(
                                icon: Icons.home_outlined,
                                label: 'Residence Type',
                                value: _formatResidenceType(
                                    userProfile?['residentType']),
                                theme: theme,
                              ),
                              const Divider(height: 24),
                              _buildProfileItem(
                                icon: Icons.person_outline,
                                label: 'Gender',
                                value: _formatGender(userProfile?['gender']),
                                theme: theme,
                              ),
                              const Divider(height: 24),
                              _buildProfileItem(
                                icon: Icons.calendar_today_outlined,
                                label: 'Age',
                                value: userProfile?['age']?.toString() ??
                                    'Not Available',
                                theme: theme,
                              ),
                              if (userProfile?['category'] == 'employee') ...[
                                const Divider(height: 24),
                                _buildProfileItem(
                                  icon: Icons.work_outline,
                                  label: 'Employment Type',
                                  value: _formatEmploymentType(
                                      userProfile?['employmentType']),
                                  theme: theme,
                                ),
                                const Divider(height: 24),
                                _buildProfileItem(
                                  icon: Icons.business_center_outlined,
                                  label: 'Employment Category',
                                  value: _formatEmploymentCategory(
                                      userProfile?['employmentCategory']),
                                  theme: theme,
                                ),
                              ],
                              if (userProfile?['category'] == 'parent' &&
                                  userProfile?['childrenDetails'] != null) ...[
                                const Divider(height: 24),
                                _buildProfileItem(
                                  icon: Icons.school_outlined,
                                  label: 'Children Grades',
                                  value: _formatChildrenDetails(
                                      userProfile?['childrenDetails']),
                                  theme: theme,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      if (canDownloadData)
                        ElevatedButton.icon(
                          onPressed: isDownloading ? null : _downloadTripData,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: isDownloading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                )
                              : const Icon(Icons.download, color: Colors.white),
                          label: Text(
                            isDownloading
                                ? 'Downloading...'
                                : 'Download Trip Data (CSV)',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () {
                          context.read<AuthBloc>().add(const LogoutEvent());
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const MyApp(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.error,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.logout, color: Colors.white),
                        label: const Text(
                          'Log Out',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildProfileItem({
    required IconData icon,
    required String label,
    required String value,
    required ThemeData theme,
  }) {
    // Handle all possible null or empty cases
    String displayValue = 'Not Available';
    if (value.isNotEmpty &&
        value != 'null' &&
        value != 'Null' &&
        value != 'NULL') {
      displayValue = value;
    }

    return Row(
      children: [
        Icon(icon, color: theme.colorScheme.primary, size: 24),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                displayValue,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatCategory(String? category) {
    if (category == null) return 'Not Available';
    switch (category.toLowerCase()) {
      case 'student':
        return 'IITM Student';
      case 'employee':
        return 'Employee';
      case 'parent':
        return 'Campus School Parent';
      case 'relative':
        return 'Relative';
      default:
        return category;
    }
  }

  String _formatResidenceType(String? type) {
    if (type == null) return 'Not Available';
    switch (type.toLowerCase()) {
      case 'oncampus':
        return 'On Campus';
      case 'offcampus':
        return 'Off Campus';
      default:
        return type;
    }
  }

  String _formatGender(String? gender) {
    if (gender == null) return 'Not Available';
    switch (gender.toLowerCase()) {
      case 'male':
        return 'Male';
      case 'female':
        return 'Female';
      case 'nonbinary':
        return 'Non-Binary';
      case 'noreveal':
        return 'Prefer Not to Say';
      default:
        return gender;
    }
  }

  String _formatEmploymentType(String? type) {
    if (type == null) return 'Not Available';
    switch (type.toLowerCase()) {
      case 'permanent':
        return 'Permanent';
      case 'contract':
        return 'Contract';
      case 'intern':
        return 'Intern';
      default:
        return type;
    }
  }

  String _formatEmploymentCategory(String? category) {
    if (category == null) return 'Not Available';
    switch (category.toLowerCase()) {
      case 'technical':
        return 'Technical';
      case 'research':
        return 'Research';
      case 'admin':
        return 'Administrative';
      case 'school':
        return 'School';
      case 'other':
        return 'Other';
      default:
        return category;
    }
  }

  String _formatChildrenDetails(List<dynamic>? grades) {
    if (grades == null || grades.isEmpty) return 'Not Available';

    // Sort grades in ascending order
    final sortedGrades = List<int>.from(grades)..sort();

    // Convert grades to a readable format
    return sortedGrades.map((grade) {
      if (grade == 0) return 'LKG';
      if (grade == -1) return 'UKG';
      return 'Grade $grade';
    }).join(', ');
  }
}
