import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/services/auth_service.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthService _authService;

  AuthBloc({AuthService? authService}) 
      : _authService = authService ?? AuthService(),
        super(const AuthState()) {
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
    // if(event.phoneNumber=="8949462906"){
    //    emit(state.copyWith(
    //     isLoading: false,
    //     phoneNumber: event.phoneNumber,
    //   ));
    //   return;
    // }
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
      // if(event.otp=="123456"){
      //   emit(state.copyWith(
      //   isLoading: false,
      //   isAuthenticated: true,
      //   userId: "6763f3ba0bb2910e81ce8b0b",
      // ));
      // return;
      // }
      emit(state.copyWith(isLoading: true, error: null));
      final response = await _authService.verifyOtp(
        state.phoneNumber!,
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