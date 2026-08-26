import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../helpers/date_formatter.dart';
import '../models/job_application.dart';
import '../providers/app_state.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().fetchApplications();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final stats = state.dashboardStats;
    final apps = state.applications;

    return RefreshIndicator(
      onRefresh: () => context.read<AppState>().fetchApplications(forceRefresh: true),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 1.6,
            children: [
              _StatCard(
                label: 'Total postulaciones',
                value: stats.total.toString(),
                color: Colors.blue,
                icon: Icons.work,
              ),
              _StatCard(
                label: 'Activas',
                value: stats.activas.toString(),
                color: Colors.orange,
                icon: Icons.notifications_active,
                onTap: () => state.setTab(1),
              ),
              _StatCard(
                label: 'Entrevistas',
                value: stats.entrevistas.toString(),
                color: Colors.purple,
                icon: Icons.people,
              ),
              _StatCard(
                label: 'Rechazadas',
                value: stats.rechazadas.toString(),
                color: Colors.red,
                icon: Icons.cancel,
                onTap: () => state.setTab(3),
              ),
            ],
          ),
          if (stats.total > 0) ...[
            const SizedBox(height: 8),
            _PipelineCard(segments: _pipelineSegments(apps)),
            const SizedBox(height: 8),
            _ConversionCard(
              entrevistas: stats.entrevistas,
              rechazadas: stats.rechazadas,
              total: stats.total,
            ),
            const SizedBox(height: 8),
            _RecentActivityCard(
              ultimos7: _countSince(apps, 7),
              ultimos30: _countSince(apps, 30),
            ),
            const SizedBox(height: 8),
            _DistributionCard(
              modalidades: _topBy(apps, (a) => a.modalidad, 3),
              ciudades: _topBy(apps, (a) => a.ciudad, 3),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  final VoidCallback? onTap;

  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final card = Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: color),
                const Spacer(),
                Text(
                  value,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Text(label, style: Theme.of(context).textTheme.bodySmall),
                ),
                if (onTap != null)
                  Icon(Icons.chevron_right, size: 16, color: Colors.grey[400]),
              ],
            ),
          ],
        ),
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: card,
      );
    }

    return card;
  }
}

int _countSince(List<JobApplication> apps, int days) {
  final cutoff = DateTime.now().subtract(Duration(days: days));
  var count = 0;
  for (final a in apps) {
    final d = parseDate(a.fechaPostulacion);
    if (d != null && !d.isBefore(cutoff)) count++;
  }
  return count;
}

List<(String, int)> _topBy(
  List<JobApplication> apps,
  String Function(JobApplication) field,
  int n,
) {
  final counts = <String, int>{};
  for (final a in apps) {
    final v = field(a).trim();
    if (v.isEmpty) continue;
    counts[v] = (counts[v] ?? 0) + 1;
  }
  final entries = counts.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  return entries.take(n).map((e) => (e.key, e.value)).toList();
}

class _PipelineStage {
  final String label;
  final Color color;
  final bool Function(String estado) matches;

  const _PipelineStage(this.label, this.color, this.matches);
}

final _pipelineStages = <_PipelineStage>[
  _PipelineStage('Enviada', Colors.blue, (e) => e.contains('enviada')),
  _PipelineStage('Sin respuesta', Colors.amber, (e) => e == 'sin respuesta'),
  _PipelineStage(
    'En revisión',
    Colors.orange,
    (e) => e.contains('revisión') || e.contains('revision'),
  ),
  _PipelineStage('Prueba técnica', Colors.teal, (e) => e.contains('prueba')),
  _PipelineStage('Entrevista', Colors.purple, (e) => e.contains('entrevista')),
  _PipelineStage('Oferta', Colors.green, (e) => e.contains('oferta')),
  _PipelineStage('Aceptada', Colors.lightGreen, (e) => e == 'aceptada'),
  _PipelineStage('Rechazada', Colors.red, (e) => e.contains('rechazada')),
  _PipelineStage('Retirada', Colors.blueGrey, (e) => e.contains('retirada')),
  _PipelineStage('Otros', Colors.grey, (_) => true),
];

_PipelineStage _stageOf(String estado) {
  final e = estado.trim().toLowerCase();
  for (final st in _pipelineStages) {
    if (st.matches(e)) return st;
  }
  return _pipelineStages.last;
}

List<(_PipelineStage, int)> _pipelineSegments(List<JobApplication> apps) {
  final counts = <String, int>{};
  for (final a in apps) {
    final label = _stageOf(a.estado).label;
    counts[label] = (counts[label] ?? 0) + 1;
  }
  return [
    for (final st in _pipelineStages)
      if (counts.containsKey(st.label)) (st, counts[st.label]!),
  ];
}

class _PipelineCard extends StatelessWidget {
  final List<(_PipelineStage, int)> segments;

  const _PipelineCard({required this.segments});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pipeline de postulaciones',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: Row(
                children: [
                  for (final (stage, count) in segments)
                    Expanded(
                      flex: count,
                      child: Container(height: 10, color: stage.color),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 6,
              children: [
                for (final (stage, count) in segments)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: stage.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${stage.label} $count',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ConversionCard extends StatelessWidget {
  final int entrevistas;
  final int rechazadas;
  final int total;

  const _ConversionCard({
    required this.entrevistas,
    required this.rechazadas,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tasa de conversión',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            _ConversionBar(
              label: 'A entrevista',
              part: entrevistas,
              total: total,
              color: Colors.purple,
            ),
            const SizedBox(height: 10),
            _ConversionBar(
              label: 'Rechazadas',
              part: rechazadas,
              total: total,
              color: Colors.red,
            ),
          ],
        ),
      ),
    );
  }
}

class _ConversionBar extends StatelessWidget {
  final String label;
  final int part;
  final int total;
  final Color color;

  const _ConversionBar({
    required this.label,
    required this.part,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final pct = total == 0 ? 0.0 : part / total;
    return Row(
      children: [
        SizedBox(
          width: 96,
          child: Text(label, style: Theme.of(context).textTheme.bodySmall),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 8,
              backgroundColor: color.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 40,
          child: Text(
            '${(pct * 100).round()}%',
            textAlign: TextAlign.right,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

class _RecentActivityCard extends StatelessWidget {
  final int ultimos7;
  final int ultimos30;

  const _RecentActivityCard({required this.ultimos7, required this.ultimos30});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Postulaciones recientes',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _ActivityItem(
                    icon: Icons.today,
                    label: 'Últimos 7 días',
                    value: '$ultimos7',
                    color: Colors.teal,
                  ),
                ),
                Expanded(
                  child: _ActivityItem(
                    icon: Icons.calendar_month,
                    label: 'Últimos 30 días',
                    value: '$ultimos30',
                    color: Colors.lightGreen,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _ActivityItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ],
    );
  }
}

class _DistributionCard extends StatelessWidget {
  final List<(String, int)> modalidades;
  final List<(String, int)> ciudades;

  const _DistributionCard({
    required this.modalidades,
    required this.ciudades,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
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
            _DistributionGroup(
              label: 'Modalidades',
              icon: Icons.business_center,
              items: modalidades,
              color: Colors.teal,
            ),
            const SizedBox(height: 16),
            _DistributionGroup(
              label: 'Ciudades',
              icon: Icons.location_on_outlined,
              items: ciudades,
              color: Colors.indigo,
            ),
          ],
        ),
      ),
    );
  }
}

class _DistributionGroup extends StatelessWidget {
  final String label;
  final IconData icon;
  final List<(String, int)> items;
  final Color color;

  const _DistributionGroup({
    required this.label,
    required this.icon,
    required this.items,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final maxCount = items.isEmpty
        ? 1
        : items.map((e) => e.$2).reduce((a, b) => a > b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(color: Colors.grey[700], fontSize: 13),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (items.isEmpty)
          Text('—', style: TextStyle(color: Colors.grey[400]))
        else
          for (final (name, count) in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '$count',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: count / maxCount,
                      minHeight: 6,
                      backgroundColor: color.withValues(alpha: 0.12),
                      valueColor: AlwaysStoppedAnimation(color),
                    ),
                  ),
                ],
              ),
            ),
      ],
    );
  }
}
