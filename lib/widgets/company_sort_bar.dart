import 'package:flutter/material.dart';

import '../helpers/company_stats.dart';
import '../theme.dart';
import 'filter_pill.dart';

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
    (CompanySortMode.recomendacion, 'Recomendación', Icons.auto_awesome),
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
              FilterPill(
                label: _specs[i].$2,
                icon: _specs[i].$3,
                selected: _specs[i].$1 == selected,
                onTap: () => onSelected(_specs[i].$1),
                semanticLabel: 'Ordenar por ${_specs[i].$2}',
              ),
              if (i < _specs.length - 1) const SizedBox(width: AppSpace.sm),
            ],
          ],
        ),
      ),
    );
  }
}
