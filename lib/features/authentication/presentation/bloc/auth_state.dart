import 'package:equatable/equatable.dart';

enum UserCategory { student, employee, parent, relative }

enum ResidenceType { onCampus, offCampus }

enum Gender { male, female, nonBinary, noReveal }

enum EmploymentType { permanent, contract, intern }

enum EmploymentCategory { technical, research, admin, school, other }

class AuthState extends Equatable {
  final bool isAuthenticated;
  final String? phoneNumber;
  final String? userId;
  final Gender? gender;
  final int? age;
  final String? name;
  final UserCategory? userCategory;
  final ResidenceType? residenceType;
  final EmploymentType? employmentType;
  final EmploymentCategory? employmentCategory;
  final List<int>? childrenDetails;
  final String? error;
  final bool isLoading;
  final bool isLoginFlow;

  const AuthState({
    this.isAuthenticated = false,
    this.gender,
    this.age,
    this.phoneNumber,
    this.userId,
    this.userCategory,
    this.residenceType,
    this.employmentType,
    this.name,
    this.employmentCategory,
    this.childrenDetails,
    this.error,
    this.isLoading = false,
    this.isLoginFlow = false,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    String? phoneNumber,
    String? userId,
    Gender? gender,
    int? age,
    String? name,
    UserCategory? userCategory,
    ResidenceType? residenceType,
    EmploymentType? employmentType,
    EmploymentCategory? employmentCategory,
    List<int>? childrenDetails,
    String? error,
    bool? isLoading,
    bool? isLoginFlow,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      userId: userId ?? this.userId,
      gender: gender ?? this.gender,
      age: age ?? this.age,
      name: name ?? this.name,
      userCategory: userCategory ?? this.userCategory,
      residenceType: residenceType ?? this.residenceType,
      employmentType: employmentType ?? this.employmentType,
      employmentCategory: employmentCategory ?? this.employmentCategory,
      childrenDetails: childrenDetails ?? this.childrenDetails,
      error: error ?? this.error,
      isLoading: isLoading ?? this.isLoading,
      isLoginFlow: isLoginFlow ?? this.isLoginFlow,
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
        name,
        employmentCategory,
        childrenDetails,
        error,
        isLoading,
        isLoginFlow,
      ];
}
