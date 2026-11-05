import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../helpers/network_error.dart';
import '../helpers/search.dart';
import '../models/job_application.dart';
import '../providers/app_state.dart';
import '../theme.dart';
import '../widgets/application_card.dart';
import '../widgets/offline_banner.dart';
import '../widgets/scroll_to_top_button.dart';
import '../widgets/wheel_refresh.dart';
import 'application_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  final _scrollCtrl = ScrollController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    context.read<AppState>().fetchApplications();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  bool get _hasQuery => _query.trim().isNotEmpty;

  void _clearQuery() {
    _controller.clear();
    setState(() => _query = '');
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final hasQuery = _hasQuery;
    final results = hasQuery
        ? searchApplications(state.applications, _query)
        : const <JobApplication>[];
    final showCount =
        hasQuery &&
        !(state.loading && state.applications.isEmpty) &&
        state.error == null;

    Widget body;
    if (state.loading && state.applications.isEmpty) {
      body = const Center(child: CircularProgressIndicator());
    } else if (state.error != null && state.applications.isEmpty) {
      body = ErrorStateView(
        message: state.error!,
        isOffline: isNetworkError(state.error!),
        onRetry: () =>
            context.read<AppState>().fetchApplications(forceRefresh: true),
      );
    } else if (!hasQuery) {
      body = const _SearchEmptyState(
        icon: Icons.search,
        title: 'Escribe para buscar',
        subtitle: 'Empresa, puesto, estado, ciudad, comentarios o enlace.',
      );
    } else if (results.isEmpty) {
      body = _SearchEmptyState(
        icon: Icons.search_off,
        title: 'Sin resultados para "${_query.trim()}"',
        subtitle: 'Prueba con otra palabra o revisa la ortografía.',
        actionLabel: 'Limpiar búsqueda',
        onAction: _clearQuery,
      );
    } else {
      body = ListView.separated(
        controller: _scrollCtrl,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.lg, vertical: AppSpace.sm),
        itemCount: results.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpace.sm),
        itemBuilder: (context, index) {
          final app = results[index];
          return ApplicationCard(
            application: app,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ApplicationDetailScreen(application: app),
              ),
            ),
          );
        },
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          textInputAction: TextInputAction.search,
          onSubmitted: (_) => FocusScope.of(context).unfocus(),
          onChanged: (v) => setState(() => _query = v),
          decoration: InputDecoration(
            hintText: 'Buscar empresa, puesto, estado...',
            border: InputBorder.none,
            suffixIcon: _query.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: _clearQuery,
                  )
                : null,
          ),
        ),
      ),
      body: Column(
        children: [
          if (state.offline)
            OfflineBanner(
              lastUpdated: state.cacheTimestamp,
              onRetry: () => state.fetchApplications(forceRefresh: true),
            ),
          if (showCount) _ResultCount(count: results.length),
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                WheelRefreshIndicator(
                  controller: _scrollCtrl,
                  onRefresh: () => state.fetchApplications(forceRefresh: true),
                  child: body,
                ),
                ScrollToTopButton(controller: _scrollCtrl),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Contador fijo de resultados, visible mientras hay una consulta.
class _ResultCount extends StatelessWidget {
  final int count;

  const _ResultCount({required this.count});

  @override
  Widget build(BuildContext context) {
    final label = count == 1 ? '1 resultado' : '$count resultados';
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.lg,
        AppSpace.sm,
        AppSpace.lg,
        0,
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          label,
          style: AppType.label(
            context,
          ).copyWith(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

/// Estado vacío del buscador: ayuda inicial o aviso de que no hubo coincidencias.
class _SearchEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _SearchEmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpace.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 48,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: AppSpace.md),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpace.sm),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: AppType.label(context),
            ),
            if (actionLabel != null) ...[
              const SizedBox(height: AppSpace.md),
              TextButton(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
