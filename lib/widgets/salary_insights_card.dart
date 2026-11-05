import 'package:flutter/material.dart';

import '../helpers/salary_formatter.dart';
import '../helpers/salary_insights.dart';
import '../theme.dart';

/// Tarjeta de Inicio con promedio y rango salarial por moneda.
class SalaryInsightsCard extends StatelessWidget {
  final List<SalaryGroup> groups;

  const SalaryInsightsCard({super.key, required this.groups});

  @override
  Widget build(BuildContext context) {
    if (groups.isEmpty) return const SizedBox.shrink();

    final brightness = Theme.of(context).brightness;
    final color = tealColor(brightness);
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Salario ofrecido', style: AppType.section(context)),
            const SizedBox(height: AppSpace.md),
            if (groups.length == 1)
              _SingleCurrencyRow(
                group: groups.first,
                color: color,
                muted: muted,
              )
            else
              _CurrencyTable(
                groups: groups,
                color: color,
                muted: muted,
              ),
          ],
        ),
      ),
    );
  }
}

class _SingleCurrencyRow extends StatelessWidget {
  final SalaryGroup group;
  final Color color;
  final Color muted;

  const _SingleCurrencyRow({
    required this.group,
    required this.color,
    required this.muted,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpace.md,
      runSpacing: AppSpace.xs,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          '${group.currency.label} (${group.count})',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: muted,
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              formatCompactSalary(group.average),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: color,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(width: AppSpace.xs),
            Text(
              'promedio',
              style: TextStyle(fontSize: 11, color: muted),
            ),
          ],
        ),
        Text(
          'Rango ${_rangeText(group)}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 11,
            color: muted,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

class _CurrencyTable extends StatelessWidget {
  final List<SalaryGroup> groups;
  final Color color;
  final Color muted;

  const _CurrencyTable({
    required this.groups,
    required this.color,
    required this.muted,
  });

  @override
  Widget build(BuildContext context) {
    final headerStyle = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      color: muted,
    );

    return Table(
      columnWidths: const {
        0: FlexColumnWidth(1.05),
        1: FlexColumnWidth(0.95),
        2: FlexColumnWidth(1.5),
      },
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        TableRow(
          children: [
            Text('Moneda', style: headerStyle),
            Text('Promedio', textAlign: TextAlign.right, style: headerStyle),
            Text('Rango', textAlign: TextAlign.right, style: headerStyle),
          ],
        ),
        for (final group in groups)
          TableRow(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: AppSpace.xs + 2),
                child: Text(
                  '${group.currency.label} (${group.count})',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: muted,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: AppSpace.xs + 2),
                child: Text(
                  formatCompactSalary(group.average),
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: color,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: AppSpace.xs + 2),
                child: Text(
                  _rangeText(group),
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: muted,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }
}

String _rangeText(SalaryGroup group) {
  final min = formatCompactSalary(group.min);
  final max = formatCompactSalary(group.max);
  return group.min == group.max ? min : '$min – $max';
}
