import 'package:equatable/equatable.dart';

enum UserCategory { student, faculty, nonFaculty, schoolRelative, others }

enum ResidenceType { onCampus, offCampus }

class AuthState extends Equatable {
  final bool isAuthenticated;
  final String? phoneNumber;
  final String? userId;
  final UserCategory? userCategory;
  final ResidenceType? residenceType;
  final String? error;
  final bool isLoading;

  const AuthState({
    this.isAuthenticated = false,
    this.phoneNumber,
    this.userId,
    this.userCategory,
    this.residenceType,
    this.error,
    this.isLoading = false,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    String? phoneNumber,
    String? userId,
    UserCategory? userCategory,
    ResidenceType? residenceType,
    String? error,
    bool? isLoading,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      userId: userId ?? this.userId,
      userCategory: userCategory ?? this.userCategory,
      residenceType: residenceType ?? this.residenceType,
      error: error ?? this.error,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object?> get props => [
        isAuthenticated,
        phoneNumber,
        userId,
        userCategory,
        residenceType,
        error,
        isLoading,
      ];
}
