// lib/core/services/history_service.dart
//
// Admin doesn't expose a paginated history endpoint right now — recent test
// results live inside `user_profile.php` under `data.recent_tests`.
// We return them in the shape the history screen already expects:
// { status, success, data:[...], total, stats }

import 'user_service.dart';

class HistoryService {
  /// Pulls all "recent_tests" from the user profile and applies basic
  /// client-side filter / search / pagination.
  static Future<Map<String, dynamic>> getHistory({
    required int page,
    required int limit,
    String? category,
    String? search,
  }) async {
    final res = await UserService.getProfile();
    final isOk = res['success'] == true || res['status'] == true;
    if (!isOk) {
      return {
        'success': false,
        'status': false,
        'message': res['message'] ?? 'Could not load history',
      };
    }

    final data = res['data'];
    final List<dynamic> rawList = (data is Map && data['recent_tests'] is List)
        ? List<dynamic>.from(data['recent_tests'] as List)
        : <dynamic>[];

    // Map → uniform shape expected by history_screen
    var items = rawList
        .whereType<Map>()
        .map<Map<String, dynamic>>((e) {
          final m = Map<String, dynamic>.from(e);
          final accuracy = (m['accuracy'] as num?)?.toDouble() ?? 0.0;
          final timeTaken = (m['time_taken'] as num?)?.toInt() ?? 0;
          final total = (m['total_questions'] as num?)?.toInt() ?? 0;
          final correct = (m['score'] as num?)?.toInt() ??
              (m['correct'] as num?)?.toInt() ??
              0;
          return {
            'category': '${m['category'] ?? ''}',
            'set_number': m['set_number'] ?? 0,
            'exam_name': m['exam_name'] ?? m['category'] ?? 'Quiz',
            'correct': correct,
            'total_questions': total,
            'accuracy': accuracy,
            'avg_speed_seconds':
                total > 0 ? (timeTaken / total).toDouble() : 0.0,
            'xp_earned': m['xp_earned'] ?? 0,
            'created_at_label': '${m['completed_at'] ?? ''}',
            'date': '${m['completed_at'] ?? ''}',
          };
        })
        .toList();

    // Filter by category
    if (category != null && category.isNotEmpty && category.toUpperCase() != 'ALL') {
      final cat = category.toLowerCase();
      items = items
          .where((e) => '${e['category']}'.toLowerCase() == cat ||
              '${e['exam_name']}'.toLowerCase().contains(cat))
          .toList();
    }

    // Search
    if (search != null && search.trim().isNotEmpty) {
      final q = search.toLowerCase();
      items = items.where((e) {
        return '${e['exam_name']}'.toLowerCase().contains(q) ||
            '${e['category']}'.toLowerCase().contains(q);
      }).toList();
    }

    final total = items.length;
    final start = ((page - 1) * limit).clamp(0, total);
    final end = (start + limit).clamp(0, total);
    final pageItems = items.sublist(start, end);

    // Stats from user_profile.stats
    final stats = (data is Map && data['stats'] is Map)
        ? Map<String, dynamic>.from(data['stats'] as Map)
        : <String, dynamic>{};

    return {
      'success': true,
      'status': true,
      'data': pageItems,
      'total': total,
      'page': page,
      'limit': limit,
      'stats': {
        'total_tests': stats['total_tests'] ?? total,
        'avg_score': ((stats['avg_accuracy'] as num?)?.toDouble() ?? 0) / 10.0,
        'best_score': stats['best_score'] ?? 0,
        'avg_speed': 0.0,
      },
    };
  }
}
