import '../helpers/app_build_info.dart';

/// Versión, commit y fecha de la compilación que se está ejecutando.
///
/// Sirve para comparar la app instalada con el código: si el commit mostrado
/// no es el último de `git log`, falta compilar.
class AppBuildInfo {
  /// Versión del `pubspec.yaml` (p. ej. `0.2.0`).
  final String version;

  /// Número de build del `pubspec.yaml` (p. ej. `2`).
  final String buildNumber;

  /// Hash corto del commit con el que se compiló (vacío sin `scripts/build.sh`).
  final String commit;

  /// Momento de la compilación (hora local); `null` si no se inyectó.
  final DateTime? buildDate;

  /// `true` si se compiló con cambios sin commitear.
  final bool dirty;

  /// Sistema y arquitectura (`Linux x64`).
  final String platform;

  /// `release`, `debug` o `profile`.
  final String channel;

  const AppBuildInfo({
    this.version = '',
    this.buildNumber = '',
    this.commit = '',
    this.buildDate,
    this.dirty = false,
    this.platform = '',
    this.channel = '',
  });

  String get versionLabel => appVersionLabel(version, buildNumber);
  String get commitLabel => appCommitLabel(commit, dirty: dirty);
  String get dateLabel => formatBuildTime(buildDate);

  /// Hay commit o fecha: el build se hizo con `scripts/build.sh`.
  bool get hasBuildMetadata => commit.isNotEmpty || buildDate != null;

  /// Texto del botón "Copiar información".
  String get copyText => [
    'DevJobs $versionLabel',
    'Commit: $commitLabel',
    'Compilada: $dateLabel',
    'Plataforma: $platform',
    'Canal: $channel',
  ].join('\n');
}
