import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/job_application.dart';

class LocalCache {
  static const _keyData = 'devjobs_cached_applications';
  static const _keyTimestamp = 'devjobs_cached_timestamp';

  final SharedPreferences _prefs;

  LocalCache(this._prefs);

  Future<List<JobApplication>?> load() async {
    final raw = _prefs.getString(_keyData);
    if (raw == null || raw.isEmpty) return null;
    try {
      final List<dynamic> jsonList = jsonDecode(raw) as List<dynamic>;
      return jsonList
          .map((e) => JobApplication.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return null;
    }
  }

  Future<void> save(List<JobApplication> apps) async {
    final jsonList = apps.map((a) => a.toJson()).toList();
    await _prefs.setString(_keyData, jsonEncode(jsonList));
    await _prefs.setString(_keyTimestamp, DateTime.now().toIso8601String());
  }

  DateTime? get lastSavedAt {
    final raw = _prefs.getString(_keyTimestamp);
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }

  Future<void> clear() async {
    await _prefs.remove(_keyData);
    await _prefs.remove(_keyTimestamp);
  }
}
