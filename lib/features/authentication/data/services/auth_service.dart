import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String baseUrl = 'http://192.168.8.105:3000';
  static const String tokenKey = 'kjbnaeildnflia';

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
        print('❌ API Error: $errorMsg');
        throw Exception(errorMsg);
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

  Future<Map<String, dynamic>> verifyOtp(String phoneNumber, String otp) async {
    try {
      print('🔐 Attempting to verify OTP');
      print('📱 Phone number: $phoneNumber');
      print('🔑 OTP: $otp');
      print('🌐 Making request to: $baseUrl/user/login/verify');

      final body = json.encode({
        'number': int.parse(phoneNumber),
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
        print('❌ API Error: $errorMsg');
        throw Exception(errorMsg);
      }

      final data = json.decode(response.body);
      print('✅ OTP verified successfully');
      print('🎫 Received token: ${data['token']?.substring(0, 10)}...');

      await _saveToken(data['token']);
      print('💾 Token saved to storage');

      return data;
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
      print(token != null
          ? '✅ Token found: ${token.substring(0, 10)}...'
          : '⚠️ No token found');
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
}
