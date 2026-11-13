import 'package:devjobs/models/app_build_info.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const complete = AppBuildInfo(
    version: '0.2.0',
    buildNumber: '2',
    commit: '3d8890b',
    dirty: true,
    platform: 'Linux x64',
    channel: 'release',
  );

  test('etiquetas de versión, commit y fecha', () {
    expect(complete.versionLabel, 'v0.2.0 (2)');
    expect(complete.commitLabel, '3d8890b *');
    expect(complete.dateLabel, 'No disponible');
  });

  test('copyText arma el bloque para reportar problemas', () {
    final info = AppBuildInfo(
      version: '0.2.0',
      buildNumber: '2',
      commit: '3d8890b',
      buildDate: DateTime(2026, 11, 12, 14, 22),
      platform: 'Linux x64',
      channel: 'release',
    );

    expect(
      info.copyText,
      [
        'DevJobs v0.2.0 (2)',
        'Commit: 3d8890b',
        'Compilada: 12 nov 2026 · 14:22',
        'Plataforma: Linux x64',
        'Canal: release',
      ].join('\n'),
    );
  });

  test('hasBuildMetadata distingue un build con script de uno sin él', () {
    expect(const AppBuildInfo().hasBuildMetadata, isFalse);
    expect(const AppBuildInfo(commit: '3d8890b').hasBuildMetadata, isTrue);
    expect(
      AppBuildInfo(buildDate: DateTime(2026, 11, 12)).hasBuildMetadata,
      isTrue,
    );
  });

  test('por defecto no está dirty ni tiene datos', () {
    const info = AppBuildInfo();

    expect(info.dirty, isFalse);
    expect(info.versionLabel, 'No disponible');
    expect(info.commitLabel, 'No disponible');
    expect(info.buildDate, isNull);
  });
}
