import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config.dart';
import '../helpers/theme_mode.dart';
import '../models/ai_config.dart';
import '../models/company_insight.dart';
import '../models/job_application.dart';

class LocalCache {
  static const _keyData = 'devjobs_cached_applications';
  static const _keyTimestamp = 'devjobs_cached_timestamp';
  static const _keyThemeMode = 'devjobs_theme_mode';
  static const _keyAiConfig = 'devjobs_ai_config';
  static const _keyInsights = 'devjobs_company_insights';

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

  /// Tema elegido por el usuario; [ThemeMode.system] si nunca eligió uno.
  ThemeMode get themeMode => themeModeFromName(_prefs.getString(_keyThemeMode));

  Future<void> saveThemeMode(ThemeMode mode) async {
    await _prefs.setString(_keyThemeMode, themeModeName(mode));
  }

  /// Configuración de IA guardada.
  ///
  /// Si el usuario nunca guardó una, se usa la semilla del `.env`
  /// ([kAiConfig]), para que una instalación existente siga igual. Si el valor
  /// guardado está corrupto, la IA queda desactivada en lugar de
  /// reactivarse con valores que el usuario no eligió.
  AiConfig get aiConfig {
    final raw = _prefs.getString(_keyAiConfig);
    if (raw == null) return kAiConfig;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return AiConfig.empty;
      return AiConfig.fromJson(Map<String, dynamic>.from(decoded));
    } catch (_) {
      return AiConfig.empty;
    }
  }

  Future<void> saveAiConfig(AiConfig config) async {
    await _prefs.setString(_keyAiConfig, jsonEncode(config.toJson()));
  }

  /// Borra la configuración guardada para volver a la semilla del `.env`.
  Future<void> clearAiConfig() async {
    await _prefs.remove(_keyAiConfig);
  }

  /// Análisis IA de empresas guardados en el dispositivo.
  Future<List<CompanyInsight>?> loadCompanyInsights() async {
    final raw = _prefs.getString(_keyInsights);
    if (raw == null || raw.isEmpty) return null;
    try {
      final List<dynamic> jsonList = jsonDecode(raw) as List<dynamic>;
      return jsonList
          .whereType<Map>()
          .map((e) => CompanyInsight.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (_) {
      return null;
    }
  }

  Future<void> saveCompanyInsights(List<CompanyInsight> insights) async {
    final jsonList = insights.map((i) => i.toJson()).toList();
    await _prefs.setString(_keyInsights, jsonEncode(jsonList));
  }

  Future<void> clear() async {
    await _prefs.remove(_keyData);
    await _prefs.remove(_keyTimestamp);
    await _prefs.remove(_keyInsights);
  }
}
