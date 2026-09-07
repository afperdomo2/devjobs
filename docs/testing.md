# Testing

Pruebas unitarias para la lógica reutilizable de `devjobs`.

## Estructura

`test/` replica la estructura de `lib/`:

```
lib/helpers/domain_parser.dart      → test/helpers/domain_parser_test.dart
lib/helpers/salary_formatter.dart   → test/helpers/salary_formatter_test.dart
lib/helpers/text_shortener.dart     → test/helpers/text_shortener_test.dart
lib/helpers/date_formatter.dart     → test/helpers/date_formatter_test.dart
lib/helpers/network_error.dart      → test/helpers/network_error_test.dart
lib/models/job_application.dart     → test/models/job_application_test.dart
```

## Convenciones

- Solo `flutter_test` (sin dependencias extra). Los helpers/model son Dart puro y no requieren mocks.
- Cada función/getter debe cubrir al menos: el camino feliz, un caso vacío/null y una variante realista (p. ej. `extractPlatform`: dominio directo vs subdominio vs TLD compuesto).
- Para pruebas de fechas con `intl`, inicializar el locale español en `setUpAll`:
  ```dart
  import 'package:intl/date_symbol_data_local.dart';

  setUpAll(() async {
    await initializeDateFormatting('es');
  });
  ```
  Necesario para que `DateFormat('d \'de\' MMMM, yyyy', 'es')` resuelva nombres de mes en español.
- Agrupar por `group('nombreDeFuncion', () { test('describe caso', () { ... }); })`.

## Cómo correr

```bash
flutter test                         # todas
flutter test test/helpers/domain_parser_test.dart  # un archivo
flutter analyze                      # lint
```

Ambos comandos deben estar en verde antes de hacer commit de cambios en helpers/model.

## Ejemplo mínimo

```dart
import 'package:devjobs/helpers/domain_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('extractPlatform', () {
    test('link vacío retorna vacío', () {
      expect(extractPlatform(''), equals(''));
    });

    test('extrae dominio directo', () {
      expect(extractPlatform('https://www.linkedin.com/jobs/1'), equals('Linkedin'));
    });

    test('maneja subdominio y TLD compuesto', () {
      expect(extractPlatform('https://co.computrabajo.com/empleo/1'), equals('Computrabajo'));
      expect(extractPlatform('https://www.computrabajo.com.co/empleo/1'), equals('Computrabajo'));
    });
  });
}
```
