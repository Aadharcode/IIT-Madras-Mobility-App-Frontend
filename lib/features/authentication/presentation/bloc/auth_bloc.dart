import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/services/auth_service.dart';
import 'package:http/http.dart' as http;
import 'auth_event.dart';
import 'auth_state.dart';
import 'dart:convert';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthService _authService;
  static const String baseUrl =
      'http://ec2-13-232-246-85.ap-south-1.compute.amazonaws.com/api';
      // 'http://192.168.10.250:3000/';

  AuthBloc({AuthService? authService})
      : _authService = authService ?? AuthService(),
        super(const AuthState()) {
    on<SendPhoneNumberVerification>(_onSendPhoneNumberVerification);
    on<VerifyOTP>(_onVerifyOTP);
    on<UpdateUserProfile>(_onUpdateUserProfile);
    on<SignOut>(_onSignOut);
    on<LogoutEvent>(_onLogoutEvent);
    on<CheckAuthStatus>(_onCheckAuthStatus);
  }

  Future<void> _onSendPhoneNumberVerification(
    SendPhoneNumberVerification event,
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(state.copyWith(isLoading: true, error: null));
      await _authService.sendOtp(event.phoneNumber);
      emit(state.copyWith(
        isLoading: false,
        phoneNumber: event.phoneNumber,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onVerifyOTP(
    VerifyOTP event,
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(state.copyWith(isLoading: true, error: null));
      final response = await _authService.verifyOtp(
        state.phoneNumber!,
        event.name,
        event.otp,
      );

      emit(state.copyWith(
        isLoading: false,
        isAuthenticated: true,
        userId: response['user']['_id'],
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
    }
  }

  String enumToString(Enum enumValue) {
    return enumValue.toString().split('.').last;
  }

  Future<void> _onLogoutEvent(
    LogoutEvent event,
    Emitter<AuthState> emit,
  ) async {
    try {
      await _authService.clearSession();
      emit(const AuthState());
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> _onUpdateUserProfile(
  UpdateUserProfile event,
  Emitter<AuthState> emit,
) async {
  try {
    emit(state.copyWith(isLoading: true, error: null));
    print('🔄 Starting user profile update...');

    final token = await _authService.getToken();
    if (token == null) {
      print('❌ No token found!');
      throw Exception('No token found');
    }
    print('🔑 Token retrieved successfully.');

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    // Prepare dynamic request body
    final body = <String, dynamic>{};
    final userCategory = event.userCategory;
    final residenceType = event.residenceType;
    final employmentType = event.employmentType;
    final employmentCategory = event.employmentCategory;
    final gender = event.gender;
    final age = event.age;

    if (userCategory != null) {
      body['category'] = enumToString(userCategory);
    }
    if (gender != null) {
      body['gender'] = enumToString(gender);
    }
    if (residenceType != null) {
      body['residenceType'] = enumToString(residenceType);
    }
    if (employmentType != null) {
      body['employmentType'] = enumToString(employmentType);
    }
    if (employmentCategory != null) {
      body['employmentCategory'] = enumToString(employmentCategory);
    }
    if (age != null) {
      body['age'] = age;
    }
    if (event.childrenDetails != null) {
      body['childrenDetails'] = event.childrenDetails;
    }

    print('📤 Request body: ${json.encode(body)}');

    final response = await http.post(
      Uri.parse('$baseUrl/user/login/details'),
      headers: headers,
      body: json.encode(body),
    );

    print('📬 Response status code: ${response.statusCode}');

    if (response.statusCode == 200) {
      final user = json.decode(response.body);
      print('✅ Profile update successful: $user');

      emit(state.copyWith(
        isLoading: false,
        userCategory: event.userCategory ?? state.userCategory,
        residenceType: event.residenceType ?? state.residenceType,
        employmentType: event.employmentType ?? state.employmentType,
        gender: event.gender ?? state.gender,
        age: event.age ?? state.age,
        employmentCategory: event.employmentCategory ?? state.employmentCategory,
        childrenDetails: event.childrenDetails ?? state.childrenDetails,
        isAuthenticated: true,
        error: null,
      ));

      print(
          '🎉 State updated with: ${state.userCategory}, ${state.residenceType}, ${state.employmentType}, ${state.employmentCategory}, ${state.childrenDetails}, ${state.isAuthenticated}');
    } else {
      final error = json.decode(response.body);
      print('⚠️ Profile update failed with error: ${error['msg']}');
      throw Exception(error['msg']);
    }
  } catch (e) {
    print('🚨 Error occurred: $e');
    emit(state.copyWith(
      isLoading: false,
      error: e.toString(),
    ));
  }
}


  Future<void> _onSignOut(
    SignOut event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthState());
  }

  Future<void> _onCheckAuthStatus(
    CheckAuthStatus event,
    Emitter<AuthState> emit,
  ) async {
    try {
      final session = await _authService.getSession();

      if (session != null) {
        emit(state.copyWith(
          isAuthenticated: true,
          userId: session.userId,
          userCategory: session.userCategory,
          residenceType: session.residenceType,
        ));
      }
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }
}
