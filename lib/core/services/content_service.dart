// lib/core/services/content_service.dart

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

  // ── Banners ───────────────────────────────────────
  static Future<List<BannerModel>> getBanners() async {
    try {
      final res = await ApiClient.get(ApiEndpoints.banners);
      debugPrint('[Banners] success=${res['success']} count=${(res['data'] as List?)?.length}');

      if (res['success'] != true) return [];

      final raw = res['data'];
      if (raw == null || raw is! List) return [];

      return raw
          .map((e) => BannerModel.fromJson(e as Map<String, dynamic>))
          .toList();

    } catch (e, st) {
      debugPrint('[Banners] ERROR: $e\n$st');
      return [];
    }
  }

  // ── Sets by category ──────────────────────────────
  static Future<List<SetModel>> getSets(String category) async {
    try {
      final res = await ApiClient.get(
        ApiEndpoints.sets,
        params: {'category': category},
      );
      if (res['success'] != true) return [];
      return (res['data'] as List)
          .map((e) => SetModel.fromJson(e))
          .toList();
    } catch (_) {
      return [];
    }
  }

  // ── Questions by set_id ───────────────────────────
  static Future<List<QuestionModel>> getQuestions(int setId) async {
    try {
      final res = await ApiClient.get(
        ApiEndpoints.questions,
        params: {'set_id': setId.toString()},
        auth: true,
      );
      if (res['success'] != true) return [];
      return (res['data'] as List)
          .map((e) => QuestionModel.fromJson(e))
          .toList();
    } catch (_) {
      return [];
    }
  }

  // ── Tricks ────────────────────────────────────────
  static Future<List<TrickModel>> getTricks() async {
    try {
      final res = await ApiClient.get(ApiEndpoints.tricks);
      if (res['success'] != true) return [];
      return (res['data'] as List)
          .map((e) => TrickModel.fromJson(e))
          .toList();
    } catch (_) {
      return [];
    }
  }

  // ── Tricks by category ────────────────────────────
  static Future<List<TrickModel>> getTricksByCategory(String category) async {
    try {
      final res = await ApiClient.get(
        ApiEndpoints.tricks,
        params: {'category': category},
      );
      if (res['success'] != true) return [];
      return (res['data'] as List)
          .map((e) => TrickModel.fromJson(e))
          .toList();
    } catch (_) {
      return [];
    }
  }

  // ── Shorts ────────────────────────────────────────
  static Future<List<ShortModel>> getShorts() async {
    try {
      final res = await ApiClient.get(ApiEndpoints.shorts);
      if (res['success'] != true) return [];
      return (res['data'] as List)
          .map((e) => ShortModel.fromJson(e))
          .toList();
    } catch (_) {
      return [];
    }
  }

  // ── Today's Daily Dose ────────────────────────────
  static Future<DailyDoseModel?> getDailyDose() async {
    try {
      final res = await ApiClient.get(ApiEndpoints.dailyDose);
      if (res['success'] != true || res['data'] == null) return null;
      return DailyDoseModel.fromJson(res['data']);
    } catch (_) {
      return null;
    }
  }

  // ── Submit test result ────────────────────────────
  static Future<Map<String, dynamic>> submitResult({
    required String category,
    required int    setId,
    required int    score,
    required int    total,
    required int    correct,
    required int    wrong,
    required int    skipped,
    required int    timeTaken,
  }) async {
    try {
      return await ApiClient.post(
        ApiEndpoints.submitResult,
        {
          'category':        category,
          'set_id':          setId,
          'score':           score,
          'total_questions': total,
          'correct':         correct,
          'wrong':           wrong,
          'skipped':         skipped,
          'time_taken':      timeTaken,
        },
        auth: true,
      );
    } catch (e) {
      return {'success': false, 'message': 'Failed to submit result.'};
    }
  }

  // ── PYQ by exam type ──────────────────────────────
  static Future<List<SetModel>> getPreviousYearSets(String examType) async {
    try {
      final res = await ApiClient.get(
        ApiEndpoints.sets,
        params: {
          'category':  'previous_year',
          'exam_type': examType,
        },
      );
      if (res['success'] != true) return [];
      return (res['data'] as List)
          .map((e) => SetModel.fromJson(e))
          .toList();
    } catch (_) {
      return [];
    }
  }
}