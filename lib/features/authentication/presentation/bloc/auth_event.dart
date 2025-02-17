import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'auth_state.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class SendPhoneNumberVerification extends AuthEvent {
  final String phoneNumber;
  final String name;

  const SendPhoneNumberVerification(this.phoneNumber, this.name);

  @override
  List<Object> get props => [phoneNumber, name];
}

class LogoutEvent extends AuthEvent {
  const LogoutEvent();
}
class LoginEvent extends AuthEvent {
  final String phoneNumber;
  const LoginEvent(this.phoneNumber);
}

class VerifyOTP extends AuthEvent {
  final String otp;
  final String name;

  const VerifyOTP(this.otp, this.name);

  @override
  List<Object> get props => [otp];
}

class UpdateUserProfile extends AuthEvent {
  final UserCategory? userCategory;
  final ResidenceType? residenceType;
  final EmploymentType? employmentType;
  final EmploymentCategory? employmentCategory;
  final List<int>? childrenDetails;
  final Gender? gender;
  final int? age;
  final BuildContext context;

  const UpdateUserProfile({
    this.userCategory,
    this.age,
    this.residenceType,
    this.gender,
    this.employmentType,
    this.employmentCategory,
    this.childrenDetails,
    required this.context,
  });

  @override
  List<Object?> get props => [
        userCategory,
        residenceType,
        gender,
        employmentType,
        employmentCategory,
        childrenDetails,
      ];
}


class SignOut extends AuthEvent {}

class CheckAuthStatus extends AuthEvent {
  const CheckAuthStatus();
}
