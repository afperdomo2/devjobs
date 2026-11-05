import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../helpers/activity.dart';
import '../helpers/distribution.dart';
import '../helpers/network_error.dart';
import '../helpers/pipeline.dart';
import '../helpers/salary_insights.dart';
import '../helpers/trends.dart';
import '../providers/app_state.dart';
import '../theme.dart';
import '../widgets/distribution_card.dart';
import '../widgets/monthly_trend_card.dart';
import '../widgets/offline_banner.dart';
import '../widgets/pipeline_card.dart';
import '../widgets/recent_activity_card.dart';
import '../widgets/salary_insights_card.dart';
import '../widgets/wheel_refresh.dart';
import 'application_detail_screen.dart';
import 'filtered_applications_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ScrollController _scrollCtrl = ScrollController();
  final ScrollController _errorScrollCtrl = ScrollController();

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
    _errorScrollCtrl.dispose();
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
    final movements = recentMovements(apps);
    final last7 = countApplicationsSince(apps, 7);
    final last30 = countApplicationsSince(apps, 30);
    final monthly = monthlyApplicationCounts(apps);
    final salaryGroups = salaryInsights(apps);
    final brightness = Theme.of(context).brightness;

    // Full-screen error when no data and fetch failed.
    if (state.error != null && apps.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refresh,
        child: WheelRefreshIndicator(
          controller: _errorScrollCtrl,
          onRefresh: _refresh,
          child: ListView(
            controller: _errorScrollCtrl,
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
              childAspectRatio: 1.8,
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
              const SizedBox(height: 8),
              PipelineCard(
                segments: pipelineSegments(apps),
                onStageTap: (stage) => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FilteredApplicationsScreen(
                      title: 'Pipeline · ${stage.label}',
                      selector: (apps) => applicationsInStage(apps, stage),
                      emptyMessage: 'No hay postulaciones en esta etapa',
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              _ConversionCard(
                conRespuesta: stats.conRespuesta,
                entrevistas: stats.entrevistas,
                finalizadas: stats.finalizadas,
                total: stats.total,
                conRespuestaColor: successColor(brightness),
                entrevistaColor: statusColor('entrevista', brightness),
                finalizadasColor: neutralColor(brightness),
              ),
              const SizedBox(height: 8),
              RecentActivityCard(
                movements: movements,
                last7: last7,
                last30: last30,
                onOpen: (app) => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        ApplicationDetailScreen(application: app),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              MonthlyTrendCard(counts: monthly),
              if (salaryGroups.isNotEmpty) ...[
                const SizedBox(height: 8),
                SalaryInsightsCard(groups: salaryGroups),
              ],
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

class _ConversionCard extends StatelessWidget {
  final int conRespuesta;
  final int entrevistas;
  final int finalizadas;
  final int total;
  final Color conRespuestaColor;
  final Color entrevistaColor;
  final Color finalizadasColor;

  const _ConversionCard({
    required this.conRespuesta,
    required this.entrevistas,
    required this.finalizadas,
    required this.total,
    required this.conRespuestaColor,
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
              label: 'Con respuesta',
              part: conRespuesta,
              total: total,
              color: conRespuestaColor,
            ),
            const SizedBox(height: AppSpace.md - 2),
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
