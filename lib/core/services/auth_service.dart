// lib/core/services/auth_service.dart

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../network/api_client.dart';
import '../network/api_endpoints.dart';
import '../constants/app_constants.dart';

class AuthService {

  // ── Send OTP ──────────────────────────────────────
  static Future<Map<String, dynamic>> sendOtp(String phone) async {
    try {
      final res = await ApiClient.post(ApiEndpoints.login, {
        'step': 'send',
        'phone': phone,
      });
      debugPrint('[AuthService] sendOtp response: $res');
      return res;
    } catch (e) {
      debugPrint('[AuthService] sendOtp error: $e');
      return {'success': false, 'message': 'Network error. Please try again.'};
    }
  }

  // ── Verify OTP + cache user ───────────────────────
  static Future<Map<String, dynamic>> verifyOtp(
      String phone, String otp) async {
    try {
      final res = await ApiClient.post(ApiEndpoints.login, {
        'step': 'verify',
        'phone': phone,
        'otp': otp,
      });
      debugPrint('[AuthService] verifyOtp response: $res');

      // ✅ PHP 'success' return karta hai, 'status' nahi
      final bool isSuccess = res['success'] == true;

      if (isSuccess) {
        // ✅ PHP ok() ka structure: { success, message, data: { token, user } }
        final data  = res['data']  as Map<String, dynamic>? ?? {};
        final token = data['token'] as String? ?? '';
        final user  = data['user']  as Map<String, dynamic>? ?? {};

        debugPrint('[AuthService] Token: $token');
        debugPrint('[AuthService] User: $user');

        if (token.isNotEmpty) {
          final prefs = await SharedPreferences.getInstance();
          await Future.wait([
            prefs.setString(AppConstants.prefAuthToken, token),
            prefs.setBool(AppConstants.prefIsLoggedIn, true),
            prefs.setString(AppConstants.prefUserPhone,
                user['phone'] as String? ?? phone),
            prefs.setString(AppConstants.prefUserName,
                user['name'] as String? ?? ''),
            prefs.setBool(AppConstants.prefIsPremium,
                user['is_premium'] == true || user['is_premium'] == 1),
          ]);
          debugPrint('[AuthService] ✅ Token & user cached successfully');
        } else {
          debugPrint('[AuthService] ⚠️ Token empty — check PHP login.php response');
        }
      }

      return res;
    } catch (e) {
      debugPrint('[AuthService] verifyOtp error: $e');
      return {'success': false, 'message': 'Network error. Please try again.'};
    }
  }

  // ── Logout ────────────────────────────────────────
  static Future<void> logout() async {
    try {
      await ApiClient.post(ApiEndpoints.logout, {}, auth: true);
    } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  // ── Getters ───────────────────────────────────────
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AppConstants.prefAuthToken) ?? '';
    return token.isNotEmpty &&
        (prefs.getBool(AppConstants.prefIsLoggedIn) ?? false);
  }

  static Future<bool> isPremium() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(AppConstants.prefIsPremium) ?? false;
  }

  static Future<String> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.prefAuthToken) ?? '';
  }

  static Future<String> getCachedName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.prefUserName) ?? '';
  }

  static Future<String> getCachedPhone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.prefUserPhone) ?? '';
  }

  static Future<void> setPremium(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.prefIsPremium, value);
  }

  static Future<void> setCachedName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.prefUserName, name);
  }

  static Future<bool> isProfileComplete() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString(AppConstants.prefUserName) ?? '';
    return name.trim().isNotEmpty;
  }

  static Future<void> setCachedStandard(String standard) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_standard', standard);
  }

  static Future<String> getCachedStandard() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_standard') ?? '';
  }
}