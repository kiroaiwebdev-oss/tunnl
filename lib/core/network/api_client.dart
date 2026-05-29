import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

class ApiClient {
  static const _timeout = Duration(seconds: 15);

  static Future<Map<String, String>> _headers({bool auth = false}) async {
    final h = <String, String>{
      'Content-Type': 'application/json',
      'Accept':       'application/json',
    };
    if (auth) {
      final p = await SharedPreferences.getInstance();
      final t = p.getString(AppConstants.prefAuthToken) ?? '';
      if (t.isNotEmpty) {
        h['Authorization'] = 'Bearer $t';
      }
      debugPrint('[ApiClient] Token: ${t.isEmpty ? "EMPTY ❌" : "${t.substring(0, t.length.clamp(0, 20))}... ✅"}');
    }
    return h;
  }

  // ✅ FIXED: 'success' return karta hai error case me bhi
  static Map<String, dynamic> _decode(http.Response res) {
    debugPrint('[ApiClient] ${res.request?.method} ${res.request?.url} → ${res.statusCode}');
    debugPrint('[ApiClient] Body: ${res.body}');
    try {
      final decoded = jsonDecode(res.body);
      if (decoded is Map<String, dynamic>) return decoded;
      return {'success': false, 'message': 'Unexpected response format'};
    } catch (_) {
      return {'success': false, 'message': 'Invalid JSON: ${res.body}'};
    }
  }

  static Map<String, dynamic> _error(dynamic e) {
    debugPrint('[ApiClient] Error: $e');
    if (e is SocketException || e is HttpException) {
      return {'success': false, 'message': 'No internet connection.'};
    }
    if (e is TimeoutException) {
      return {'success': false, 'message': 'Request timed out. Try again.'};
    }
    return {'success': false, 'message': 'Something went wrong: $e'};
  }

  // ── GET ───────────────────────────────────────────
  static Future<Map<String, dynamic>> get(
    String endpoint, {
    bool auth = false,
    Map<String, String>? params,
  }) async {
    try {
      // ✅ Clean URL building — no double slash
      final base = AppConstants.baseUrl.endsWith('/')
          ? AppConstants.baseUrl.substring(0, AppConstants.baseUrl.length - 1)
          : AppConstants.baseUrl;

      var uri = Uri.parse('$base/$endpoint');
      if (params != null && params.isNotEmpty) {
        uri = uri.replace(queryParameters: params);
      }

      final res = await http
          .get(uri, headers: await _headers(auth: auth))
          .timeout(_timeout);

      if (res.statusCode == 401) {
        return {'success': false, 'message': 'Session expired. Please login again.', 'code': 401};
      }

      return _decode(res);
    } catch (e) {
      return _error(e);
    }
  }

  // ── POST ──────────────────────────────────────────
  static Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> body, {
    bool auth = false,
  }) async {
    try {
      final base = AppConstants.baseUrl.endsWith('/')
          ? AppConstants.baseUrl.substring(0, AppConstants.baseUrl.length - 1)
          : AppConstants.baseUrl;

      final res = await http
          .post(
            Uri.parse('$base/$endpoint'),
            headers: await _headers(auth: auth),
            body: jsonEncode(body),
          )
          .timeout(_timeout);

      if (res.statusCode == 401) {
        return {'success': false, 'message': 'Session expired. Please login again.', 'code': 401};
      }

      return _decode(res);
    } catch (e) {
      return _error(e);
    }
  }

  // ── PUT ───────────────────────────────────────────
  static Future<Map<String, dynamic>> put(
    String endpoint,
    Map<String, dynamic> body, {
    bool auth = false,
  }) async {
    try {
      final base = AppConstants.baseUrl.endsWith('/')
          ? AppConstants.baseUrl.substring(0, AppConstants.baseUrl.length - 1)
          : AppConstants.baseUrl;

      final res = await http
          .put(
            Uri.parse('$base/$endpoint'),
            headers: await _headers(auth: auth),
            body: jsonEncode(body),
          )
          .timeout(_timeout);

      if (res.statusCode == 401) {
        return {'success': false, 'message': 'Session expired. Please login again.', 'code': 401};
      }

      return _decode(res);
    } catch (e) {
      return _error(e);
    }
  }
}