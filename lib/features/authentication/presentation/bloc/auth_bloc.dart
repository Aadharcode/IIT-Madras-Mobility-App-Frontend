
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/services/auth_service.dart';
import 'package:http/http.dart' as http;
import 'auth_event.dart';
import 'auth_state.dart';
import 'dart:convert';


class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthService _authService;
  static const String baseUrl = 'http://192.168.162.250:3000';

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
      await _authService.logout();
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
    String userCategoryString = enumToString(event.userCategory);
    String residenceTypeString = enumToString(event.residenceType);

    // Retrieve token from SharedPreferences
    final token = await _authService.getToken();

    if (token == null) {
      throw Exception('No token found');
    }

    // Prepare the request headers and body
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token', // Include the token in the Authorization header
    };


   final body = json.encode({
      'category': userCategoryString, // Enum as a string
      'residenceType': residenceTypeString, // Enum as a string
    });
    print(json.encode(body));

    // Make the API call to update the profile
    final response = await http.post(
      Uri.parse('$baseUrl/user/login/details'),
      headers: headers,
      body: body,
    );
    print(response.statusCode);

    if (response.statusCode == 200) {
      // If the update is successful, update the state with the new profile details
      final user = json.decode(response.body);
      emit(state.copyWith(
        isLoading: false,
        userCategory: user['category'],
        residenceType: user['residenceType'],
        isAuthenticated: true,
        error: null,
      ));

      
    } else {
      // If the API response is not 200, throw an error
      final error = json.decode(response.body);
      throw Exception(error['msg']);
    }
  } catch (e) {
    // Handle errors and update the state with the error message
    print(e);
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
      final token = await _authService.getToken();
      emit(state.copyWith(
        isAuthenticated: token != null,
      ));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }
}
