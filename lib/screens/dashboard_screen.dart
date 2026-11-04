import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../helpers/date_formatter.dart';
import '../helpers/distribution.dart';
import '../helpers/network_error.dart';
import '../models/job_application.dart';
import '../providers/app_state.dart';
import '../theme.dart';
import '../widgets/distribution_card.dart';
import '../widgets/offline_banner.dart';
import '../widgets/pending_applications_card.dart';
import '../widgets/wheel_refresh.dart';
import 'application_detail_screen.dart';
import 'pending_applications_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ScrollController _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().fetchApplications();
    });
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _refresh() {
    return context.read<AppState>().fetchApplications(forceRefresh: true);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final stats = state.dashboardStats;
    final apps = state.applications;
    final pending = state.getApplications(AppState.filterPorGestionar);
    final brightness = Theme.of(context).brightness;

    // Full-screen error when no data and fetch failed.
    if (state.error != null && apps.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refresh,
        child: WheelRefreshIndicator(
          controller: _scrollCtrl,
          onRefresh: _refresh,
          child: ListView(
            controller: _scrollCtrl,
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.6,
                child: ErrorStateView(
                  message: state.error!,
                  isOffline: isNetworkError(state.error!),
                  onRetry: () => context.read<AppState>().fetchApplications(
                    forceRefresh: true,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (state.loading && apps.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: WheelRefreshIndicator(
        controller: _scrollCtrl,
        onRefresh: _refresh,
        child: ListView(
          controller: _scrollCtrl,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1.9,
              children: [
                _StatCard(
                  label: 'Total postulaciones',
                  value: stats.total.toString(),
                  color: infoColor(brightness),
                  icon: Icons.work,
                ),
                _StatCard(
                  label: 'Activas',
                  value: stats.activas.toString(),
                  color: tealColor(brightness),
                  icon: Icons.notifications_active,
                  onTap: () => state.openApplications(AppState.filterActivas),
                ),
                _StatCard(
                  label: 'Con entrevista',
                  value: stats.entrevistas.toString(),
                  color: statusColor('entrevista', brightness),
                  icon: Icons.record_voice_over_outlined,
                ),
                _StatCard(
                  label: 'Finalizadas',
                  value: stats.finalizadas.toString(),
                  color: neutralColor(brightness),
                  icon: Icons.check_circle,
                  onTap: () => state.openApplications(AppState.filterFinalizadas),
                ),
              ],
            ),
            if (stats.total > 0) ...[
              if (pending.isNotEmpty) ...[
                const SizedBox(height: 8),
                PendingApplicationsCard(
                  applications: pending,
                  onSeeAll: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PendingApplicationsScreen(),
                    ),
                  ),
                  onOpen: (app) => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          ApplicationDetailScreen(application: app),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 8),
              _PipelineCard(segments: _pipelineSegments(apps)),
              const SizedBox(height: 8),
              _ConversionCard(
                entrevistas: stats.entrevistas,
                finalizadas: stats.finalizadas,
                total: stats.total,
                entrevistaColor: statusColor('entrevista', brightness),
                finalizadasColor: neutralColor(brightness),
              ),
              const SizedBox(height: 8),
              _RecentActivityCard(
                ultimos7: _countSince(apps, 7),
                ultimos30: _countSince(apps, 30),
                color7: tealColor(brightness),
                color30: successColor(brightness),
              ),
              const SizedBox(height: 8),
              DistributionCard(
                plataformas: topDistribution(apps, (a) => a.plataforma, 3),
                modalidades: topDistribution(apps, (a) => a.modalidad, 3),
                ciudades: topDistribution(apps, (a) => a.ciudad, 3),
                colorPlataformas: tealColor(brightness),
                colorModalidades: indigoColor(brightness),
                colorCiudades: infoColor(brightness),
              ),
            ],
          ],
        ),
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
        padding: const EdgeInsets.all(AppSpace.sm + 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Icon(icon, size: AppIconSize.chip + 2, color: color),
                const Spacer(),
                Text(
                  value,
                  style: AppType.metric(context).copyWith(color: color),
                ),
              ],
            ),
            const SizedBox(height: AppSpace.xs),
            Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                if (onTap != null)
                  Icon(
                    Icons.chevron_right,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              ],
            ),
          ],
        ),
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius:
            const BorderRadius.all(Radius.circular(AppRadius.card)),
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

class _PipelineStage {
  final String label;
  final bool Function(String estado) matches;

  const _PipelineStage(this.label, this.matches);
}

final _pipelineStages = <_PipelineStage>[
  _PipelineStage('Sin respuesta', (e) => e == 'sin respuesta'),
  _PipelineStage(
    'En revisión',
    (e) => e.contains('revisión') || e.contains('revision'),
  ),
  _PipelineStage('Prueba técnica', (e) => e.contains('prueba')),
  _PipelineStage('Entrevista', (e) => e.contains('entrevista')),
  _PipelineStage('Oferta', (e) => e.contains('oferta')),
  _PipelineStage('Aceptada', (e) => e == 'aceptada'),
  _PipelineStage('Enviada', (e) => e.contains('enviada')),
  _PipelineStage('Rechazada', (e) => e.contains('rechazada')),
  _PipelineStage('Retirada', (e) => e.contains('retirada')),
  _PipelineStage('Otros', (_) => true),
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
    final brightness = Theme.of(context).brightness;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pipeline de postulaciones', style: AppType.section(context)),
            const SizedBox(height: AppSpace.md),
            ClipRRect(
              borderRadius:
                  const BorderRadius.all(Radius.circular(AppRadius.bar)),
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
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: pipelineColor(stage.label, brightness),
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
  final int finalizadas;
  final int total;
  final Color entrevistaColor;
  final Color finalizadasColor;

  const _ConversionCard({
    required this.entrevistas,
    required this.finalizadas,
    required this.total,
    required this.entrevistaColor,
    required this.finalizadasColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tasa de conversión', style: AppType.section(context)),
            const SizedBox(height: AppSpace.md),
            _ConversionBar(
              label: 'A entrevista',
              part: entrevistas,
              total: total,
              color: entrevistaColor,
            ),
            const SizedBox(height: AppSpace.md - 2),
            _ConversionBar(
              label: 'Finalizadas',
              part: finalizadas,
              total: total,
              color: finalizadasColor,
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
            borderRadius:
                const BorderRadius.all(Radius.circular(AppRadius.bar)),
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
            style: AppType.section(context),
          ),
        ),
      ],
    );
  }
}

class _RecentActivityCard extends StatelessWidget {
  final int ultimos7;
  final int ultimos30;
  final Color color7;
  final Color color30;

  const _RecentActivityCard({
    required this.ultimos7,
    required this.ultimos30,
    required this.color7,
    required this.color30,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Postulaciones recientes', style: AppType.section(context)),
            const SizedBox(height: AppSpace.md),
            Row(
              children: [
                Expanded(
                  child: _ActivityItem(
                    icon: Icons.today,
                    label: 'Últimos 7 días',
                    value: '$ultimos7',
                    color: color7,
                  ),
                ),
                Expanded(
                  child: _ActivityItem(
                    icon: Icons.calendar_month,
                    label: 'Últimos 30 días',
                    value: '$ultimos30',
                    color: color30,
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
        Icon(icon, size: AppIconSize.metric, color: color),
        const SizedBox(width: AppSpace.sm),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
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
