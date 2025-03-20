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
              'name': authState.name ?? "",
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
        _showSnackBar('Only admin is allowed to see the csv file');
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
        if (label != 'Phone') // Phone number cannot be edited
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _showEditDialog(label, value),
            color: theme.colorScheme.primary,
          ),
      ],
    );
  }

  Future<void> _showEditDialog(String label, String currentValue) async {
    String? newValue = currentValue;
    int? newAge;
    List<int>? newGrades;

    switch (label) {
      case 'Name':
        newValue = await _showTextFieldDialog(label, currentValue);
        if (newValue != null) {
          _updateProfile({'name': newValue});
        }
        break;
      case 'Age':
        newAge = await _showNumberFieldDialog(label, currentValue);
        if (newAge != null) {
          _updateProfile({'age': newAge});
        }
        break;
      case 'Gender':
        newValue = await _showGenderSelectionDialog();
        if (newValue != null) {
          _updateProfile({'gender': newValue.toLowerCase()});
        }
        break;
      case 'Category':
        newValue = await _showCategorySelectionDialog();
        if (newValue != null) {
          _updateProfile({'category': newValue.toLowerCase()});
        }
        break;
      case 'Residence Type':
        newValue = await _showResidenceTypeSelectionDialog();
        if (newValue != null) {
          _updateProfile({'residentType': newValue.toLowerCase()});
        }
        break;
      case 'Employment Type':
        if (userProfile?['category'] == 'employee') {
          newValue = await _showEmploymentTypeSelectionDialog();
          if (newValue != null) {
            _updateProfile({'employmentType': newValue.toLowerCase()});
          }
        }
        break;
      case 'Employment Category':
        if (userProfile?['category'] == 'employee') {
          newValue = await _showEmploymentCategorySelectionDialog();
          if (newValue != null) {
            _updateProfile({'employmentCategory': newValue.toLowerCase()});
          }
        }
        break;
      case 'Children Grades':
        if (userProfile?['category'] == 'parent') {
          newGrades = await _showChildrenGradesDialog(
              userProfile?['childrenDetails'] ?? []);
          if (newGrades != null) {
            _updateProfile({'childrenDetails': newGrades});
          }
        }
        break;
    }
  }

  Future<void> _updateProfile(Map<String, dynamic> updates) async {
    try {
      setState(() {
        isLoading = true;
      });

      final updatedProfile = await authService.updateUserProfile(updates);

      setState(() {
        userProfile = Map<String, dynamic>.from(userProfile ?? {})
          ..addAll(updatedProfile);
        isLoading = false;
      });

      _showSnackBar('Profile updated successfully');
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      _showSnackBar('Failed to update profile: ${e.toString()}', isError: true);
    }
  }

  Future<String?> _showTextFieldDialog(
      String label, String currentValue) async {
    String? value = currentValue;
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit $label'),
        content: TextField(
          controller: TextEditingController(text: currentValue),
          decoration: InputDecoration(labelText: label),
          onChanged: (text) => value = text,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, value),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<int?> _showNumberFieldDialog(String label, String currentValue) async {
    String value = currentValue;
    return showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit $label'),
        content: TextField(
          controller: TextEditingController(text: currentValue),
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: label),
          onChanged: (text) => value = text,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final intValue = int.tryParse(value);
              Navigator.pop(context, intValue);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<String?> _showGenderSelectionDialog() async {
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Gender'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: Gender.values
              .map(
                (gender) => ListTile(
                  title: Text(_getGenderTitle(gender)),
                  onTap: () => Navigator.pop(context, _getGenderTitle(gender)),
                ),
              )
              .toList(),
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

  Future<String?> _showCategorySelectionDialog() async {
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Category'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: UserCategory.values
              .map(
                (category) => ListTile(
                  title: Text(_getCategoryTitle(category)),
                  onTap: () =>
                      Navigator.pop(context, _getCategoryTitle(category)),
                ),
              )
              .toList(),
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

  Future<String?> _showResidenceTypeSelectionDialog() async {
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Residence Type'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ResidenceType.values
              .map(
                (type) => ListTile(
                  title: Text(type == ResidenceType.onCampus
                      ? 'On Campus'
                      : 'Off Campus'),
                  onTap: () => Navigator.pop(
                      context,
                      type == ResidenceType.onCampus
                          ? 'oncampus'
                          : 'offcampus'),
                ),
              )
              .toList(),
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

  Future<String?> _showEmploymentTypeSelectionDialog() async {
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Employment Type'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: EmploymentType.values
              .map(
                (type) => ListTile(
                  title: Text(
                      _formatEmploymentType(type.toString().split('.').last)),
                  onTap: () =>
                      Navigator.pop(context, type.toString().split('.').last),
                ),
              )
              .toList(),
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

  Future<String?> _showEmploymentCategorySelectionDialog() async {
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Employment Category'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: EmploymentCategory.values
              .map(
                (category) => ListTile(
                  title: Text(_formatEmploymentCategory(
                      category.toString().split('.').last)),
                  onTap: () => Navigator.pop(
                      context, category.toString().split('.').last),
                ),
              )
              .toList(),
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

  Future<List<int>?> _showChildrenGradesDialog(
      List<dynamic> currentGrades) async {
    List<int> selectedGrades = List<int>.from(currentGrades);

    return showDialog<List<int>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Children\'s Grades'),
        content: StatefulBuilder(
          builder: (context, setState) => SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CheckboxListTile(
                  title: const Text('LKG'),
                  value: selectedGrades.contains(0),
                  onChanged: (bool? value) {
                    setState(() {
                      if (value == true) {
                        selectedGrades.add(0);
                      } else {
                        selectedGrades.remove(0);
                      }
                    });
                  },
                ),
                CheckboxListTile(
                  title: const Text('UKG'),
                  value: selectedGrades.contains(-1),
                  onChanged: (bool? value) {
                    setState(() {
                      if (value == true) {
                        selectedGrades.add(-1);
                      } else {
                        selectedGrades.remove(-1);
                      }
                    });
                  },
                ),
                ...List.generate(
                  12,
                  (index) => CheckboxListTile(
                    title: Text('Grade ${index + 1}'),
                    value: selectedGrades.contains(index + 1),
                    onChanged: (bool? value) {
                      setState(() {
                        if (value == true) {
                          selectedGrades.add(index + 1);
                        } else {
                          selectedGrades.remove(index + 1);
                        }
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, selectedGrades),
            child: const Text('Save'),
          ),
        ],
      ),
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
}