import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../helpers/trends.dart';
import '../theme.dart';

const _monthLabels = [
  'ene',
  'feb',
  'mar',
  'abr',
  'may',
  'jun',
  'jul',
  'ago',
  'sep',
  'oct',
  'nov',
  'dic',
];

/// Tarjeta de Inicio con las postulaciones de los últimos 6 meses.
class MonthlyTrendCard extends StatelessWidget {
  final List<MonthlyCount> counts;

  const MonthlyTrendCard({super.key, required this.counts});

  @override
  Widget build(BuildContext context) {
    if (counts.isEmpty) return const SizedBox.shrink();

    final brightness = Theme.of(context).brightness;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final color = tealColor(brightness);

    var maxCount = 0;
    var total = 0;
    for (final item in counts) {
      total += item.count;
      if (item.count > maxCount) maxCount = item.count;
    }

    final subtitle = total == 0
        ? 'Sin postulaciones en ${counts.length} meses'
        : 'Últimos ${counts.length} meses · $total postulaciones';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ritmo mensual', style: AppType.section(context)),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: muted,
                  ),
            ),
            const SizedBox(height: AppSpace.md),
            SizedBox(
              height: 126,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (final item in counts)
                    Expanded(
                      child: _MonthBar(
                        item: item,
                        maxCount: maxCount,
                        color: color,
                        muted: muted,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthBar extends StatelessWidget {
  final MonthlyCount item;
  final int maxCount;
  final Color color;
  final Color muted;

  const _MonthBar({
    required this.item,
    required this.maxCount,
    required this.color,
    required this.muted,
  });

  @override
  Widget build(BuildContext context) {
    final label = _monthLabels[item.month.month - 1];
    final hasData = item.count > 0;
    final barColor = hasData ? color : muted.withValues(alpha: 0.3);
    final barHeight = maxCount == 0
        ? 2.0
        : math.max(2.0, item.count / maxCount * 72);

    return Semantics(
      label: '$label: ${item.count} postulaciones',
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            '${item.count}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: hasData ? color : muted,
            ),
          ),
          const SizedBox(height: AppSpace.xs),
          Container(
            width: 24,
            height: barHeight,
            decoration: BoxDecoration(
              color: barColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppRadius.bar),
              ),
            ),
          ),
          const SizedBox(height: AppSpace.xs + 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: muted,
            ),
          ),
        ],
      ),
    );
  }
}
