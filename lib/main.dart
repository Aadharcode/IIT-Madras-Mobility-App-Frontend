import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'features/authentication/presentation/bloc/auth_bloc.dart';
import 'features/authentication/presentation/bloc/auth_state.dart';
import 'features/authentication/presentation/screens/otp_verification_screen.dart';
import 'features/authentication/presentation/screens/user_profile_screen.dart';
import 'features/authentication/presentation/bloc/auth_event.dart';
import 'features/trip_tracking/data/services/location_service.dart';
import 'features/trip_tracking/presentation/bloc/trip_bloc.dart';
import 'features/trip_tracking/presentation/screens/trip_tracking_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => AuthBloc()),
        BlocProvider(
          create: (context) => TripBloc(
            locationService: LocationService(),
          ),
        ),
      ],
      child: MaterialApp(
        title: 'IITM Mobility App',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
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
        if (state.isAuthenticated) {
          if (state.userCategory != null && state.residenceType != null) {
            return TripTrackingScreen(userId: state.userId!);
          }
          return const UserProfileScreen();
        }
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
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('IITM Mobility'),
        centerTitle: true,
      ),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state.error != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.error!)),
            );
          }
          if (state.phoneNumber != null) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => OTPVerificationScreen(
                  phoneNumber: state.phoneNumber!,
                ),
              ),
            );
          }
        },
        builder: (context, state) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Welcome to IITM Mobility',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 32),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number',
                      hintText: 'Enter your mobile number',
                      prefixText: '+91 ',
                      border: OutlineInputBorder(),
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
                  if (state.isLoading)
                    const CircularProgressIndicator()
                  else
                    ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          context.read<AuthBloc>().add(
                                SendPhoneNumberVerification(_phoneController.text),
                              );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: const Text('Get OTP'),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
