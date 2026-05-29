// lib/core/services/result_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/app_constants.dart';
import 'auth_service.dart';

class ResultService {
  static Future<bool> saveResult({
    required String category,
    required int    setNumber,
    required String mode,
    required int    totalQuestions,
    required int    correct,
    required int    wrong,
    required int    skipped,
    required double accuracy,
    required double avgSpeedSeconds,
    required int    xpEarned,
  }) async {
    try {
      final token = await AuthService.getToken();
      final res   = await http.post(
        Uri.parse('${AppConstants.baseUrl}/user/save-result'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type' : 'application/json',
        },
        body: jsonEncode({
          'category'          : category,
          'set_number'        : setNumber,
          'mode'              : mode,
          'total_questions'   : totalQuestions,
          'correct'           : correct,
          'wrong'             : wrong,
          'skipped'           : skipped,
          'accuracy'          : accuracy,
          'avg_speed_seconds' : avgSpeedSeconds,
          'xp_earned'         : xpEarned,
        }),
      ).timeout(const Duration(seconds: 10));

      return jsonDecode(res.body)['status'] == true;
    } catch (_) {
      return false;
    }
  }
}
