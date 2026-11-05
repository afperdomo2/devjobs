import 'package:flutter/material.dart';

import '../helpers/agenda.dart';
import '../helpers/date_formatter.dart';
import '../models/job_application.dart';
import '../theme.dart';
import 'application_compact_row.dart';

/// Bloque de una sección de Agenda con hasta [maxRows] postulaciones.
class AgendaSectionCard extends StatelessWidget {
  final AgendaSection section;
  final ValueChanged<JobApplication> onOpen;
  final VoidCallback onSeeAll;
  final int maxRows;

  const AgendaSectionCard({
    super.key,
    required this.section,
    required this.onOpen,
    required this.onSeeAll,
    this.maxRows = 5,
  });

  @override
  Widget build(BuildContext context) {
    if (section.applications.isEmpty) return const SizedBox.shrink();

    final brightness = Theme.of(context).brightness;
    final (title, icon, color) = switch (section.kind) {
      AgendaSectionKind.porGestionar => (
          'Por gestionar',
          Icons.label_important,
          gestionColor(brightness),
        ),
      AgendaSectionKind.entrevistaAgendada => (
          'Entrevistas agendadas',
          Icons.event_available,
          statusColor('entrevista', brightness),
        ),
      AgendaSectionKind.ofertaRecibida => (
          'Ofertas recibidas',
          Icons.workspace_premium,
          statusColor('oferta', brightness),
        ),
    };
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final count = section.applications.length;
    final visible = section.applications.take(maxRows).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: AppIconSize.metric, color: color),
                const SizedBox(width: AppSpace.sm),
                Expanded(
                  child: Text(title, style: AppType.section(context)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpace.sm,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: const BorderRadius.all(
                      Radius.circular(AppRadius.bar),
                    ),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: color,
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
                trailingColor: muted,
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
