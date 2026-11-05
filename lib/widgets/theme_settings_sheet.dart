import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../helpers/theme_mode.dart';
import '../providers/app_state.dart';
import '../theme.dart';

/// Abre el menú de ajustes con las tres opciones de tema.
Future<void> showThemeSettingsSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (_) => const ThemeSettingsSheet(),
  );
}

/// Hoja inferior con las opciones Sistema / Claro / Oscuro.
///
/// El cambio se aplica al instante (el `MaterialApp` escucha a [AppState] y
/// este widget refleja la selección) y se persiste en [AppState].
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
                  Text(
                    'Elige cómo se ve la app.',
                    style: AppType.label(context),
                  ),
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
          ],
        ),
      ),
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
