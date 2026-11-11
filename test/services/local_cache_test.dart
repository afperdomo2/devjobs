import 'package:devjobs/config.dart';
import 'package:devjobs/models/ai_config.dart';
import 'package:devjobs/services/local_cache.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('sin preferencia guardada usa el tema del sistema', () async {
    final prefs = await SharedPreferences.getInstance();
    expect(LocalCache(prefs).themeMode, ThemeMode.system);
  });

  test('guarda y recupera el tema elegido', () async {
    final prefs = await SharedPreferences.getInstance();
    final cache = LocalCache(prefs);

    await cache.saveThemeMode(ThemeMode.dark);

    expect(cache.themeMode, ThemeMode.dark);
    expect(LocalCache(prefs).themeMode, ThemeMode.dark);
  });

  test('un valor desconocido cae en sistema', () async {
    SharedPreferences.setMockInitialValues({'devjobs_theme_mode': 'morado'});
    final prefs = await SharedPreferences.getInstance();

    expect(LocalCache(prefs).themeMode, ThemeMode.system);
  });

  test('sin configuración guardada usa la semilla del .env', () async {
    final prefs = await SharedPreferences.getInstance();

    expect(LocalCache(prefs).aiConfig, equals(kAiConfig));
  });

  test('guarda y recupera la configuración de IA', () async {
    final prefs = await SharedPreferences.getInstance();
    final cache = LocalCache(prefs);
    const config = AiConfig(
      baseUrl: 'https://api.example.com/v1',
      apiKey: 'key',
      models: ['modelo-a', 'modelo-b'],
    );

    await cache.saveAiConfig(config);

    expect(cache.aiConfig, equals(config));
    expect(LocalCache(prefs).aiConfig, equals(config));
  });

  test('un valor corrupto desactiva la IA en lugar de reactivarla', () async {
    SharedPreferences.setMockInitialValues({
      'devjobs_ai_config': 'no es json',
    });
    final prefs = await SharedPreferences.getInstance();

    expect(LocalCache(prefs).aiConfig.isEnabled, isFalse);
  });

  test('borrar la configuración vuelve a la semilla del .env', () async {
    final prefs = await SharedPreferences.getInstance();
    final cache = LocalCache(prefs);
    await cache.saveAiConfig(
      const AiConfig(baseUrl: 'https://x.com/v1', apiKey: 'k', models: ['m']),
    );

    await cache.clearAiConfig();

    expect(cache.aiConfig, equals(kAiConfig));
  });
}
