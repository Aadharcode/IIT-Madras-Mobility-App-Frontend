import 'package:equatable/equatable.dart';

enum UserCategory { student, employee , parent, relative}
enum ResidenceType { onCampus, offCampus }
enum Gender {male, female, nonBinary, noReveal }
enum EmploymentType { permanent, contract, intern }
enum EmploymentCategory { technical, research, admin, school, other }

class AuthState extends Equatable {
  final bool isAuthenticated;
  final String? phoneNumber;
  final String? userId;
  final Gender? gender;
  final int? age;
  final UserCategory? userCategory;
  final ResidenceType? residenceType;
  final EmploymentType? employmentType;
  final EmploymentCategory? employmentCategory;
  final List<int>? childrenDetails;
  final String? error;
  final bool isLoading;

  const AuthState({
    this.isAuthenticated = false,
    this.gender,
    this.age,
    this.phoneNumber,
    this.userId,
    this.userCategory,
    this.residenceType,
    this.employmentType,
    this.employmentCategory,
    this.childrenDetails,
    this.error,
    this.isLoading = false,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    String? phoneNumber,
    String? userId,
    Gender? gender,
    int? age,
    UserCategory? userCategory,
    ResidenceType? residenceType,
    EmploymentType? employmentType,
    EmploymentCategory? employmentCategory,
    List<int>? childrenDetails,
    String? error,
    bool? isLoading,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      userId: userId ?? this.userId,
      gender: gender ?? this.gender,
      age: age ?? this.age,
      userCategory: userCategory ?? this.userCategory,
      residenceType: residenceType ?? this.residenceType,
      employmentType: employmentType ?? this.employmentType,
      employmentCategory: employmentCategory ?? this.employmentCategory,
      childrenDetails: childrenDetails ?? this.childrenDetails,
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
        gender,
        age,
        residenceType,
        employmentType,
        employmentCategory,
        childrenDetails,
        error,
        isLoading,
      ];
}