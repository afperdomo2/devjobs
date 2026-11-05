import 'package:devjobs/providers/app_state.dart';
import 'package:devjobs/services/local_cache.dart';
import 'package:devjobs/services/sheets_api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeApi extends SheetsApiService {
  _FakeApi() : super(baseUrl: 'http://test');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('arranca en sistema y persiste el cambio', () async {
    final prefs = await SharedPreferences.getInstance();
    final cache = LocalCache(prefs);
    final state = AppState(apiService: _FakeApi(), localCache: cache);

    expect(state.themeMode, ThemeMode.system);

    await state.setThemeMode(ThemeMode.dark);

    expect(state.themeMode, ThemeMode.dark);
    expect(cache.themeMode, ThemeMode.dark);

    // Un nuevo arranque lee la preferencia guardada.
    final restarted = AppState(apiService: _FakeApi(), localCache: cache);
    expect(restarted.themeMode, ThemeMode.dark);
  });

  test('respeta initialThemeMode por encima de la caché', () async {
    final prefs = await SharedPreferences.getInstance();
    final cache = LocalCache(prefs);
    await cache.saveThemeMode(ThemeMode.dark);

    final state = AppState(
      apiService: _FakeApi(),
      localCache: cache,
      initialThemeMode: ThemeMode.light,
    );

    expect(state.themeMode, ThemeMode.light);
  });

  test('sin caché funciona y notifica una sola vez', () async {
    final state = AppState(apiService: _FakeApi());
    var notifications = 0;
    state.addListener(() => notifications++);

    expect(state.themeMode, ThemeMode.system);
    await state.setThemeMode(ThemeMode.light);
    await state.setThemeMode(ThemeMode.light);

    expect(state.themeMode, ThemeMode.light);
    expect(notifications, 1);
  });
}
