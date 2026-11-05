import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../helpers/date_formatter.dart';
import '../helpers/network_error.dart';
import '../helpers/platform_stats.dart';
import '../providers/app_state.dart';
import '../theme.dart';
import '../widgets/offline_banner.dart';
import '../widgets/platform_sort_bar.dart';
import '../widgets/scroll_to_top_button.dart';
import '../widgets/wheel_refresh.dart';
import 'filtered_applications_screen.dart';

/// Listado de todas las plataformas (dominios del enlace) con el total de
/// postulaciones y la fecha de la última aplicación en cada una.
///
/// El orden por defecto es por volumen; también se puede ordenar por la
/// aplicación más reciente o por la más antigua.
class PlatformsScreen extends StatefulWidget {
  const PlatformsScreen({super.key});

  @override
  State<PlatformsScreen> createState() => _PlatformsScreenState();
}

class _PlatformsScreenState extends State<PlatformsScreen> {
  final ScrollController _scrollCtrl = ScrollController();
  PlatformSortMode _sortMode = PlatformSortMode.total;

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

  void _openPlatform(PlatformStats platform) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FilteredApplicationsScreen(
          title: 'Plataforma',
          field: 'plataforma',
          value: platform.nombre,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final apps = state.applications;
    final platforms = platformsStats(apps);
    final sorted = sortPlatforms(platforms, _sortMode);
    final sinEnlace = apps.where((a) => a.plataforma.trim().isEmpty).length;

    Widget content;
    if (state.loading && apps.isEmpty) {
      content = const Center(child: CircularProgressIndicator());
    } else if (state.error != null && apps.isEmpty) {
      content = ErrorStateView(
        message: state.error!,
        isOffline: isNetworkError(state.error!),
        onRetry: () =>
            context.read<AppState>().fetchApplications(forceRefresh: true),
      );
    } else if (platforms.isEmpty) {
      content = const _PlatformsEmptyContent();
    } else {
      content = ListView(
        controller: _scrollCtrl,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpace.lg,
          AppSpace.xs,
          AppSpace.lg,
          AppSpace.lg,
        ),
        children: [
          _SummaryCard(
            platforms: platforms,
            totalPostulaciones: platforms.fold<int>(
              0,
              (sum, p) => sum + p.total,
            ),
          ),
          const SizedBox(height: AppSpace.sm),
          Card(
            child: Column(
              children: [
                for (var i = 0; i < sorted.length; i++) ...[
                  _PlatformListRow(
                    platform: sorted[i],
                    onTap: () => _openPlatform(sorted[i]),
                  ),
                  if (i < sorted.length - 1)
                    const Divider(height: 1, indent: AppSpace.lg),
                ],
              ],
            ),
          ),
          if (sinEnlace > 0) ...[
            const SizedBox(height: AppSpace.sm),
            Text(
              '$sinEnlace '
              '${sinEnlace == 1 ? 'postulación no tiene' : 'postulaciones no tienen'} '
              'enlace y no se ${sinEnlace == 1 ? 'incluye' : 'incluyen'}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Plataformas')),
      body: Column(
        children: [
          if (state.offline)
            OfflineBanner(
              lastUpdated: state.cacheTimestamp,
              onRetry: () => context.read<AppState>().fetchApplications(
                forceRefresh: true,
              ),
            ),
          if (platforms.isNotEmpty)
            PlatformSortBar(
              selected: _sortMode,
              onSelected: (mode) => setState(() => _sortMode = mode),
            ),
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                RefreshIndicator(
                  onRefresh: _refresh,
                  child: WheelRefreshIndicator(
                    controller: _scrollCtrl,
                    onRefresh: _refresh,
                    child: content,
                  ),
                ),
                if (platforms.isNotEmpty)
                  ScrollToTopButton(controller: _scrollCtrl),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final List<PlatformStats> platforms;
  final int totalPostulaciones;

  const _SummaryCard({
    required this.platforms,
    required this.totalPostulaciones,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final count = platforms.length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.language,
                  size: AppIconSize.metric,
                  color: infoColor(brightness),
                ),
                const SizedBox(width: AppSpace.sm),
                Expanded(
                  child: Text(
                    '$count ${count == 1 ? 'plataforma' : 'plataformas'}',
                    style: AppType.section(context),
                  ),
                ),
                Text(
                  '$totalPostulaciones ${totalPostulaciones == 1 ? 'postulación' : 'postulaciones'}',
                  style: Theme.of(
                    context,
                  ).textTheme.labelMedium?.copyWith(color: muted),
                ),
              ],
            ),
            const SizedBox(height: AppSpace.xs),
            Text(
              'Revisa cuándo postulaste por última vez en cada una',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: muted),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlatformListRow extends StatelessWidget {
  final PlatformStats platform;
  final VoidCallback onTap;

  const _PlatformListRow({required this.platform, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final ultima = platform.ultimaPostulacion;
    final dias = platform.diasDesdeUltima(DateTime.now());
    final dateLabel = ultima == null
        ? 'Sin fecha de aplicación'
        : 'Última aplicación: ${formatDateValueShort(ultima)}';
    final relative = dias == null ? 'Sin fecha' : formatSinNovedad(dias);
    final totalLabel =
        '${platform.total} '
        '${platform.total == 1 ? 'postulación' : 'postulaciones'}';

    return Semantics(
      button: true,
      label: '${platform.nombre}. $dateLabel. $totalLabel',
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.lg,
            vertical: AppSpace.md,
          ),
          child: Row(
            children: [
              Icon(Icons.language, size: AppIconSize.row, color: muted),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      platform.nombre,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppType.cardTitle(context),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$dateLabel · $totalLabel',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: muted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpace.sm),
              Text(
                relative,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: muted),
              ),
              const SizedBox(width: AppSpace.xs),
              Icon(Icons.chevron_right, size: 16, color: muted),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlatformsEmptyContent extends StatelessWidget {
  const _PlatformsEmptyContent();

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.language, size: 48, color: muted),
            const SizedBox(height: AppSpace.md),
            Text(
              'Sin plataformas registradas',
              style: AppType.section(context),
            ),
            const SizedBox(height: AppSpace.xs),
            Text(
              'Agrega postulaciones con enlace para verlas aquí',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: muted),
            ),
          ],
        ),
      ),
    );
  }
}
