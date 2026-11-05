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
}
