import 'package:flutter/material.dart';

import '../helpers/company_stats.dart';
import '../helpers/date_formatter.dart';
import '../models/job_application.dart';
import '../theme.dart';

/// Días de cierre hasta los cuales el promedio se marca verde (rápida).
const kRapidoCierreDias = 7;

/// Días de cierre a partir de los cuales el promedio se marca ámbar (lenta).
const kLentoCierreDias = 21;

/// Resumen glanceable de una empresa específica: promedio de cierre,
/// cuántas postulaciones respondieron y última postulación.
///
/// Pensado para mostrarse arriba del listado filtrado por empresa.
/// Cada dato se oculta si no está disponible; el color del promedio
/// siempre va acompañado de icono y texto (nunca solo color).
class CompanyInsightsCard extends StatelessWidget {
  /// Postulaciones ya filtradas por la empresa a resumir.
  final List<JobApplication> apps;

  const CompanyInsightsCard({super.key, required this.apps});

  /// Verde si cierra rápido, ámbar si tarda mucho, neutro en el medio.
  static Color _promedioTint(int dias, Brightness brightness, Color muted) {
    if (dias <= kRapidoCierreDias) return statusColor('aceptada', brightness);
    if (dias >= kLentoCierreDias) {
      return brightness == Brightness.dark
          ? AppColorsDark.warning
          : AppColors.warning;
    }
    return muted;
  }

  @override
  Widget build(BuildContext context) {
    final stats = companiesStats(apps);
    if (stats.isEmpty) return const SizedBox.shrink();
    final s = stats.first;

    final brightness = Theme.of(context).brightness;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;

    final items = <_InsightItem>[];

    final promedio = s.promedioDias;
    if (promedio != null) {
      items.add(_InsightItem(
        icon: Icons.schedule,
        value: formatDias(promedio),
        label: 'Prom. cierre',
        color: _promedioTint(promedio, brightness, muted),
      ));
    }

    items.add(_InsightItem(
      icon: Icons.check_circle_outline,
      value: '${s.conNovedad}/${s.total}',
      label: 'Respondieron',
      color: Theme.of(context).colorScheme.primary,
    ));

    final ultima = s.ultimaPostulacion;
    if (ultima != null) {
      final dias = DateTime.now().difference(ultima).inDays;
      items.add(_InsightItem(
        icon: Icons.calendar_today,
        label: 'Últ. postulación',
        value: formatSinNovedad(dias < 0 ? 0 : dias),
        color: muted,
      ));
    }

    final partes = <String>[
      if (s.activas > 0) '${s.activas} en proceso',
      if (s.finalizadas > 0)
        '${s.finalizadas} ${s.finalizadas == 1 ? 'cerrada' : 'cerradas'}',
    ];

    return Card(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          children: [
            Row(
              children: [
                for (final item in items) Expanded(child: _InsightItemView(item: item)),
              ],
            ),
            if (partes.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                partes.join(' · '),
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: muted),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InsightItem {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _InsightItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });
}

class _InsightItemView extends StatelessWidget {
  final _InsightItem item;

  const _InsightItemView({required this.item});

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(item.icon, size: 18, color: item.color),
        const SizedBox(height: 3),
        Text(
          item.value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: item.color,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          item.label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 11, color: muted),
        ),
      ],
    );
  }
}
