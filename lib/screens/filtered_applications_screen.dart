import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../helpers/network_error.dart';
import '../models/job_application.dart';
import '../providers/app_state.dart';
import '../widgets/application_card.dart';
import '../widgets/company_insights_card.dart';
import '../widgets/offline_banner.dart';
import '../widgets/wheel_refresh.dart';
import 'application_detail_screen.dart';

class FilteredApplicationsScreen extends StatefulWidget {
  final String title;
  final String field;
  final String value;

  const FilteredApplicationsScreen({
    super.key,
    required this.title,
    required this.field,
    required this.value,
  });

  @override
  State<FilteredApplicationsScreen> createState() =>
      _FilteredApplicationsScreenState();
}

class _FilteredApplicationsScreenState
    extends State<FilteredApplicationsScreen> {
  final ScrollController _scrollCtrl = ScrollController();

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
    final apps = state.getByField(widget.field, widget.value);

    return Scaffold(
      appBar: AppBar(title: Text('${widget.title} · ${widget.value}')),
      body: state.loading && apps.isEmpty
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
          ? const Center(child: Text('No se encontraron postulaciones'))
          : WheelRefreshIndicator(
              controller: _scrollCtrl,
              onRefresh: _refresh,
              child: Column(
                children: [
                  // Resumen de métricas solo al filtrar por empresa.
                  if (widget.field == 'empresa')
                    CompanyInsightsCard(apps: apps),
                  Expanded(
                    child: ListView.separated(
                      controller: _scrollCtrl,
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      itemCount: apps.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final app = apps[index];
                        return ApplicationCard(
                          application: app,
                          onTap: () => _openDetail(context, app),
                        );
                      },
                    ),
                  ),
                ],
              ),
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
