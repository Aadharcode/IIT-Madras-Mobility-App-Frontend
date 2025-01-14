import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../authentication/presentation/bloc/auth_bloc.dart';
import '../../../authentication/presentation/bloc/auth_event.dart';
// import '../../../authentication/presentation/bloc/auth_state.dart';
import '../../../../main.dart';
import '../../../authentication/data/services/auth_service.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late AuthService authService;
  Map<String, dynamic>? userProfile;
  bool isLoading = true;
  String errorMessage = '';
  bool canDownloadData = false;

  @override
  void initState() {
    super.initState();
    authService = AuthService();
    _loadUserProfile();
    _checkDataAccess();
  }

  Future<void> _loadUserProfile() async {
    try {
      setState(() {
        isLoading = true;
      });

      final profile = await authService.getUserProfile();

      setState(() {
        userProfile = profile;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = e.toString();
      });
    }
  }

  Future<void> _checkDataAccess() async {
    try {
      final token = await authService.getToken();
      if (token == null) return;

      final response = await http.head(
        Uri.parse('http://ec2-13-232-246-85.ap-south-1.compute.amazonaws.com/api/trip/getData'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          canDownloadData = true;
        });
      }
    } catch (e) {
      print('Error checking data access: $e');
    }
  }

  Future<void> _downloadTripData() async {
    try {
      final token = await authService.getToken();
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Authentication error')),
        );
        return;
      }

      final response = await http.get(
        Uri.parse('http://ec2-13-232-246-85.ap-south-1.compute.amazonaws.com/api/trip/getData'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'text/csv',
        },
      );

      if (response.statusCode == 200) {
        // Get temporary directory
        final directory = await getApplicationDocumentsDirectory();
        final filePath = '${directory.path}/trip_data.csv';

        // Write the CSV data to a file
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);

        // Share the file
        await Share.shareXFiles(
          [XFile(filePath)],
          subject: 'Trip Data',
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('CSV file ready to share')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to download data')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: const Text('Profile'),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
              ? Center(child: Text('Error: $errorMessage'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 24),
                      CircleAvatar(
                        radius: 60,
                        backgroundColor:
                            theme.colorScheme.primary.withOpacity(0.1),
                        child: Icon(
                          Icons.person,
                          size: 60,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        "Name: ${userProfile?['name'] ?? 'Not Available'}",
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 5),
                      Text(
                        "Phone: ${userProfile?['number'] ?? 'Not Available'}",
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: Card(
                          shape: theme.cardTheme.shape,
                          elevation: theme.cardTheme.elevation,
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Category",
                                  style: theme.textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  userProfile?['category'] ?? 'Not Specified',
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: double.infinity,
                        child: Card(
                          shape: theme.cardTheme.shape,
                          elevation: theme.cardTheme.elevation,
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Residence Type",
                                  style: theme.textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  userProfile?['residentType'] ??
                                      'Not Specified',
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (canDownloadData) ...[
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _downloadTripData,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            minimumSize: const Size(double.infinity, 50),
                          ),
                          child: const Text(
                            'Download Trip Data (CSV)',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      ElevatedButton(
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
                          minimumSize: const Size(double.infinity, 50),
                        ),
                        child: const Text(
                          'Log Out',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
