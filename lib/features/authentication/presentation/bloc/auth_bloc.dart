import 'package:flutter_bloc/flutter_bloc.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc() : super(const AuthState()) {
    on<SendPhoneNumberVerification>(_onSendPhoneNumberVerification);
    on<VerifyOTP>(_onVerifyOTP);
    on<UpdateUserProfile>(_onUpdateUserProfile);
    on<SignOut>(_onSignOut);
    on<LogoutEvent>(_onLogoutEvent);
  }

  Future<void> _onSendPhoneNumberVerification(
    SendPhoneNumberVerification event,
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(state.copyWith(isLoading: true, error: null));
      // TODO: Implement actual phone verification logic
      // For now, we'll just simulate the process
      await Future.delayed(const Duration(seconds: 2));
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

  Future<void> _onLogoutEvent(
    LogoutEvent event,
    Emitter<AuthState> emit,
  ) async {
    try {
      // Perform any cleanup logic (e.g., clearing session or cache data)
      emit(state.copyWith(
        isAuthenticated: false,
        phoneNumber: null,
        userCategory: null,
        residenceType: null,
        userId: null,
        error: null,
      ));
    } catch (e) {
      emit(state.copyWith(
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
      // TODO: Implement actual OTP verification logic
      // For now, we'll just simulate the process
      await Future.delayed(const Duration(seconds: 2));
      emit(state.copyWith(
        isLoading: false,
        isAuthenticated: true,
        userId: 'USER_${DateTime.now().millisecondsSinceEpoch}',
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onUpdateUserProfile(
    UpdateUserProfile event,
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(state.copyWith(isLoading: true, error: null));
      // TODO: Implement actual profile update logic
      await Future.delayed(const Duration(seconds: 1));
      emit(state.copyWith(
        isLoading: false,
        userCategory: event.userCategory,
        residenceType: event.residenceType,
        isAuthenticated: true,
        error: null,
      ));
    } catch (e) {
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
} 