import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import 'user_profile_screen.dart';
import '../../../trip_tracking/presentation/screens/trip_tracking_screen.dart';

class OTPVerificationScreen extends StatefulWidget {
  final String phoneNumber;
  final String name;

  const OTPVerificationScreen({
    super.key,
    required this.phoneNumber,
    required this.name,
  });

  @override
  State<OTPVerificationScreen> createState() => _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends State<OTPVerificationScreen> {
  final _otpController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify OTP'),
        centerTitle: true,
      ),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          print('🔄 OTP Screen State Update:');
          print('- isAuthenticated: ${state.isAuthenticated}');
          print('- userId: ${state.userId}');
          print('- userCategory: ${state.userCategory}');
          print('- residenceType: ${state.residenceType}');
          print('- error: ${state.error}');

          if (state.error != null) {
            print('❌ Error in OTP verification: ${state.error}');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.error!)),
            );
          }
          if (state.isAuthenticated) {
            print('✅ Authentication successful - navigating to profile screen');
            if (state.userCategory != null && state.residenceType != null) {
              print(
                  '👤 User profile already complete - navigating to trip tracking');
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (_) => TripTrackingScreen(userId: state.userId!),
                ),
              );
            } else {
              print(
                  '👤 User profile incomplete - navigating to profile screen');
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (_) => const UserProfileScreen(),
                ),
              );
            }
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
                  Text(
                    'Enter the OTP sent to\n${widget.phoneNumber}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 32),
                  TextFormField(
                    controller: _otpController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(
                      labelText: 'OTP',
                      hintText: 'Enter 6-digit OTP',
                      border: OutlineInputBorder(),
                      counterText: '',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter OTP';
                      }
                      if (value.length != 6) {
                        return 'Please enter a valid 6-digit OTP';
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
                                VerifyOTP(_otpController.text, widget.name),
                              );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: const Text('Verify OTP'),
                    ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      // TODO: Implement resend OTP functionality
                      context.read<AuthBloc>().add(
                            SendPhoneNumberVerification(
                                widget.phoneNumber, widget.name),
                          );
                    },
                    child: const Text('Resend OTP'),
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
