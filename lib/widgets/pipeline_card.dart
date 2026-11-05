import 'package:flutter/material.dart';

import '../helpers/pipeline.dart';
import '../theme.dart';

/// Tarjeta con la barra y la leyenda del pipeline. Cada etapa es tocable.
class PipelineCard extends StatelessWidget {
  final List<(PipelineStage, int)> segments;
  final ValueChanged<PipelineStage> onStageTap;

  const PipelineCard({
    super.key,
    required this.segments,
    required this.onStageTap,
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
            Text('Pipeline de postulaciones', style: AppType.section(context)),
            const SizedBox(height: 2),
            Text(
              'Toca una etapa para ver las postulaciones',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: muted,
                  ),
            ),
            const SizedBox(height: AppSpace.md),
            ClipRRect(
              borderRadius: const BorderRadius.all(
                Radius.circular(AppRadius.bar),
              ),
              child: Row(
                children: [
                  for (final (stage, count) in segments)
                    Expanded(
                      flex: count,
                      child: Container(
                        height: 10,
                        color: pipelineColor(stage.label, brightness),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpace.md),
            Wrap(
              spacing: AppSpace.md,
              runSpacing: AppSpace.xs + 2,
              children: [
                for (final (stage, count) in segments)
                  _StageLegendItem(
                    stage: stage,
                    count: count,
                    color: pipelineColor(stage.label, brightness),
                    onTap: () => onStageTap(stage),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StageLegendItem extends StatelessWidget {
  final PipelineStage stage;
  final int count;
  final Color color;
  final VoidCallback onTap;

  const _StageLegendItem({
    required this.stage,
    required this.count,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '${stage.label}: $count postulaciones',
      child: InkWell(
        onTap: onTap,
        borderRadius: const BorderRadius.all(Radius.circular(AppRadius.chip)),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.xs,
            vertical: 2,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: AppSpace.xs),
              Text(
                '${stage.label} $count',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
