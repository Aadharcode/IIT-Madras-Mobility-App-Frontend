import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_session.dart';
export 'auth_service.dart';

class AuthException implements Exception {
  final String message;
  final String? code;

  AuthException(this.message, {this.code});

  @override
  String toString() => message;
}

class AuthService {
  static const String baseUrl =
      'http://ec2-13-232-246-85.ap-south-1.compute.amazonaws.com/api';
  static const String tokenKey = 'kjbnaeildnflia';
  static const String sessionKey = 'user_session';

  Future<void> sendOtp(String phoneNumber) async {
    try {
      print('📱 Attempting to send OTP to: $phoneNumber');
      print('🌐 Making request to: $baseUrl/user/login');

      final body = json.encode({'number': int.parse(phoneNumber)});
      print('📦 Request body: $body');

      final response = await http.post(
        Uri.parse('$baseUrl/user/login'),
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      print('📥 Response status code: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      if (response.statusCode != 200) {
        final errorMsg =
            json.decode(response.body)['msg'] ?? 'Failed to send OTP';
        throw AuthException(errorMsg, code: response.statusCode.toString());
      }

      print('✅ OTP sent successfully');
    } catch (e, stackTrace) {
      print('❌ Exception while sending OTP:');
      print('Error: $e');
      print('Stack trace: $stackTrace');
      if (e is http.ClientException) {
        print('🔍 Network error details: ${e.message}');
      } else if (e is FormatException) {
        print('🔍 JSON parsing error: ${e.message}');
      }
      throw Exception('Failed to send OTP: $e');
    }
  }

  Future<Map<String, dynamic>> verifyOtp(
      String phoneNumber, String name, String otp) async {
    try {
      print('🔐 Attempting to verify OTP');
      print('📱 Phone number: $phoneNumber');
      print('🔑 OTP: $otp');
      print('🌐 Making request to: $baseUrl/user/login/verify');

      final body = json.encode({
        'number': int.parse(phoneNumber),
        // 'name': name,
        'otp': otp,
      });
      print('📦 Request body: $body');

      final response = await http.post(
        Uri.parse('$baseUrl/user/login/verify'),
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      print('📥 Response status code: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      if (response.statusCode != 200) {
        final errorMsg =
            json.decode(response.body)['msg'] ?? 'Failed to verify OTP';
        throw AuthException(errorMsg, code: response.statusCode.toString());
      }else{
          final data = json.decode(response.body);
      print('✅ OTP verified successfully');

      // Create session with 4-day expiry
      final session = UserSession(
        token: data['token'],
        expiryDate: DateTime.now().add(const Duration(days: 4)),
        userId: data['user']['_id'],
      );

      await saveSession(session);
      await _saveToken(data['token']);
      print('💾 Token and session saved to storage');
      return data;
      }

    } catch (e, stackTrace) {
      print('❌ Exception while verifying OTP:');
      print('Error: $e');
      print('Stack trace: $stackTrace');
      if (e is http.ClientException) {
        print('🔍 Network error details: ${e.message}');
      } else if (e is FormatException) {
        print('🔍 JSON parsing error: ${e.message}');
      }
      throw Exception('Failed to verify OTP: $e');
    }
  }

  Future<void> _saveToken(String token) async {
    try {
      print('💾 Attempting to save token');
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(tokenKey, token);
      print('✅ Token saved successfully');
    } catch (e, stackTrace) {
      print('❌ Error saving token:');
      print('Error: $e');
      print('Stack trace: $stackTrace');
      throw Exception('Failed to save token: $e');
    }
  }

  Future<String?> getToken() async {
    try {
      print('🔍 Retrieving token from storage');
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(tokenKey);
      print(token != null ? '✅ Token found: ${token}' : '⚠️ No token found');
      return token;
    } catch (e, stackTrace) {
      print('❌ Error retrieving token:');
      print('Error: $e');
      print('Stack trace: $stackTrace');
      throw Exception('Failed to get token: $e');
    }
  }

  Future<void> logout() async {
    try {
      print('🔐 Attempting to logout');
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(tokenKey);
      print('✅ Logout successful - token removed');
    } catch (e, stackTrace) {
      print('❌ Error during logout:');
      print('Error: $e');
      print('Stack trace: $stackTrace');
      throw Exception('Failed to logout: $e');
    }
  }

  Future<Map<String, dynamic>> getUserProfile() async {
    try {
      final token = await getToken();
      if (token == null) {
        throw Exception('No token found');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/user/profile'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to load user profile');
      }

      final data = json.decode(response.body);
      print(data);
      return data; // Return the user profile data
    } catch (e) {
      throw Exception('Failed to fetch user profile: $e');
    }
  }

  Future<void> saveSession(UserSession session) async {
    final prefs = await SharedPreferences.getInstance();
    final sessionJson = json.encode(session.toJson());
    await prefs.setString(sessionKey, sessionJson);
  }

  Future<UserSession?> getSession() async {
    final prefs = await SharedPreferences.getInstance();
    final sessionJson = prefs.getString(sessionKey);

    if (sessionJson == null) return null;

    final sessionMap = json.decode(sessionJson);
    final session = UserSession.fromJson(sessionMap);

    // Check if session is expired
    if (DateTime.now().isAfter(session.expiryDate)) {
      await clearSession();
      return null;
    }

    return session;
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(sessionKey);
  }
}
