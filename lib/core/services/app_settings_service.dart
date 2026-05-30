// lib/core/services/app_settings_service.dart
//
// Singleton that keeps app_settings in memory and exposes them everywhere.
//
// Refresh strategy:
//   1. App start  → SplashScreen calls `init()`.
//   2. App resume → main.dart's lifecycle observer calls `refresh()`.
//   3. Anywhere   → call `refresh()` after a known-changing event.
//
// Anything reading a setting (PaymentService, splash, premium screen, etc.)
// goes through `get('key')` so they always see the latest value with zero
// rebuild required.

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'content_service.dart';

class AppSettingsService extends ChangeNotifier {
  AppSettingsService._();
  static final AppSettingsService instance = AppSettingsService._();

  static const _prefsKey = 'cached_app_settings_v1';

  Map<String, dynamic> _cache = {};
  DateTime? _lastFetch;
  bool _initialized = false;
  bool _refreshing = false;

  /// Read-only snapshot of all settings.
  Map<String, dynamic> get all => Map.unmodifiable(_cache);

  bool get isInitialized => _initialized;
  DateTime? get lastFetch => _lastFetch;

  /// Returns a setting value as String (default empty).
  String get(String key, [String fallback = '']) {
    final v = _cache[key];
    if (v == null) return fallback;
    return v.toString();
  }

  /// Returns int form (default 0).
  int getInt(String key, [int fallback = 0]) {
    final v = _cache[key];
    if (v == null) return fallback;
    return int.tryParse(v.toString()) ?? fallback;
  }

  /// Returns bool form. Strings "1", "true", "yes", "on" → true.
  bool getBool(String key, [bool fallback = false]) {
    final v = _cache[key];
    if (v == null) return fallback;
    final s = v.toString().toLowerCase().trim();
    return s == '1' || s == 'true' || s == 'yes' || s == 'on';
  }

  // ── Initialization ───────────────────────────────
  /// Called once at splash. Loads from disk first (instant), then triggers a
  /// network refresh in background.
  Future<void> init() async {
    if (_initialized) {
      // Still trigger a background refresh in case admin changed something
      refresh();
      return;
    }
    _initialized = true;
    await _loadFromDisk();
    // Fire & forget — splash continues without blocking
    refresh();
  }

  /// Force re-fetch from server. Quietly ignores failures, never throws.
  /// Returns true if cache changed.
  Future<bool> refresh() async {
    if (_refreshing) return false;
    _refreshing = true;
    try {
      final fresh = await ContentService.getAppSettings();
      if (fresh.isEmpty) return false;
      final changed = !_mapEquals(_cache, fresh);
      _cache = Map<String, dynamic>.from(fresh);
      _lastFetch = DateTime.now();
      await _saveToDisk();
      if (changed) notifyListeners();
      return changed;
    } catch (e) {
      debugPrint('[AppSettings.refresh] $e');
      return false;
    } finally {
      _refreshing = false;
    }
  }

  /// Manually patch local cache (useful right after a known admin update).
  void overrideLocal(Map<String, dynamic> patch) {
    _cache = {..._cache, ...patch};
    notifyListeners();
    _saveToDisk();
  }

  // ── Disk cache ───────────────────────────────────
  Future<void> _loadFromDisk() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw == null || raw.isEmpty) return;
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        _cache = decoded.map((k, v) => MapEntry(k.toString(), v));
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> _saveToDisk() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, jsonEncode(_cache));
    } catch (_) {}
  }

  bool _mapEquals(Map a, Map b) {
    if (a.length != b.length) return false;
    for (final k in a.keys) {
      if (!b.containsKey(k)) return false;
      if ('${a[k]}' != '${b[k]}') return false;
    }
    return true;
  }
}
