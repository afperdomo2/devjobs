import 'package:devjobs/helpers/app_build_info.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('shortCommit', () {
    test('recorta a siete caracteres', () {
      expect(shortCommit('a1b2c3d4e5f6'), 'a1b2c3d');
    });

    test('deja los hashes cortos y recorta espacios', () {
      expect(shortCommit('  abc  '), 'abc');
      expect(shortCommit('a1b2c3d'), 'a1b2c3d');
    });

    test('vacío se queda vacío', () {
      expect(shortCommit(''), '');
      expect(shortCommit('   '), '');
    });
  });

  group('isDirtyFlag', () {
    test('solo "true" activa la marca', () {
      expect(isDirtyFlag('true'), isTrue);
      expect(isDirtyFlag(' TRUE '), isTrue);
    });

    test('otros valores no la activan', () {
      expect(isDirtyFlag('false'), isFalse);
      expect(isDirtyFlag(''), isFalse);
      expect(isDirtyFlag('1'), isFalse);
    });
  });

  group('parseBuildTime', () {
    test('interpreta el ISO UTC del script como hora local', () {
      final date = parseBuildTime('2026-11-12T18:22:05Z');

      expect(date, isNotNull);
      expect(date!.isUtc, isFalse);
      expect(date.toUtc(), DateTime.utc(2026, 11, 12, 18, 22, 5));
    });

    test('sin fecha o inválida devuelve null', () {
      expect(parseBuildTime(''), isNull);
      expect(parseBuildTime('   '), isNull);
      expect(parseBuildTime('ayer'), isNull);
    });
  });

  group('formatBuildTime', () {
    test('formatea día, mes, año y hora', () {
      expect(
        formatBuildTime(DateTime(2026, 11, 12, 14, 22)),
        '12 nov 2026 · 14:22',
      );
    });

    test('rellena la hora con ceros', () {
      expect(formatBuildTime(DateTime(2026, 1, 5, 9, 3)), '5 ene 2026 · 09:03');
    });

    test('sin fecha muestra "No disponible"', () {
      expect(formatBuildTime(null), kBuildUnavailable);
    });
  });

  group('appVersionLabel', () {
    test('incluye el número de build', () {
      expect(appVersionLabel('0.2.0', '2'), 'v0.2.0 (2)');
    });

    test('sin build number solo muestra la versión', () {
      expect(appVersionLabel(' 0.2.0 ', '  '), 'v0.2.0');
    });

    test('sin versión muestra "No disponible"', () {
      expect(appVersionLabel('', '2'), kBuildUnavailable);
    });
  });

  group('appCommitLabel', () {
    test('agrega el asterisco cuando hay cambios sin commitear', () {
      expect(appCommitLabel('3d8890b', dirty: true), '3d8890b *');
      expect(appCommitLabel('3d8890b'), '3d8890b');
    });

    test('sin commit muestra "No disponible" aunque esté dirty', () {
      expect(appCommitLabel('', dirty: true), kBuildUnavailable);
    });
  });

  group('platformLabel', () {
    test('saca la arquitectura de Platform.version', () {
      expect(
        platformLabel(
          'linux',
          '3.13.7 (stable) (Wed Oct 29 2026) on "linux_x64"',
        ),
        'Linux x64',
      );
    });

    test('reconoce Windows arm64', () {
      expect(
        platformLabel('windows', '3.13.7 (stable) on "windows_arm64"'),
        'Windows arm64',
      );
    });

    test('sin arquitectura deja solo el sistema', () {
      expect(platformLabel('linux', ''), 'Linux');
      expect(platformLabel('macos', 'sin target'), 'macOS');
    });

    test('sin sistema muestra "No disponible"', () {
      expect(platformLabel('', ''), kBuildUnavailable);
    });
  });

  group('buildChannelLabel', () {
    test('distingue release, debug y profile', () {
      expect(buildChannelLabel(release: true, debug: false), 'release');
      expect(buildChannelLabel(release: false, debug: true), 'debug');
      expect(buildChannelLabel(release: false, debug: false), 'profile');
    });
  });
}
