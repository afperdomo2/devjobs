import 'package:flutter/material.dart';

import '../helpers/activity.dart';
import '../helpers/date_formatter.dart';
import '../models/job_application.dart';
import '../theme.dart';

/// Tarjeta de Inicio con los últimos movimientos y los conteos de 7/30 días.
class RecentActivityCard extends StatelessWidget {
  final List<Movement> movements;
  final int last7;
  final int last30;
  final ValueChanged<JobApplication> onOpen;

  const RecentActivityCard({
    super.key,
    required this.movements,
    required this.last7,
    required this.last30,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Actividad reciente', style: AppType.section(context)),
            const SizedBox(height: AppSpace.md),
            Row(
              children: [
                Expanded(
                  child: _SummaryItem(
                    icon: Icons.today,
                    label: 'Últimos 7 días',
                    value: '$last7',
                    color: tealColor(brightness),
                  ),
                ),
                Expanded(
                  child: _SummaryItem(
                    icon: Icons.calendar_month,
                    label: 'Últimos 30 días',
                    value: '$last30',
                    color: successColor(brightness),
                  ),
                ),
              ],
            ),
            const Divider(height: AppSpace.xl),
            if (movements.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpace.sm),
                child: Text(
                  'Sin movimientos recientes',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: muted,
                      ),
                ),
              )
            else
              for (var i = 0; i < movements.length; i++) ...[
                _MovementRow(
                  movement: movements[i],
                  onTap: () => onOpen(movements[i].application),
                ),
                if (i < movements.length - 1) const Divider(height: 1),
              ],
          ],
        ),
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _SummaryItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: AppIconSize.metric, color: color),
        const SizedBox(width: AppSpace.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
              ),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MovementRow extends StatelessWidget {
  final Movement movement;
  final VoidCallback onTap;

  const _MovementRow({required this.movement, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final application = movement.application;
    final brightness = Theme.of(context).brightness;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final vacancy = application.vacante.trim();
    final status = application.estado.trim();

    return Semantics(
      button: true,
      label: '${application.empresa}. $status',
      child: InkWell(
        onTap: onTap,
        borderRadius: const BorderRadius.all(Radius.circular(AppRadius.chip)),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.xs,
            vertical: AppSpace.sm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      application.empresa,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpace.sm),
                  Text(
                    formatSinNovedad(movement.daysAgo),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: muted,
                        ),
                  ),
                  const SizedBox(width: AppSpace.xs),
                  Icon(
                    Icons.chevron_right,
                    size: 16,
                    color: muted,
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text.rich(
                TextSpan(
                  children: [
                    if (vacancy.isNotEmpty)
                      TextSpan(
                        text: vacancy,
                        style: TextStyle(color: muted),
                      ),
                    if (vacancy.isNotEmpty && status.isNotEmpty)
                      TextSpan(
                        text: ' · ',
                        style: TextStyle(color: muted),
                      ),
                    if (status.isNotEmpty)
                      TextSpan(
                        text: status,
                        style: TextStyle(
                          color: statusColor(status, brightness),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    if (vacancy.isEmpty && status.isEmpty)
                      TextSpan(
                        text: 'Sin detalle',
                        style: TextStyle(color: muted),
                      ),
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
