import 'package:flutter/material.dart';

import '../helpers/company_stats.dart';
import '../theme.dart';

/// Fila horizontal de criterios de orden para el listado de Empresas.
class CompanySortBar extends StatelessWidget {
  final CompanySortMode selected;
  final ValueChanged<CompanySortMode> onSelected;

  const CompanySortBar({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  static final _specs = <(CompanySortMode, String, IconData)>[
    (CompanySortMode.total, 'Más postulaciones', Icons.list_alt),
    (
      CompanySortMode.activas,
      'Más activas',
      Icons.notifications_active_outlined,
    ),
    (
      CompanySortMode.entrevistas,
      'Más entrevistas',
      Icons.record_voice_over_outlined,
    ),
    (
      CompanySortMode.responseRate,
      'Mejor respuesta',
      Icons.check_circle_outline,
    ),
    (CompanySortMode.recent, 'Recientes', Icons.schedule),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.lg,
          vertical: AppSpace.xs,
        ),
        child: Row(
          children: [
            for (var i = 0; i < _specs.length; i++) ...[
              _SortPill(
                label: _specs[i].$2,
                icon: _specs[i].$3,
                selected: _specs[i].$1 == selected,
                onTap: () => onSelected(_specs[i].$1),
              ),
              if (i < _specs.length - 1) const SizedBox(width: AppSpace.sm),
            ],
          ],
        ),
      ),
    );
  }
}

class _SortPill extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _SortPill({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final scheme = Theme.of(context).colorScheme;
    final color = selected ? scheme.primary : scheme.onSurfaceVariant;

    return Semantics(
      button: true,
      selected: selected,
      label: 'Ordenar por $label',
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
            color: selected ? scheme.primary.withValues(alpha: 0.10) : null,
            borderRadius: const BorderRadius.all(Radius.circular(AppRadius.chip)),
            border: Border.all(
              color: selected ? scheme.primary : chipBorderColor(brightness),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: AppIconSize.chip, color: color),
              const SizedBox(width: AppSpace.xs),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
