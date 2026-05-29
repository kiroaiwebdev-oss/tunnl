// lib/core/services/user_service.dart

import '../network/api_client.dart';
import '../network/api_endpoints.dart';
import '../services/auth_service.dart';

class UserService {

  // ── Get profile ───────────────────────────────────
  static Future<Map<String, dynamic>> getProfile() async {
    try {
      return await ApiClient.get(ApiEndpoints.userProfile, auth: true);
    } catch (e) {
      return {'status': false, 'message': 'Failed to load profile.'};
    }
  }

  // ── Update name ───────────────────────────────────
  static Future<bool> updateName(String name) async {
    try {
      final res = await ApiClient.post(
        ApiEndpoints.userProfile,
        {'name': name},
        auth: true,
      );
      if (res['status'] == true) {
        await AuthService.setCachedName(name);
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  // ── Update FCM token ──────────────────────────────
  static Future<void> updateFcmToken(String token) async {
    try {
      await ApiClient.post(
        ApiEndpoints.userProfile,
        {'fcm_token': token},
        auth: true,
      );
    } catch (_) {}
  }

  // ── Leaderboard ───────────────────────────────────
  static Future<List<Map<String, dynamic>>> getLeaderboard() async {
    try {
      final res = await ApiClient.get(ApiEndpoints.leaderboard);
      if (res['status'] != true) return [];
      return List<Map<String, dynamic>>.from(res['data'] ?? []);
    } catch (_) {
      return [];
    }
  }

  // ── Solve & Earn leaderboard ──────────────────────
  static Future<List<Map<String, dynamic>>> getSolveEarnLeaderboard() async {
    try {
      final res = await ApiClient.get(
        ApiEndpoints.leaderboard,
        params: {'type': 'solve_earn'},
      );
      if (res['status'] != true) return [];
      return List<Map<String, dynamic>>.from(res['data'] ?? []);
    } catch (_) {
      return [];
    }
  }

  // ── History ───────────────────────────────────────
  static Future<List<Map<String, dynamic>>> getHistory() async {
    try {
      final res = await ApiClient.get(
        ApiEndpoints.history,
        auth: true,
      );
      if (res['status'] != true) return [];
      return List<Map<String, dynamic>>.from(res['data'] ?? []);
    } catch (_) {
      return [];
    }
  }

  // ── XP summary ────────────────────────────────────
  static Future<Map<String, dynamic>> getXpSummary() async {
    try {
      final res = await ApiClient.get(
        ApiEndpoints.userXp,
        auth: true,
      );
      if (res['status'] != true) return {};
      return Map<String, dynamic>.from(res['data'] ?? {});
    } catch (_) {
      return {};
    }
  }

  // ── Get set progress ──────────────────────────────  ← ADD KIYA
  static Future<Map<String, dynamic>> getSetProgress(String category) async {
    try {
      return await ApiClient.get(
        ApiEndpoints.userProfile,
        params: {
          'action'  : 'get_set_progress',
          'category': category,
        },
        auth: true,
      );
    } catch (_) {
      return {'status': false, 'data': []};
    }
  }

  // ── Update set progress ───────────────────────────  ← FIX KIYA (andar hai ab)
  static Future<bool> updateSetProgress({
    required String category,
    required int    setNumber,
    required double progress,
    required bool   isCompleted,
  }) async {
    try {
      final res = await ApiClient.post(
        ApiEndpoints.userProfile,
        {
          'action'      : 'update_set_progress',
          'category'    : category,
          'set_number'  : setNumber,
          'progress'    : progress,
          'is_completed': isCompleted ? 1 : 0,
        },
        auth: true,
      );
      return res['status'] == true;
    } catch (_) {
      return false;
    }
  }

} 