import 'package:flutter/material.dart';

import '../theme.dart';

/// Píldora de selección única reutilizable (barras de orden y de filtros).
class FilterPill extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final String? semanticLabel;

  const FilterPill({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final scheme = Theme.of(context).colorScheme;
    final color = selected ? scheme.primary : scheme.onSurfaceVariant;

    return Semantics(
      button: true,
      selected: selected,
      label: semanticLabel ?? label,
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
            borderRadius:
                const BorderRadius.all(Radius.circular(AppRadius.chip)),
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
