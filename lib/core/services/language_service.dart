// lib/core/services/language_service.dart
//
// App-wide language preference (English / Hindi).
// - Default: English.
// - Set from Profile; persisted in SharedPreferences.
// - Drives the DEFAULT question language; users can still switch a single
//   question during a test (question_screen has its own per-test toggle).

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageService extends ChangeNotifier {
  LanguageService._();
  static final LanguageService instance = LanguageService._();

  static const _key = 'app_lang';
  bool _isHindi = false;

  bool get isHindi => _isHindi;
  String get lang => _isHindi ? 'hi' : 'en';

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isHindi = (prefs.getString(_key) ?? 'en') == 'hi';
    } catch (_) {}
    notifyListeners();
  }

  Future<void> setHindi(bool hi) async {
    _isHindi = hi;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, hi ? 'hi' : 'en');
    } catch (_) {}
  }
}
