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
  // 'http://192.168.73.250:3000';

  AuthBloc({AuthService? authService})
      : _authService = authService ?? AuthService(),
        super(const AuthState()) {
    on<SendPhoneNumberVerification>(_onSendPhoneNumberVerification);
    on<VerifyOTP>(_onVerifyOTP);
    on<UpdateUserProfile>(_onUpdateUserProfile);
    on<SignOut>(_onSignOut);
    on<LogoutEvent>(_onLogoutEvent);
    on<LoginEvent>(_onLogin);
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

  Future<void> _onLogin(LoginEvent event, Emitter<AuthState> emit) async {
    try {
      emit(state.copyWith(isLoading: true, error: null, isLoginFlow: true));

      // Use the existing sendOtp method but mark it as login flow
      await _authService.sendOtp(event.phoneNumber);
      emit(state.copyWith(
        isLoading: false,
        phoneNumber: event.phoneNumber,
        isLoginFlow: true,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: e.toString(),
        isLoginFlow: false,
      ));
    }
  }

  // Gender? _parseGender(String? value) {
  //   switch (value?.toLowerCase()) {
  //     case 'male':
  //       return Gender.male;
  //     case 'female':
  //       return Gender.female;
  //     case 'nonbinary':
  //       return Gender.nonBinary;
  //     case 'noreveal':
  //       return Gender.noReveal;
  //     default:
  //       return null;
  //   }
  // }

  // UserCategory? _parseUserCategory(String? value) {
  //   switch (value?.toLowerCase()) {
  //     case 'student':
  //       return UserCategory.student;
  //     case 'employee':
  //       return UserCategory.employee;
  //     case 'parent':
  //       return UserCategory.parent;
  //     case 'relative':
  //       return UserCategory.relative;
  //     default:
  //       return null;
  //   }
  // }

  // ResidenceType? _parseResidenceType(String? value) {
  //   switch (value?.toLowerCase()) {
  //     case 'oncampus':
  //       return ResidenceType.onCampus;
  //     case 'offcampus':
  //       return ResidenceType.offCampus;
  //     default:
  //       return null;
  //   }
  // }

  // EmploymentType? _parseEmploymentType(String? value) {
  //   switch (value?.toLowerCase()) {
  //     case 'permanent':
  //       return EmploymentType.permanent;
  //     case 'contract':
  //       return EmploymentType.contract;
  //     case 'intern':
  //       return EmploymentType.intern;
  //     default:
  //       return null;
  //   }
  // }

  // EmploymentCategory? _parseEmploymentCategory(String? value) {
  //   switch (value?.toLowerCase()) {
  //     case 'technical':
  //       return EmploymentCategory.technical;
  //     case 'research':
  //       return EmploymentCategory.research;
  //     case 'admin':
  //       return EmploymentCategory.admin;
  //     case 'school':
  //       return EmploymentCategory.school;
  //     case 'other':
  //       return EmploymentCategory.other;
  //     default:
  //       return null;
  //   }
  // }

  Future<void> _onVerifyOTP(
    VerifyOTP event,
    Emitter<AuthState> emit,
  ) async {
    try {
      print('🔄 Starting OTP verification process');
      emit(state.copyWith(isLoading: true, error: null));

      final response = await _authService.verifyOtp(
        state.phoneNumber!,
        event.name,
        event.otp,
      );

      print('📥 OTP verification response:');
      print(response['user']);
      print('- userId: ${response['user']['_id']}');
      print('- userCategory: ${response['user']['category']}');
      print('- residenceType: ${response['user']['residentType']}');
      print('- gender: ${response['user']['gender']}');

      // Check if user profile is complete
      final userCategory = response['user']['category'];
      final residenceType = response['user']['residentType'];
      final gender = response['user']['gender'];

      // Convert string values to enums if they exist
      UserCategory? parsedCategory;
      ResidenceType? parsedResidence;
      Gender? parsedGender;

      if (userCategory != null) {
        try {
          parsedCategory = UserCategory.values.firstWhere(
            (e) => e.toString().split('.').last == userCategory,
          );
        } catch (e) {
          print('⚠️ Invalid userCategory value: $userCategory');
        }
      }

      if (residenceType != null) {
        try {
          parsedResidence = ResidenceType.values.firstWhere(
            (e) => e.toString().split('.').last == residenceType,
          );
        } catch (e) {
          print('⚠️ Invalid residenceType value: $residenceType');
        }
      }

      if (gender != null) {
        try {
          parsedGender = Gender.values.firstWhere(
            (e) => e.toString().split('.').last == gender,
          );
        } catch (e) {
          print('⚠️ Invalid gender value: $gender');
        }
      }

      emit(state.copyWith(
        isLoading: false,
        isAuthenticated: true,
        name: response['user']['name'],
        userId: response['user']['_id'],
        userCategory: parsedCategory,
        residenceType: parsedResidence,
        gender: parsedGender,
      ));

      print('✅ State updated after OTP verification:');
      print('- isAuthenticated: ${state.isAuthenticated}');
      print('- userId: ${state.userId}');
      print('- userCategory: ${state.userCategory}');
      print('- residenceType: ${state.residenceType}');
      print('- gender: ${state.gender}');
    } catch (e) {
      print('❌ Error in OTP verification: $e');
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
      final name = event.name;

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
      if (event.name != null) {
        body['name'] = event.name;
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
          employmentCategory:
              event.employmentCategory ?? state.employmentCategory,
          childrenDetails: event.childrenDetails ?? state.childrenDetails,
          isAuthenticated: true,
          name: event.name ?? state.name,
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
