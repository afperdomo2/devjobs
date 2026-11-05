import 'package:devjobs/helpers/theme_mode.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('themeModeName', () {
    test('usa nombres estables para cada modo', () {
      expect(themeModeName(ThemeMode.system), 'system');
      expect(themeModeName(ThemeMode.light), 'light');
      expect(themeModeName(ThemeMode.dark), 'dark');
    });
  });

  group('themeModeFromName', () {
    test('lee los tres valores persistidos', () {
      expect(themeModeFromName('system'), ThemeMode.system);
      expect(themeModeFromName('light'), ThemeMode.light);
      expect(themeModeFromName('dark'), ThemeMode.dark);
    });

    test('sin valor o valor desconocido usa sistema', () {
      expect(themeModeFromName(null), ThemeMode.system);
      expect(themeModeFromName(''), ThemeMode.system);
      expect(themeModeFromName('morado'), ThemeMode.system);
    });

    test('hace round-trip con themeModeName', () {
      for (final mode in ThemeMode.values) {
        expect(themeModeFromName(themeModeName(mode)), mode);
      }
    });
  });

  group('etiquetas del menú', () {
    test('expone los textos en español', () {
      expect(themeModeLabel(ThemeMode.system), 'Sistema');
      expect(themeModeLabel(ThemeMode.light), 'Claro');
      expect(themeModeLabel(ThemeMode.dark), 'Oscuro');
    });

    test('cada opción tiene descripción e ícono', () {
      for (final mode in ThemeMode.values) {
        expect(themeModeDescription(mode), isNotEmpty);
        expect(themeModeIcon(mode), isA<IconData>());
      }
    });
  });
}
