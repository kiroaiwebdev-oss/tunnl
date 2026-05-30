// lib/core/services/user_service.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';
import '../network/api_client.dart';
import '../network/api_endpoints.dart';
import '../services/auth_service.dart';

class UserService {
  static bool _ok(Map<String, dynamic> res) =>
      res['success'] == true || res['status'] == true;

  // ── Get profile ───────────────────────────────────
  /// Returns the raw response { success, data: { user, stats, recent_tests } }
  static Future<Map<String, dynamic>> getProfile() async {
    try {
      return await ApiClient.get(ApiEndpoints.userProfile, auth: true);
    } catch (e) {
      debugPrint('[UserService.getProfile] $e');
      return {'success': false, 'message': 'Failed to load profile.'};
    }
  }

  // ── Update profile fields ─────────────────────────
  static Future<bool> updateName(String name) async {
    try {
      final res = await ApiClient.post(
        ApiEndpoints.userProfile,
        {'name': name},
        auth: true,
      );
      if (_ok(res)) {
        await AuthService.setCachedName(name);
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> updateStandard(String standard) async {
    try {
      final res = await ApiClient.post(
        ApiEndpoints.userProfile,
        {'standard': standard},
        auth: true,
      );
      if (_ok(res)) {
        await AuthService.setCachedStandard(standard);
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> updateProfile({
    String? name,
    String? standard,
    String? fcmToken,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (name != null && name.isNotEmpty) body['name'] = name;
      if (standard != null && standard.isNotEmpty) body['standard'] = standard;
      if (fcmToken != null && fcmToken.isNotEmpty) body['fcm_token'] = fcmToken;
      if (body.isEmpty) return false;

      final res = await ApiClient.post(
        ApiEndpoints.userProfile,
        body,
        auth: true,
      );
      if (_ok(res)) {
        if (name != null && name.isNotEmpty) {
          await AuthService.setCachedName(name);
        }
        if (standard != null && standard.isNotEmpty) {
          await AuthService.setCachedStandard(standard);
        }
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> updateFcmToken(String token) async {
    try {
      await ApiClient.post(
        ApiEndpoints.userProfile,
        {'fcm_token': token},
        auth: true,
      );
    } catch (_) {}
  }

  /// Upload a local image file as the profile picture. Uses multipart/form-data
  /// so it goes straight to admin/api/user_profile.php which moves the file
  /// into admin/uploads/profiles/ and stores the public URL.
  ///
  /// Returns the new public URL on success, null on failure.
  static Future<String?> uploadProfileImage(String filePath) async {
    try {
      final base = AppConstants.baseUrl.endsWith('/')
          ? AppConstants.baseUrl.substring(0, AppConstants.baseUrl.length - 1)
          : AppConstants.baseUrl;
      final uri = Uri.parse('$base/${ApiEndpoints.userProfile}');

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(AppConstants.prefAuthToken) ?? '';

      final req = http.MultipartRequest('POST', uri)
        ..headers['Authorization'] = 'Bearer $token'
        ..headers['Accept'] = 'application/json'
        ..files.add(await http.MultipartFile.fromPath('profile_image', filePath));

      final streamed = await req.send().timeout(const Duration(seconds: 30));
      final body = await streamed.stream.bytesToString();
      if (streamed.statusCode >= 400) {
        debugPrint('[uploadProfileImage] HTTP ${streamed.statusCode} → $body');
        return null;
      }

      final json = jsonDecode(body);
      if (json is Map &&
          (json['success'] == true || json['status'] == true)) {
        final url = (json['data']?['profile_image'] ?? '').toString();
        return url.isEmpty ? null : url;
      }
      debugPrint('[uploadProfileImage] failed → $body');
      return null;
    } catch (e) {
      debugPrint('[uploadProfileImage] error: $e');
      return null;
    }
  }

  // ── Leaderboard ───────────────────────────────────
  /// type: 'all_time' (default) | 'weekly' | 'monthly'
  /// Returns { entries: [...], myRank, myXp, type }
  static Future<Map<String, dynamic>> getLeaderboard({
    String type = 'all_time',
    int limit = 50,
  }) async {
    try {
      final res = await ApiClient.get(
        ApiEndpoints.leaderboard,
        params: {'type': type, 'limit': '$limit'},
        auth: true,
      );
      if (!_ok(res)) {
        return {'entries': const [], 'my_rank': null, 'my_xp': null};
      }
      final list = res['leaderboard'];
      final entries = (list is List)
          ? list
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList()
          : <Map<String, dynamic>>[];
      return {
        'entries': entries,
        'my_rank': res['my_rank'],
        'my_xp': res['my_xp'],
        'type': res['type'] ?? type,
      };
    } catch (e) {
      debugPrint('[Leaderboard] $e');
      return {'entries': const [], 'my_rank': null, 'my_xp': null};
    }
  }

  // ── Recent test history (from user_profile.recent_tests) ──
  static Future<List<Map<String, dynamic>>> getRecentTests() async {
    try {
      final res = await getProfile();
      if (!_ok(res)) return [];
      final data = res['data'];
      if (data is! Map) return [];
      final list = data['recent_tests'];
      if (list is! List) return [];
      return list
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } catch (_) {
      return [];
    }
  }

  // ── Weekly Challenge ──────────────────────────────
  static Future<Map<String, dynamic>> getWeeklyChallenge() async {
    try {
      return await ApiClient.get(ApiEndpoints.weeklyChallenge, auth: true);
    } catch (e) {
      return {'success': false, 'message': '$e'};
    }
  }

  static Future<Map<String, dynamic>> submitWeeklyChallenge({
    required int challengeId,
    required int correct,
    required int wrong,
    required int timeTaken,
  }) async {
    try {
      return await ApiClient.post(
        ApiEndpoints.weeklyChallenge,
        {
          'challenge_id': challengeId,
          'correct': correct,
          'wrong': wrong,
          'time_taken': timeTaken,
        },
        auth: true,
      );
    } catch (e) {
      return {'success': false, 'message': '$e'};
    }
  }

  // ── Verify Razorpay payment ───────────────────────
  static Future<Map<String, dynamic>> verifyPayment({
    required String orderId,
    required String paymentId,
    required String signature,
    String plan = 'monthly',
  }) async {
    try {
      return await ApiClient.post(
        ApiEndpoints.verifyPayment,
        {
          'razorpay_order_id': orderId,
          'razorpay_payment_id': paymentId,
          'razorpay_signature': signature,
          'plan': plan,
        },
        auth: true,
      );
    } catch (e) {
      return {'success': false, 'message': '$e'};
    }
  }
}
