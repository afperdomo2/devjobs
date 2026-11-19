import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../helpers/date_formatter.dart';
import '../helpers/network_error.dart';
import '../helpers/platform_stats.dart';
import '../helpers/text_normalizer.dart';
import '../providers/app_state.dart';
import '../theme.dart';
import '../widgets/offline_banner.dart';
import '../widgets/platform_sort_bar.dart';
import '../widgets/scroll_to_top_button.dart';
import '../widgets/wheel_refresh.dart';
import 'platform_detail_screen.dart';

/// Listado de todas las plataformas (dominios del enlace) con el total de
/// postulaciones y la fecha de la última aplicación en cada una, y filtro
/// propio por nombre (insensible a mayúsculas y tildes).
///
/// El orden por defecto es por volumen; también se puede ordenar por la
/// aplicación más reciente o por la más antigua. Al tocar una plataforma se
/// abre [PlatformDetailScreen] con sus métricas y vacantes.
class PlatformsScreen extends StatefulWidget {
  const PlatformsScreen({super.key});

  @override
  State<PlatformsScreen> createState() => _PlatformsScreenState();
}

class _PlatformsScreenState extends State<PlatformsScreen> {
  final _searchCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  String _query = '';
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
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _refresh() {
    return context.read<AppState>().fetchApplications(forceRefresh: true);
  }

  void _clearQuery() {
    _searchCtrl.clear();
    setState(() => _query = '');
  }

  List<PlatformStats> _filter(List<PlatformStats> all) {
    final q = normalizeText(_query);
    if (q.isEmpty) return all;
    return all.where((p) => normalizeText(p.nombre).contains(q)).toList();
  }

  void _openPlatform(PlatformStats platform) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PlatformDetailScreen(nombre: platform.nombre),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final apps = state.applications;
    final platforms = platformsStats(apps);
    final sorted = sortPlatforms(_filter(platforms), _sortMode);
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
    } else if (sorted.isEmpty) {
      content = _SearchEmptyContent(query: _query, onClear: _clearQuery);
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
          // El resumen y el aviso de "sin enlace" son del listado completo:
          // se ocultan mientras se busca para no mezclarlos con los
          // resultados filtrados.
          if (_query.isEmpty) ...[
            _SummaryCard(
              platforms: platforms,
              totalPostulaciones: platforms.fold<int>(
                0,
                (sum, p) => sum + p.total,
              ),
            ),
            const SizedBox(height: AppSpace.sm),
          ],
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
          if (_query.isEmpty && sinEnlace > 0) ...[
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
          _SearchField(
            controller: _searchCtrl,
            query: _query,
            onChanged: (v) => setState(() => _query = v),
            onClear: _clearQuery,
          ),
          if (platforms.isNotEmpty)
            PlatformSortBar(
              selected: _sortMode,
              onSelected: (mode) => setState(() => _sortMode = mode),
            ),
          if (_query.isNotEmpty && sorted.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.lg,
                0,
                AppSpace.lg,
                AppSpace.xs,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${sorted.length} de ${platforms.length} '
                  '${platforms.length == 1 ? 'plataforma' : 'plataformas'}',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
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

/// Campo de búsqueda del listado de plataformas (mismo patrón visual que el
/// filtro por nombre de la pestaña Empresas).
class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final String query;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _SearchField({
    required this.controller,
    required this.query,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpace.md, AppSpace.sm, AppSpace.md, AppSpace.sm),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          isDense: true,
          hintText: 'Filtrar plataformas...',
          prefixIcon: const Icon(Icons.search, size: 20),
          suffixIcon: query.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 20),
                  onPressed: onClear,
                )
              : null,
          filled: true,
          fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          border: OutlineInputBorder(
            borderRadius: const BorderRadius.all(
                Radius.circular(AppRadius.control)),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
        ),
      ),
    );
  }
}

/// Estado vacío cuando la búsqueda no encuentra plataformas.
class _SearchEmptyContent extends StatelessWidget {
  final String query;
  final VoidCallback onClear;

  const _SearchEmptyContent({required this.query, required this.onClear});

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 48, color: muted),
            const SizedBox(height: AppSpace.md),
            Text(
              'Sin resultados para "$query"',
              textAlign: TextAlign.center,
              style: AppType.section(context),
            ),
            const SizedBox(height: AppSpace.xs),
            TextButton(
              onPressed: onClear,
              child: const Text('Limpiar búsqueda'),
            ),
          ],
        ),
      ),
    );
  }
}
