import '../network/api_client.dart';
import '../network/api_endpoints.dart';

class QuestionService {
  static Future<Map<String, dynamic>> getQuestions({
    required String category,
    required int setNumber,
    required int totalQuestions,
    String mode = 'practice',
  }) async {
    return await ApiClient.get(
      ApiEndpoints.questions,
      params: {
        'category':        category,
        'set_number':      setNumber.toString(),
        'total_questions': totalQuestions.toString(),
        'mode':            mode,
      },
    );
  }
}
