import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../helpers/company_stats.dart';
import '../helpers/date_formatter.dart';
import '../providers/app_state.dart';
import '../widgets/application_card.dart';
import '../widgets/meta_chip.dart';
import 'application_detail_screen.dart';
import 'filtered_applications_screen.dart';

/// Detalle de una empresa: métricas agregadas, distribución de sus
/// postulaciones y acceso al listado de vacantes filtrado por empresa.
class CompanyDetailScreen extends StatelessWidget {
  final String nombre;

  const CompanyDetailScreen({super.key, required this.nombre});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final apps = state.getByField('empresa', nombre);
    final statsList = companiesStats(apps);
    final stats = statsList.isEmpty ? null : statsList.first;

    if (stats == null) {
      return Scaffold(
        appBar: AppBar(title: Text(nombre)),
        body: const Center(child: Text('Sin datos para mostrar')),
      );
    }

    final entrevistas = apps.where((a) => a.entrevistaRealizada).length;
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
                  const Text(
                    'Métricas',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 20,
                    runSpacing: 16,
                    children: [
                      _Metric(
                        icon: Icons.notifications_active_outlined,
                        value: '${stats.activas}',
                        label: 'Activas',
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                      _Metric(
                        icon: Icons.check_circle_outline,
                        value: '${stats.conNovedad}/${stats.total}',
                        label: 'Respondieron',
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      _Metric(
                        icon: Icons.flag_outlined,
                        value: '${stats.finalizadas}',
                        label: 'Finalizadas',
                        color: Theme.of(context).colorScheme.error,
                      ),
                      _Metric(
                        icon: Icons.record_voice_over_outlined,
                        value: '$entrevistas',
                        label: 'Entrevistas',
                        color: Theme.of(context).colorScheme.tertiary,
                      ),
                      if (stats.promedioDias != null)
                        _Metric(
                          icon: Icons.schedule,
                          value: formatDias(stats.promedioDias!),
                          label: 'Prom. cierre',
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                    ],
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
                    const Text(
                      'Distribución',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
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
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => FilteredApplicationsScreen(
                  title: 'Empresa',
                  field: 'empresa',
                  value: stats.nombre,
                ),
              ),
            ),
            icon: const Icon(Icons.list_alt),
            label: const Text('Ver vacantes de esta empresa'),
          ),
          const SizedBox(height: 20),
          Text(
            'Vacantes (${apps.length})',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
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
            const SizedBox(height: 8),
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
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${stats.total} '
                    '${stats.total == 1 ? 'postulación' : 'postulaciones'}',
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
    return SizedBox(
      width: 76,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11, color: muted),
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
              Icon(icon, size: 14, color: muted),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(fontSize: 12, color: muted),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [for (final v in values) MetaChip(icon: icon, label: v)],
          ),
        ],
      ),
    );
  }
}
