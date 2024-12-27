import '../../presentation/bloc/auth_state.dart';

class UserSession {
  final String token;
  final DateTime expiryDate;
  final String userId;
  final UserCategory? userCategory;
  final ResidenceType? residenceType;

  UserSession({
    required this.token,
    required this.expiryDate,
    required this.userId,
    this.userCategory,
    this.residenceType,
  });

  Map<String, dynamic> toJson() => {
        'token': token,
        'expiryDate': expiryDate.toIso8601String(),
        'userId': userId,
        'userCategory': userCategory?.toString(),
        'residenceType': residenceType?.toString(),
      };

  factory UserSession.fromJson(Map<String, dynamic> json) {
    return UserSession(
      token: json['token'],
      expiryDate: DateTime.parse(json['expiryDate']),
      userId: json['userId'],
      userCategory: json['userCategory'] != null
          ? UserCategory.values.firstWhere(
              (e) => e.toString() == json['userCategory'],
            )
          : null,
      residenceType: json['residenceType'] != null
          ? ResidenceType.values.firstWhere(
              (e) => e.toString() == json['residenceType'],
            )
          : null,
    );
  }
}
