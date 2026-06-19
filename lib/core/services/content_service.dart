// lib/core/services/content_service.dart
//
// Wrapper around the admin panel content endpoints.
// Admin (PHP) returns either:
//   - {success: true, data: [...]}              ── login.php / banners.php / app_settings.php / user_profile.php
//   - {success: true, <named_key>: [...] }      ── sets.php / questions.php / shorts.php / tricks.php / daily_dose.php / etc.
//
// Helpers below tolerate both shapes.

import 'package:flutter/foundation.dart';
import '../network/api_client.dart';
import '../network/api_endpoints.dart';
import '../models/banner_model.dart';
import '../models/set_model.dart';
import '../models/question_model.dart';
import '../models/trick_model.dart';
import '../models/short_model.dart';
import '../models/daily_dose_model.dart';

class ContentService {
  // ── Helpers ───────────────────────────────────────
  static bool _ok(Map<String, dynamic> res) =>
      res['success'] == true || res['status'] == true;

  static List<dynamic> _list(Map<String, dynamic> res, List<String> keys) {
    for (final k in keys) {
      final v = res[k];
      if (v is List) return v;
    }
    final data = res['data'];
    if (data is List) return data;
    return const [];
  }

  static Map<String, dynamic> _map(Map<String, dynamic> res, List<String> keys) {
    for (final k in keys) {
      final v = res[k];
      if (v is Map<String, dynamic>) return v;
      if (v is Map) return Map<String, dynamic>.from(v);
    }
    final data = res['data'];
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return const {};
  }

  // ── App settings ──────────────────────────────────
  static Future<Map<String, dynamic>> getAppSettings() async {
    try {
      final res = await ApiClient.get(ApiEndpoints.appSettings);
      if (!_ok(res)) return {};
      return _map(res, const ['settings']);
    } catch (_) {
      return {};
    }
  }

  // ── Banners ───────────────────────────────────────
  static Future<List<BannerModel>> getBanners() async {
    try {
      final res = await ApiClient.get(ApiEndpoints.banners);
      if (!_ok(res)) return [];
      final raw = _list(res, const ['banners']);
      return raw
          .whereType<Map>()
          .map((e) => BannerModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e, st) {
      debugPrint('[Banners] ERROR: $e\n$st');
      return [];
    }
  }

  // ── Sets by category ──────────────────────────────
  static Future<List<SetModel>> getSets(
    String category, {
    int? examId,
    String? examName,
    bool ungrouped = false,
    int page = 1,
    int perPage = 50,
  }) async {
    try {
      final params = <String, String>{
        'category': category,
        'page': '$page',
        'per_page': '$perPage',
      };
      if (examId != null) params['exam_id'] = '$examId';
      if (examName != null && examName.isNotEmpty) params['exam_name'] = examName;
      if (ungrouped) params['ungrouped'] = '1';

      final res = await ApiClient.get(
        ApiEndpoints.sets,
        params: params,
      );
      if (!_ok(res)) return [];
      final raw = _list(res, const ['sets']);
      return raw
          .whereType<Map>()
          .map((e) => SetModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e) {
      debugPrint('[Sets] ERROR: $e');
      return [];
    }
  }

  // ── Questions by set_id ───────────────────────────
  static Future<List<QuestionModel>> getQuestions(
    int setId, {
    bool shuffle = false,
  }) async {
    try {
      final params = <String, String>{'set_id': '$setId'};
      if (shuffle) params['shuffle'] = '1';

      final res = await ApiClient.get(
        ApiEndpoints.questions,
        params: params,
        auth: true,
      );
      if (!_ok(res)) return [];
      final raw = _list(res, const ['questions']);
      return raw
          .whereType<Map>()
          .map((e) => QuestionModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e) {
      debugPrint('[Questions] ERROR: $e');
      return [];
    }
  }

  // Raw questions response (so the question screen can also pull set info)
  static Future<Map<String, dynamic>> getQuestionsRaw(int setId,
      {bool shuffle = false}) async {
    try {
      final params = <String, String>{'set_id': '$setId'};
      if (shuffle) params['shuffle'] = '1';

      return await ApiClient.get(
        ApiEndpoints.questions,
        params: params,
        auth: true,
      );
    } catch (e) {
      return {'success': false, 'message': '$e'};
    }
  }

  // ── Tricks ────────────────────────────────────────
  static Future<List<TrickModel>> getTricks({String? category}) async {
    try {
      final params = <String, String>{};
      if (category != null && category.isNotEmpty && category != 'ALL') {
        params['category'] = category;
      }
      final res = await ApiClient.get(
        ApiEndpoints.tricks,
        params: params.isEmpty ? null : params,
      );
      if (!_ok(res)) return [];
      final raw = _list(res, const ['tricks']);
      return raw
          .whereType<Map>()
          .map((e) => TrickModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e) {
      debugPrint('[Tricks] ERROR: $e');
      return [];
    }
  }

  static Future<TrickModel?> getTrickById(int id) async {
    try {
      final res = await ApiClient.get(
        ApiEndpoints.tricks,
        params: {'id': '$id'},
      );
      if (!_ok(res)) return null;
      final m = _map(res, const ['trick']);
      if (m.isEmpty) return null;
      return TrickModel.fromJson(m);
    } catch (_) {
      return null;
    }
  }

  // ── Shorts ────────────────────────────────────────
  static Future<List<ShortModel>> getShorts({
    String? category,
    int page = 1,
    int perPage = 30,
  }) async {
    try {
      final params = <String, String>{
        'page': '$page',
        'per_page': '$perPage',
      };
      if (category != null && category.isNotEmpty && category != 'ALL') {
        params['category'] = category.toLowerCase();
      }
      final res = await ApiClient.get(
        ApiEndpoints.shorts,
        params: params,
      );
      if (!_ok(res)) return [];
      final raw = _list(res, const ['shorts']);
      return raw
          .whereType<Map>()
          .map((e) => ShortModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e) {
      debugPrint('[Shorts] ERROR: $e');
      return [];
    }
  }

  // ── Today's Daily Dose ────────────────────────────
  static Future<DailyDoseModel?> getDailyDose() async {
    try {
      final res = await ApiClient.get(ApiEndpoints.dailyDose);
      if (!_ok(res)) return null;
      final m = _map(res, const ['dose']);
      if (m.isEmpty) return null;
      return DailyDoseModel.fromJson(m);
    } catch (_) {
      return null;
    }
  }

  // ── Daily Practice (auth) ─────────────────────────
  static Future<Map<String, dynamic>> getDailyPractice() async {
    try {
      return await ApiClient.get(ApiEndpoints.dailyPractice, auth: true);
    } catch (e) {
      return {'success': false, 'message': '$e'};
    }
  }

  static Future<Map<String, dynamic>> submitDailyPractice({
    required int practiceId,
    required int correct,
    required int wrong,
    required int timeTaken,
  }) async {
    try {
      return await ApiClient.post(
        ApiEndpoints.submitDaily,
        {
          'practice_id': practiceId,
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

  // ── Submit test result ────────────────────────────
  static Future<Map<String, dynamic>> submitResult({
    required String category,
    required int setId,
    required int correct,
    required int wrong,
    required int skipped,
    required int timeTaken,
    List<Map<String, dynamic>>? answers,
  }) async {
    try {
      return await ApiClient.post(
        ApiEndpoints.submitResult,
        {
          'category': category,
          'set_id': setId,
          'correct': correct,
          'wrong': wrong,
          'skipped': skipped,
          'time_taken': timeTaken,
          if (answers != null) 'answers': answers,
        },
        auth: true,
      );
    } catch (e) {
      return {'success': false, 'message': 'Failed to submit result.'};
    }
  }

  // ── Previous Year exams (grouped by name) ─────────
  static Future<Map<String, List<Map<String, dynamic>>>>
      getPreviousYearExams() async {
    try {
      final res = await ApiClient.get(ApiEndpoints.previousYear);
      if (!_ok(res)) return {};
      final raw = res['exams'];
      if (raw is! Map) return {};
      final out = <String, List<Map<String, dynamic>>>{};
      raw.forEach((key, value) {
        if (value is List) {
          out['$key'] = value
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        }
      });
      return out;
    } catch (e) {
      debugPrint('[PreviousYear] ERROR: $e');
      return {};
    }
  }

  // ── PYQ sets for a single exam ────────────────────
  static Future<Map<String, dynamic>> getPreviousYearExam(int examId) async {
    try {
      return await ApiClient.get(
        ApiEndpoints.previousYear,
        params: {'exam_id': '$examId'},
      );
    } catch (e) {
      return {'success': false, 'message': '$e'};
    }
  }

  // ── Coupon validation ─────────────────────────────
  /// Returns { valid, code, discount, final_price, base_price, message }.
  static Future<Map<String, dynamic>> validateCoupon(
    String code, {
    String plan = 'lifetime',
  }) async {
    try {
      final res = await ApiClient.post(
        ApiEndpoints.coupons,
        {'code': code, 'plan': plan},
        auth: true,
      );
      if (!_ok(res)) {
        return {'valid': false, 'message': res['message'] ?? 'Could not validate coupon.'};
      }
      return {
        'valid': res['valid'] == true,
        'code': res['code'] ?? code.toUpperCase(),
        'discount': (res['discount'] as num?)?.toInt() ?? 0,
        'final_price': (res['final_price'] as num?)?.toInt() ??
            (res['base_price'] as num?)?.toInt() ?? 0,
        'base_price': (res['base_price'] as num?)?.toInt() ?? 0,
        'message': res['message'] ?? '',
      };
    } catch (e) {
      debugPrint('[validateCoupon] $e');
      return {'valid': false, 'message': 'Network error. Try again.'};
    }
  }

  // ── 5000 MCQ exams (grouped by category, exam-wise) ──
  /// Returns a flat list of exam maps: { exam_name, exam_category, icon,
  /// difficulty, is_premium, can_access, set_count, total_questions }.
  static Future<List<Map<String, dynamic>>> getMcqExams() async {
    try {
      final res = await ApiClient.get(ApiEndpoints.mcqExams, auth: true);
      if (!_ok(res)) return [];
      final raw = _list(res, const ['exams']);
      return raw
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } catch (e) {
      debugPrint('[McqExams] ERROR: $e');
      return [];
    }
  }

  // ── Submit a technical error report ───────────────
  /// Returns true on success. Sends the message to the admin.
  static Future<bool> submitTechReport(String message) async {
    try {
      final res = await ApiClient.post(
        ApiEndpoints.reportError,
        {'message': message},
        auth: true,
      );
      return _ok(res);
    } catch (e) {
      debugPrint('[submitTechReport] ERROR: $e');
      return false;
    }
  }

  // ── Tunnlity leaderboard ──────────────────────────
  /// Returns { leaderboard: [...], my_rank, my_best }.
  static Future<Map<String, dynamic>> getTunnlityLeaderboard() async {
    try {
      final res = await ApiClient.get(
        ApiEndpoints.tunnlityLeaderboard,
        auth: true,
      );
      if (!_ok(res)) {
        return {'leaderboard': const [], 'my_rank': null, 'my_best': null};
      }
      final raw = res['leaderboard'];
      final list = (raw is List)
          ? raw
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList()
          : <Map<String, dynamic>>[];
      return {
        'leaderboard': list,
        'my_rank': res['my_rank'],
        'my_best': res['my_best'],
      };
    } catch (e) {
      debugPrint('[TunnlityLeaderboard] ERROR: $e');
      return {'leaderboard': const [], 'my_rank': null, 'my_best': null};
    }
  }
}
