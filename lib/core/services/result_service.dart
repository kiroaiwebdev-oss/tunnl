// lib/core/services/result_service.dart
//
// Posts the test result to admin's submit_result.php.

import '../network/api_client.dart';
import '../network/api_endpoints.dart';

class ResultService {
  static Future<bool> saveResult({
    required String category,
    required int setId,
    required int correct,
    required int wrong,
    required int skipped,
    required int timeTaken,
    List<Map<String, dynamic>>? answers,
  }) async {
    try {
      final res = await ApiClient.post(
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
      return res['success'] == true || res['status'] == true;
    } catch (_) {
      return false;
    }
  }

  /// Same as saveResult but returns the raw response so the caller can
  /// surface XP / badges info.
  static Future<Map<String, dynamic>> saveResultRaw({
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
      return {'success': false, 'message': '$e'};
    }
  }
}
