import 'package:equatable/equatable.dart';
import 'auth_state.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class SendPhoneNumberVerification extends AuthEvent {
  final String phoneNumber;

  const SendPhoneNumberVerification(this.phoneNumber);

  @override
  List<Object> get props => [phoneNumber];
}

class LogoutEvent extends AuthEvent {
  const LogoutEvent();
}
class VerifyOTP extends AuthEvent {
  final String otp;

  const VerifyOTP(this.otp);

  @override
  List<Object> get props => [otp];
}

class UpdateUserProfile extends AuthEvent {
  final UserCategory userCategory;
  final ResidenceType residenceType;

  const UpdateUserProfile({
    required this.userCategory,
    required this.residenceType,
  });

  @override
  List<Object> get props => [userCategory, residenceType];
}

class SignOut extends AuthEvent {} 