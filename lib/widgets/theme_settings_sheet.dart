import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../helpers/theme_mode.dart';
import '../models/app_build_info.dart';
import '../providers/app_state.dart';
import '../screens/about_screen.dart';
import '../screens/ai_settings_screen.dart';
import '../services/build_info_service.dart';
import '../theme.dart';

/// Abre el menú de ajustes: tema, importación con IA y datos de la compilación.
Future<void> showThemeSettingsSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (_) => const ThemeSettingsSheet(),
  );
}

/// Hoja inferior con las opciones de tema, el acceso a la configuración de IA
/// y los datos de la compilación.
///
/// El cambio de tema se aplica al instante (el `MaterialApp` escucha a
/// [AppState] y este widget refleja la selección) y se persiste en [AppState].
/// La importación con IA se configura en `AiSettingsScreen`.
class ThemeSettingsSheet extends StatelessWidget {
  const ThemeSettingsSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final selected = context.watch<AppState>().themeMode;
    final theme = Theme.of(context);

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: AppSpace.sm),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.lg,
                AppSpace.xs,
                AppSpace.lg,
                AppSpace.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ajustes',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpace.xs),
                  Text('Tema, IA y compilación', style: AppType.label(context)),
                ],
              ),
            ),
            for (final mode in ThemeMode.values)
              _ThemeModeTile(
                mode: mode,
                selected: mode == selected,
                onTap: () async {
                  await context.read<AppState>().setThemeMode(mode);
                  if (context.mounted) Navigator.of(context).pop();
                },
              ),
            const SizedBox(height: AppSpace.sm),
            const _AiSettingsTile(),
            const _AboutTile(),
          ],
        ),
      ),
    );
  }
}

/// Acceso a la configuración de la importación con IA.
class _AiSettingsTile extends StatelessWidget {
  const _AiSettingsTile();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final config = state.aiConfig;
    final scheme = Theme.of(context).colorScheme;

    final subtitle = state.aiEnabled
        ? '${config.models.length} ${config.models.length == 1 ? 'modelo' : 'modelos'} · ${config.providerHost}'
        : 'Sin configurar';

    return ListTile(
      key: const Key('ai-settings'),
      leading: Icon(
        Icons.auto_awesome,
        color: state.aiEnabled ? scheme.primary : null,
      ),
      title: const Text('Importación con IA'),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const AiSettingsScreen()),
        );
      },
    );
  }
}

/// Acceso a la versión y los datos de la compilación en ejecución.
///
/// El subtítulo ya muestra versión y commit, así que el dato queda a la vista
/// sin abrir la pantalla.
class _AboutTile extends StatefulWidget {
  const _AboutTile();

  @override
  State<_AboutTile> createState() => _AboutTileState();
}

class _AboutTileState extends State<_AboutTile> {
  late final Future<AppBuildInfo> _future;
  AppBuildInfo? _info;

  @override
  void initState() {
    super.initState();
    _future = BuildInfoService().load();
    _future.then((info) {
      if (mounted) setState(() => _info = info);
    }, onError: (_) {});
  }

  String get _subtitle {
    final info = _info;
    if (info == null) return 'Versión y compilación';
    if (!info.hasBuildMetadata) return info.versionLabel;
    return '${info.versionLabel} · ${info.commitLabel}';
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      key: const Key('about-settings'),
      leading: const Icon(Icons.info_outline),
      title: const Text('Acerca de DevJobs'),
      subtitle: Text(_subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => AboutScreen(buildInfo: _future),
          ),
        );
      },
    );
  }
}

class _ThemeModeTile extends StatelessWidget {
  final ThemeMode mode;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeModeTile({
    required this.mode,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(
        themeModeIcon(mode),
        color: selected ? scheme.primary : null,
      ),
      title: Text(themeModeLabel(mode)),
      subtitle: Text(themeModeDescription(mode)),
      trailing: selected ? Icon(Icons.check, color: scheme.primary) : null,
      selected: selected,
      selectedColor: scheme.primary,
      selectedTileColor: scheme.primaryContainer.withValues(alpha: 0.35),
      onTap: onTap,
    );
  }
}
