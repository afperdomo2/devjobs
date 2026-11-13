/// Helpers de la compilación que se está ejecutando (versión, commit, fecha).
///
/// Son funciones puras para poder probarlas sin compilar ni leer el binario:
/// los valores reales los inyecta `scripts/build.sh` con `--dart-define` y
/// `package_info_plus` lee la versión del paquete.
library;

/// Texto que se muestra cuando un dato no se pudo capturar.
const String kBuildUnavailable = 'No disponible';

/// Largo del hash corto de git (`3d8890b`).
const int _shortCommitLength = 7;

const List<String> _months = [
  '',
  'ene',
  'feb',
  'mar',
  'abr',
  'may',
  'jun',
  'jul',
  'ago',
  'sep',
  'oct',
  'nov',
  'dic',
];

/// Recorta el hash de git a siete caracteres (o lo deja tal cual).
String shortCommit(String raw) {
  final commit = raw.trim();
  if (commit.length > _shortCommitLength) {
    return commit.substring(0, _shortCommitLength);
  }
  return commit;
}

/// `true` solo si el build se hizo con cambios sin commitear.
bool isDirtyFlag(String raw) => raw.trim().toLowerCase() == 'true';

/// ISO-8601 en UTC (lo que escribe el script) -> fecha local.
///
/// Devuelve `null` si no se inyectó la fecha o no se puede interpretar.
DateTime? parseBuildTime(String raw) {
  final value = raw.trim();
  if (value.isEmpty) return null;
  return DateTime.tryParse(value)?.toLocal();
}

/// `12 nov 2026 · 14:22` a partir de una fecha local.
String formatBuildTime(DateTime? date) {
  if (date == null) return kBuildUnavailable;
  final local = date.toLocal();
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '${local.day} ${_months[local.month]} ${local.year} · $hour:$minute';
}

/// `v0.1.0 (1)`; sin número de build queda `v0.1.0`.
String appVersionLabel(String version, String buildNumber) {
  final value = version.trim();
  if (value.isEmpty) return kBuildUnavailable;
  final build = buildNumber.trim();
  return build.isEmpty ? 'v$value' : 'v$value ($build)';
}

/// `3d8890b`, o `3d8890b *` si se compiló con cambios sin commitear.
String appCommitLabel(String commit, {bool dirty = false}) {
  final value = commit.trim();
  if (value.isEmpty) return kBuildUnavailable;
  return dirty ? '$value *' : value;
}

/// `Linux x64`, `Windows arm64`, ...
///
/// El sistema sale de `Platform.operatingSystem` y la arquitectura del final de
/// `Platform.version` (`... on "linux_x64"`). Si no se puede leer, queda solo
/// el nombre del sistema.
String platformLabel(String operatingSystem, String dartVersion) {
  final name = switch (operatingSystem.trim().toLowerCase()) {
    'linux' => 'Linux',
    'windows' => 'Windows',
    'macos' => 'macOS',
    'android' => 'Android',
    'ios' => 'iOS',
    'fuchsia' => 'Fuchsia',
    '' => kBuildUnavailable,
    _ => operatingSystem.trim(),
  };
  final arch = _archFromDartVersion(dartVersion);
  return arch == null ? name : '$name $arch';
}

/// Arquitectura a partir de `... on "linux_x64"` / `... on "windows_arm64"`.
String? _archFromDartVersion(String dartVersion) {
  final match = RegExp(r'on "([A-Za-z0-9_]+)"').firstMatch(dartVersion);
  final target = match?.group(1);
  if (target == null) return null;
  final arch = target.split('_').skip(1).join('_');
  return arch.isEmpty ? null : arch;
}

/// `release`, `debug` o `profile`.
String buildChannelLabel({required bool release, required bool debug}) {
  if (release) return 'release';
  if (debug) return 'debug';
  return 'profile';
}
