import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../helpers/network_error.dart';
import '../models/job_application.dart';
import '../providers/app_state.dart';
import '../widgets/application_card.dart';
import '../widgets/offline_banner.dart';
import '../widgets/scroll_to_top_button.dart';
import '../widgets/wheel_refresh.dart';
import 'application_detail_screen.dart';

class FilteredApplicationsScreen extends StatefulWidget {
  final String title;
  final String? field;
  final String? value;

  /// Alternativa a [field]/[value]: una función que recibe todas las
  /// postulaciones y devuelve el subconjunto ya ordenado.
  final List<JobApplication> Function(List<JobApplication> apps)? selector;

  /// Texto cuando no hay resultados.
  final String emptyMessage;

  const FilteredApplicationsScreen({
    super.key,
    required this.title,
    this.field,
    this.value,
    this.selector,
    this.emptyMessage = 'No se encontraron postulaciones',
  }) : assert(selector != null || (field != null && value != null));

  @override
  State<FilteredApplicationsScreen> createState() =>
      _FilteredApplicationsScreenState();
}

class _FilteredApplicationsScreenState
    extends State<FilteredApplicationsScreen> {
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
    final apps = widget.selector != null
        ? widget.selector!(state.applications)
        : state.getByField(widget.field!, widget.value!);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.value == null
              ? widget.title
              : '${widget.title} · ${widget.value}',
        ),
      ),
      body: Column(
        children: [
          if (state.offline)
            OfflineBanner(
              lastUpdated: state.cacheTimestamp,
              onRetry: () => context.read<AppState>().fetchApplications(
                forceRefresh: true,
              ),
            ),
          Expanded(
            child: state.loading && apps.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : state.error != null && apps.isEmpty
                ? ErrorStateView(
                    message: state.error!,
                    isOffline: isNetworkError(state.error!),
                    onRetry: () => context.read<AppState>().fetchApplications(
                      forceRefresh: true,
                    ),
                  )
                : apps.isEmpty
                ? Center(child: Text(widget.emptyMessage))
                : Stack(
                    fit: StackFit.expand,
                    children: [
                      RefreshIndicator(
                        onRefresh: _refresh,
                        child: WheelRefreshIndicator(
                          controller: _scrollCtrl,
                          onRefresh: _refresh,
                          child: ListView.separated(
                            controller: _scrollCtrl,
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            itemCount: apps.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final app = apps[index];
                              return ApplicationCard(
                                application: app,
                                onTap: () => _openDetail(context, app),
                              );
                            },
                          ),
                        ),
                      ),
                      ScrollToTopButton(controller: _scrollCtrl),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  void _openDetail(BuildContext context, JobApplication app) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ApplicationDetailScreen(application: app),
      ),
    );
  }
}
