import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../helpers/app_build_info.dart';
import '../models/app_build_info.dart';

/// Repositorio del proyecto (botón "Ver código en GitHub").
const String kRepositoryUrl = 'https://github.com/afperdomo2/devjobs';

/// Compone los datos de la compilación en ejecución.
///
/// La versión y el build salen del paquete instalado (`package_info_plus` lee
/// `version.json` en Linux/Windows y el `PackageManager` en Android, así que
/// siempre coinciden con el `pubspec.yaml`). El commit, la fecha y la marca de
/// cambios sin commitear solo existen si se compiló con `scripts/build.sh`,
/// que los inyecta con `--dart-define`.
class BuildInfoService {
  static const String _commit = String.fromEnvironment('GIT_COMMIT');
  static const String _buildTime = String.fromEnvironment('BUILD_TIME');
  static const String _dirty = String.fromEnvironment('BUILD_DIRTY');

  Future<AppBuildInfo> load() async {
    var version = '';
    var buildNumber = '';
    try {
      final info = await PackageInfo.fromPlatform();
      version = info.version;
      buildNumber = info.buildNumber;
    } catch (_) {
      // Sin plugin (tests, plataforma sin soporte): el resto sigue disponible.
    }

    return AppBuildInfo(
      version: version,
      buildNumber: buildNumber,
      commit: shortCommit(_commit),
      buildDate: parseBuildTime(_buildTime),
      dirty: isDirtyFlag(_dirty),
      platform: platformLabel(Platform.operatingSystem, Platform.version),
      channel: buildChannelLabel(release: kReleaseMode, debug: kDebugMode),
    );
  }
}
