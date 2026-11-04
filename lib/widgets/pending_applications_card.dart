import 'package:flutter/material.dart';

import '../helpers/date_formatter.dart';
import '../models/job_application.dart';
import '../theme.dart';
import 'application_compact_row.dart';

/// Tarjeta de Inicio con las postulaciones marcadas "Por gestionar"
/// (switch de la columna O).
///
/// Muestra hasta [maxRows] filas y el total. Si la lista está vacía no pinta
/// nada: la decisión de ocultarla vive en la pantalla.
class PendingApplicationsCard extends StatelessWidget {
  final List<JobApplication> applications;
  final VoidCallback onSeeAll;
  final ValueChanged<JobApplication> onOpen;
  final int maxRows;

  const PendingApplicationsCard({
    super.key,
    required this.applications,
    required this.onSeeAll,
    required this.onOpen,
    this.maxRows = 3,
  });

  @override
  Widget build(BuildContext context) {
    if (applications.isEmpty) return const SizedBox.shrink();

    final brightness = Theme.of(context).brightness;
    final gestion = gestionColor(brightness);
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final count = applications.length;
    final visible = applications.take(maxRows).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.label_important,
                  size: AppIconSize.metric,
                  color: gestion,
                ),
                const SizedBox(width: AppSpace.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Por gestionar',
                        style: AppType.section(context),
                      ),
                      Text(
                        'Pendientes de acción',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: muted),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpace.sm,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: gestion.withValues(alpha: 0.12),
                    borderRadius: const BorderRadius.all(
                      Radius.circular(AppRadius.bar),
                    ),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: gestion,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpace.md),
            for (var i = 0; i < visible.length; i++) ...[
              ApplicationCompactRow(
                application: visible[i],
                onTap: () => onOpen(visible[i]),
                trailingLabel: formatSinNovedad(
                  visible[i].diasDesdeUltimaNovedad ?? 0,
                ),
                trailingColor: gestion,
              ),
              if (i < visible.length - 1) const Divider(height: 1),
            ],
            if (count > maxRows) ...[
              const SizedBox(height: AppSpace.xs),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: onSeeAll,
                  child: Text('Ver todas ($count)'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
