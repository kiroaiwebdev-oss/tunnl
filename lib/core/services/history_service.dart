// lib/core/services/history_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/app_constants.dart';
import 'auth_service.dart';

class HistoryService {
  /// GET /user/history?page=1&limit=10&category=SSC&search=CGL
  static Future<Map<String, dynamic>> getHistory({
    required int    page,
    required int    limit,
    String?         category,
    String?         search,
  }) async {
    final token = await AuthService.getToken();

    final params = {
      'page' : '$page',
      'limit': '$limit',
      if (category != null) 'category': category,
      if (search   != null) 'search'  : search,
    };

    final uri = Uri.parse('${AppConstants.baseUrl}/user/history')
        .replace(queryParameters: params);

    final res = await http.get(uri, headers: {
      'Authorization': 'Bearer $token',
      'Content-Type' : 'application/json',
    }).timeout(const Duration(seconds: 15));

    return jsonDecode(res.body);
  }
}
