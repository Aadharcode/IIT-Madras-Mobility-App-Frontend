import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'features/authentication/presentation/bloc/auth_bloc.dart';
import 'features/authentication/presentation/bloc/auth_state.dart';
import 'features/authentication/presentation/screens/otp_verification_screen.dart';
import 'features/authentication/presentation/screens/user_profile_screen.dart';
import 'features/authentication/presentation/bloc/auth_event.dart';
import 'features/trip_tracking/data/services/location_service.dart';
import 'features/trip_tracking/presentation/bloc/trip_bloc.dart';
import 'features/trip_tracking/presentation/screens/trip_tracking_screen.dart';
import 'features/trip_tracking/data/services/background_service.dart'; // Add this import
import 'package:flutter/services.dart';
import 'features/trip_tracking/data/services/notification_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:io' show Platform;
import 'package:permission_handler/permission_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Remove notification initialization from here since we'll do it after permissions
  // await NotificationService.initialize(); // Initialize notification service
  await NotificationService.registerWorkManager(); // Register background task
  runApp(const MyApp());
}

Future<bool> requestExactAlarmPermission() async {
  if (Platform.isAndroid) {
    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    final bool? result = await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestExactAlarmsPermission();

    return result ?? false;
  }
  return true;
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => AuthBloc()..add(const CheckAuthStatus()),
        ),
        BlocProvider(
          create: (context) => TripBloc(
            locationService: LocationService(),
          ),
        ),
      ],
      child: MaterialApp(
        title: 'IITM Mobility App',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF1A73E8),
            primary: const Color(0xFF1A73E8),
            secondary: const Color(0xFF34A853),
            tertiary: const Color(0xFFEA4335),
            background: Colors.white,
          ),
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            backgroundColor: Colors.white,
            elevation: 0,
            foregroundColor: Color(0xFF1A73E8),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF1A73E8), width: 2),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          cardTheme: CardTheme(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.grey[200]!),
            ),
            color: Colors.white,
          ),
        ),
        home: const AuthenticationWrapper(),
      ),
    );
  }
}

class AuthenticationWrapper extends StatelessWidget {
  const AuthenticationWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        print('🔐 AuthenticationWrapper State:');
        print('- isAuthenticated: ${state.isAuthenticated}');
        print('- userId: ${state.userId}');
        print('- userCategory: ${state.userCategory}');
        print('- residenceType: ${state.residenceType}');
        print('- phoneNumber: ${state.phoneNumber}');

        if (state.isAuthenticated) {
          if (state.userId != null) {
            print(
                '✅ Navigating to TripTrackingScreen with userId: ${state.userId}');
            return TripTrackingScreen(userId: state.userId!);
          }
          if (state.userCategory == null || state.residenceType == null) {
            print('⚠️ Missing profile info - redirecting to UserProfileScreen');
            return const UserProfileScreen();
          }
        }
        print('🔄 Showing PhoneAuthScreen - not authenticated');
        return const PhoneAuthScreen();
      },
    );
  }
}

class PhoneAuthScreen extends StatefulWidget {
  const PhoneAuthScreen({super.key});

  @override
  State<PhoneAuthScreen> createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends State<PhoneAuthScreen> {
  final _phoneController = TextEditingController();
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool? _hasConsent;

  @override
  void dispose() {
    _phoneController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<bool> _requestPermissions() async {
    // First request basic location permission
    final locationPermission = await Permission.location.request();
    if (locationPermission.isDenied || locationPermission.isPermanentlyDenied) {
      return false;
    }

    // For Android, request background location with proper guidance
    if (Platform.isAndroid) {
      // Show guidance dialog before requesting background location
      if (!context.mounted) return false;
      final proceedWithBackground = await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Background Location Required'),
                content: const Text(
                    'This app needs background location access to track your campus entry/exit even when the app is closed.\n\nOn the next screen, please select "Allow all the time" to enable this feature.'),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(false);
                    },
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(true);
                    },
                    child: const Text('Continue'),
                  ),
                ],
              );
            },
          ) ??
          false;

      if (!proceedWithBackground) return false;

      final backgroundLocation = await Permission.locationAlways.request();
      // Check if background permission was granted
      final locationAlwaysStatus = await Permission.locationAlways.status;
      if (!locationAlwaysStatus.isGranted) {
        if (!context.mounted) return false;
        // Show settings guidance if not granted
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Additional Setup Required'),
              content: const Text(
                  'Please select "Allow all the time" in the location permission settings to enable background tracking.'),
              actions: [
                TextButton(
                  onPressed: () async {
                    Navigator.of(context).pop();
                    await openAppSettings();
                  },
                  child: const Text('Open Settings'),
                ),
              ],
            );
          },
        );
        return false;
      }
    }

    // Request notification permission
    final notificationPermission = await Permission.notification.request();
    if (notificationPermission.isDenied ||
        notificationPermission.isPermanentlyDenied) {
      return false;
    }

    // Request exact alarm permission (Android only)
    if (Platform.isAndroid) {
      final hasExactAlarm = await requestExactAlarmPermission();
      if (!hasExactAlarm) return false;
    }

    // Initialize notification service after permissions are granted
    await NotificationService.initialize();

    return true;
  }

  Future<bool> _checkPermissions() async {
    final locationStatus = await Permission.location.status;
    if (!locationStatus.isGranted) return false;

    if (Platform.isAndroid) {
      final backgroundLocationStatus = await Permission.locationAlways.status;
      if (!backgroundLocationStatus.isGranted) return false;
    }

    final notificationStatus = await Permission.notification.status;
    if (!notificationStatus.isGranted) return false;

    if (Platform.isAndroid) {
      final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
      final hasExactAlarm = await flutterLocalNotificationsPlugin
              .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin>()
              ?.requestExactAlarmsPermission() ??
          false;
      if (!hasExactAlarm) return false;
    }

    return true;
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Permissions Required'),
          content: const Text(
              'This app requires location access "all the time" and notification permissions to function properly. Please grant all permissions to continue.'),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                // Check current permission status first
                final hasExistingPermissions = await _checkPermissions();
                if (hasExistingPermissions) {
                  setState(() {
                    _hasConsent = true;
                  });
                  return;
                }
                // Only request if not already granted
                final hasPermissions = await _requestPermissions();
                if (hasPermissions) {
                  setState(() {
                    _hasConsent = true;
                  });
                }
              },
              child: const Text('Review Permissions'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                SystemNavigator.pop();
              },
              child: const Text('Exit App'),
            ),
          ],
        );
      },
    );
  }

  void _showExitDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Exit App'),
          content: const Text(
              'You need to accept the terms to use this app. Would you like to exit?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Review Again'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                SystemNavigator.pop(); // This will close the app
              },
              child: const Text('Exit App'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildConsentSection(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey[200]!,
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      constraints: const BoxConstraints(maxHeight: 400),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Welcome to IITM Mobility Research',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Flexible(
            child: SingleChildScrollView(
              child: Text(
                'This app is part of a research initiative by IIT Madras to improve campus mobility and sustainability. By participating, you agree to:\n\n'
                '• Share location data (including background location) for tracking campus entry/exit\n'
                '• Receive notifications for trip verification and updates\n'
                '• Allow exact alarm permissions for scheduled checks\n'
                '• Contribute to research aimed at reducing traffic congestion and protecting campus wildlife\n'
                '• Help us develop better transportation solutions for our campus community\n\n'
                'Your data will be used solely for research purposes and handled with strict confidentiality.',
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _hasConsent = false;
                    });
                    _showExitDialog();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.error,
                    foregroundColor: Colors.white,
                    textStyle: theme.textTheme.bodyMedium,
                  ),
                  child: const Text('Maybe Later'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    // First check if permissions are already granted
                    final hasExistingPermissions = await _checkPermissions();
                    if (hasExistingPermissions) {
                      setState(() {
                        _hasConsent = true;
                      });
                      return;
                    }

                    // If not, request permissions
                    final hasPermissions = await _requestPermissions();
                    if (hasPermissions) {
                      setState(() {
                        _hasConsent = true;
                      });
                    } else {
                      _showPermissionDeniedDialog();
                    }
                  },
                  child: const Text('Participate'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state.error != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.error!),
                backgroundColor: theme.colorScheme.error,
              ),
            );
          }
          if (state.phoneNumber != null && state.isAuthenticated == false) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => OTPVerificationScreen(
                  phoneNumber: state.phoneNumber!,
                  name: _nameController.text,
                ),
              ),
            );
          }
        },
        builder: (context, state) {
          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 1),
                    Center(
                      child: Hero(
                        tag: 'app_logo_image',
                        child: Container(
                          height: 180,
                          width: 180,
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Image.asset(
                              'assets/images/app_logo.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'IITM Mobility',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Help us build a sustainable campus mobility solution',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    if (_hasConsent == null)
                      _buildConsentSection(theme)
                    else if (_hasConsent == true)
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey[200]!,
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Enter your mobile number and name',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'We\'ll call you with a verification code',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 24),
                            TextFormField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              style: theme.textTheme.titleMedium,
                              decoration: const InputDecoration(
                                labelText: 'Phone Number',
                                hintText: 'Enter your mobile number',
                                prefixText: '+91 ',
                                prefixIcon: Icon(Icons.phone_android),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your phone number';
                                }
                                if (value.length != 10) {
                                  return 'Please enter a valid 10-digit phone number';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _nameController,
                              style: theme.textTheme.titleMedium,
                              decoration: const InputDecoration(
                                labelText: 'Name',
                                hintText: 'Enter your Name',
                                prefixIcon: Icon(Icons.person_outline),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your name';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 24),
                            if (state.isLoading)
                              const Center(child: CircularProgressIndicator())
                            else
                              ElevatedButton(
                                onPressed: () {
                                  if (_formKey.currentState!.validate()) {
                                    context.read<AuthBloc>().add(
                                          SendPhoneNumberVerification(
                                            _phoneController.text,
                                            _nameController.text,
                                          ),
                                        );
                                  }
                                },
                                child: const Text('Get OTP'),
                              ),

                              ElevatedButton(
                                onPressed: () {
                                  if (_formKey.currentState!.validate()) {
                                    context.read<AuthBloc>().add(
                                          LoginEvent(
                                            _phoneController.text,
                                          ),
                                        );
                                  }
                                },
                                child: const Text('Login'),
                              ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SvgPicture.asset(
                          'assets/images/logo.svg',
                          height: 40,
                          width: 40,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'IIT Madras',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
