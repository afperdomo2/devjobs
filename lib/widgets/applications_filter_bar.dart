import 'package:flutter/material.dart';

import '../providers/app_state.dart';
import '../theme.dart';

/// Definición visual de un filtro de la pestaña Postulaciones.
class ApplicationFilterSpec {
  final String mode;
  final String label;
  final IconData icon;
  final Color Function(Brightness) color;

  const ApplicationFilterSpec({
    required this.mode,
    required this.label,
    required this.icon,
    required this.color,
  });
}

/// Orden en que se pintan las pills.
final applicationFilters = <ApplicationFilterSpec>[
  ApplicationFilterSpec(
    mode: AppState.filterAll,
    label: 'Todas',
    icon: Icons.list_alt,
    color: infoColor,
  ),
  ApplicationFilterSpec(
    mode: AppState.filterActivas,
    label: 'Activas',
    icon: Icons.notifications_active_outlined,
    color: tealColor,
  ),
  ApplicationFilterSpec(
    mode: AppState.filterEnviadas,
    label: 'Enviadas',
    icon: Icons.schedule_outlined,
    color: indigoColor,
  ),
  ApplicationFilterSpec(
    mode: AppState.filterFinalizadas,
    label: 'Finalizadas',
    icon: Icons.check_circle_outline,
    color: neutralColor,
  ),
];

/// Fila horizontal de filtros de Postulaciones, con contador por filtro.
/// Scrollea en horizontal para que las cuatro pills entren a 360 px.
class ApplicationsFilterBar extends StatelessWidget {
  final String selected;
  final Map<String, int> counts;
  final ValueChanged<String> onSelected;

  const ApplicationsFilterBar({
    super.key,
    required this.selected,
    required this.counts,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.lg,
          vertical: AppSpace.sm,
        ),
        child: Row(
          children: [
            for (final spec in applicationFilters) ...[
              _FilterPill(
                spec: spec,
                count: counts[spec.mode] ?? 0,
                selected: selected == spec.mode,
                onTap: () => onSelected(spec.mode),
              ),
              if (spec != applicationFilters.last)
                const SizedBox(width: AppSpace.sm),
            ],
          ],
        ),
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  final ApplicationFilterSpec spec;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  const _FilterPill({
    required this.spec,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final color = spec.color(brightness);

    return Semantics(
      button: true,
      selected: selected,
      label: '${spec.label}: $count postulaciones',
      child: InkWell(
        onTap: onTap,
        borderRadius: const BorderRadius.all(Radius.circular(AppRadius.chip)),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.md,
            vertical: AppSpace.sm - 2,
          ),
          decoration: BoxDecoration(
            color: selected ? color.withValues(alpha: 0.14) : Colors.transparent,
            borderRadius: const BorderRadius.all(Radius.circular(AppRadius.chip)),
            border: Border.all(
              color: selected ? color : chipBorderColor(brightness),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                spec.icon,
                size: AppIconSize.chip,
                color: selected ? color : muted,
              ),
              const SizedBox(width: AppSpace.xs),
              Text(
                spec.label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? color : muted,
                ),
              ),
              const SizedBox(width: AppSpace.xs + 2),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: selected
                      ? color.withValues(alpha: 0.18)
                      : Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius:
                      const BorderRadius.all(Radius.circular(AppRadius.bar)),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: selected ? color : muted,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
