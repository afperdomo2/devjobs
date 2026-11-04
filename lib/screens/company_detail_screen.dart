import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../helpers/company_stats.dart';
import '../helpers/date_formatter.dart';
import '../providers/app_state.dart';
import '../theme.dart';
import '../widgets/application_card.dart';
import '../widgets/meta_chip.dart';
import 'application_detail_screen.dart';

/// Detalle de una empresa: métricas agregadas, distribución de sus
/// postulaciones y acceso al listado de vacantes filtrado por empresa.
class CompanyDetailScreen extends StatelessWidget {
  final String nombre;

  const CompanyDetailScreen({super.key, required this.nombre});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final brightness = Theme.of(context).brightness;
    final apps = state.getByField('empresa', nombre);
    final statsList = companiesStats(apps);
    final stats = statsList.isEmpty ? null : statsList.first;

    if (stats == null) {
      return Scaffold(
        appBar: AppBar(title: Text(nombre)),
        body: const Center(child: Text('Sin datos para mostrar')),
      );
    }

    final ciudades = _unique(apps.map((a) => a.ciudad));
    final modalidades = _unique(apps.map((a) => a.modalidad));
    final plataformas = _unique(apps.map((a) => a.plataforma));

    return Scaffold(
      appBar: AppBar(title: Text(stats.nombre)),
      body: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          _HeaderCard(stats: stats),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Métricas', style: AppType.section(context)),
                  const SizedBox(height: AppSpace.md),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      const gap = AppSpace.md;
                      final columns = constraints.maxWidth >= 520 ? 3 : 2;
                      final tileWidth =
                          (constraints.maxWidth - gap * (columns - 1)) /
                              columns;
                      final metrics = <Widget>[
                        _Metric(
                          icon: Icons.notifications_active_outlined,
                          value: '${stats.activas}',
                          label: 'Activas',
                          color: tealColor(brightness),
                        ),
                        _Metric(
                          icon: Icons.check_circle_outline,
                          value: '${stats.conNovedad}/${stats.total}',
                          label: 'Respondieron',
                          color: infoColor(brightness),
                        ),
                        _Metric(
                          icon: Icons.flag_outlined,
                          value: '${stats.finalizadas}',
                          label: 'Finalizadas',
                          color: neutralColor(brightness),
                        ),
                        _Metric(
                          icon: Icons.record_voice_over_outlined,
                          value: '${stats.entrevistas}',
                          label: 'Entrevistas',
                          color: statusColor('entrevista', brightness),
                        ),
                        _Metric(
                          icon: Icons.label_important,
                          value: '${stats.porGestionar}',
                          label: 'Por gestionar',
                          color: gestionColor(brightness),
                        ),
                        if (stats.promedioDias != null)
                          _Metric(
                            icon: Icons.schedule,
                            value: formatDias(stats.promedioDias!),
                            label: 'Prom. cierre',
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                      ];
                      return Wrap(
                        spacing: gap,
                        runSpacing: gap,
                        children: [
                          for (final metric in metrics)
                            SizedBox(width: tileWidth, child: metric),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          if (ciudades.isNotEmpty ||
              modalidades.isNotEmpty ||
              plataformas.isNotEmpty) ...[
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Distribución', style: AppType.section(context)),
                    const SizedBox(height: AppSpace.md),
                    if (plataformas.isNotEmpty)
                      _ChipGroup(
                        icon: Icons.language,
                        label: 'Plataformas',
                        values: plataformas,
                      ),
                    if (ciudades.isNotEmpty)
                      _ChipGroup(
                        icon: Icons.location_on_outlined,
                        label: 'Ciudades',
                        values: ciudades,
                      ),
                    if (modalidades.isNotEmpty)
                      _ChipGroup(
                        icon: Icons.business_center,
                        label: 'Modalidades',
                        values: modalidades,
                      ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: AppSpace.xl),
          Text('Vacantes (${apps.length})', style: AppType.section(context)),
          const SizedBox(height: AppSpace.sm),
          for (final app in apps) ...[
            ApplicationCard(
              application: app,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ApplicationDetailScreen(application: app),
                ),
              ),
            ),
            const SizedBox(height: AppSpace.sm),
          ],
        ],
      ),
    );
  }

  static List<String> _unique(Iterable<String> values) {
    final seen = <String>{};
    final out = <String>[];
    for (final v in values) {
      final t = v.trim();
      if (t.isEmpty) continue;
      if (seen.add(t.toLowerCase())) out.add(t);
    }
    return out;
  }
}

class _HeaderCard extends StatelessWidget {
  final CompanyStats stats;

  const _HeaderCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final initial = stats.nombre.trim().isEmpty
        ? '?'
        : stats.nombre.trim().characters.first.toUpperCase();
    final totalLabel =
        '${stats.total} ${stats.total == 1 ? 'postulación' : 'postulaciones'}';
    final ultima = stats.ultimaPostulacion;
    final dias = ultima == null
        ? null
        : DateTime.now().difference(ultima).inDays;
    final subtitle = dias == null
        ? totalLabel
        : '$totalLabel · ${formatSinNovedad(dias < 0 ? 0 : dias)}';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Text(
                initial,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: scheme.primary,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stats.nombre,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: scheme.onSurfaceVariant),
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

class _Metric extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _Metric({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.md,
        vertical: AppSpace.sm,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius:
            const BorderRadius.all(Radius.circular(AppRadius.control)),
      ),
      child: Row(
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
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontSize: 11,
                        color: muted,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChipGroup extends StatelessWidget {
  final IconData icon;
  final String label;
  final List<String> values;

  const _ChipGroup({
    required this.icon,
    required this.label,
    required this.values,
  });

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: AppIconSize.chip, color: muted),
              const SizedBox(width: 6),
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontSize: 12,
                      color: muted,
                    ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.xs + 2),
          Wrap(
            spacing: AppSpace.xs + 2,
            runSpacing: AppSpace.xs + 2,
            children: [for (final v in values) MetaChip(icon: icon, label: v)],
          ),
        ],
      ),
    );
  }
}
