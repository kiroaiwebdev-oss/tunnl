// lib/core/services/question_service.dart
//
// Thin wrapper around `questions.php`. The set picker (sets_screen, test_list_screen,
// previous_year) gives us a real `set_id` from the admin DB. We just pass it through.

import '../network/api_client.dart';
import '../network/api_endpoints.dart';

class QuestionService {
  /// GET /questions.php?set_id=...
  /// Response: { success, set, questions: [{id, question, options:{a,b,c,d}, correct, explanation, difficulty, time_limit}] }
  static Future<Map<String, dynamic>> getQuestions({
    required int setId,
    bool shuffle = false,
  }) async {
    final params = <String, String>{'set_id': '$setId'};
    if (shuffle) params['shuffle'] = '1';

    return await ApiClient.get(
      ApiEndpoints.questions,
      params: params,
      auth: true,
    );
  }
}
