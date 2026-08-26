import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_state.dart';
import '../models/job_application.dart';
import '../widgets/application_card.dart';
import 'application_detail_screen.dart';

class ApplicationsListScreen extends StatefulWidget {
  final String filterMode;

  const ApplicationsListScreen({super.key, required this.filterMode});

  @override
  State<ApplicationsListScreen> createState() => _ApplicationsListScreenState();
}

class _ApplicationsListScreenState extends State<ApplicationsListScreen> {
  int? _pulseRowIndex;
  int _pulseTrigger = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().fetchApplications();
    });
  }

  Future<void> _openDetail(JobApplication app) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ApplicationDetailScreen(application: app)),
    );
    if (!context.mounted) return;
    setState(() {
      _pulseRowIndex = app.rowIndex;
      _pulseTrigger++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final apps = state.getApplications(widget.filterMode);

    return RefreshIndicator(
      onRefresh: () => context.read<AppState>().fetchApplications(forceRefresh: true),
      child: state.loading && apps.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : state.error != null && apps.isEmpty
              ? Center(child: Text(state.error!, textAlign: TextAlign.center))
              : apps.isEmpty
                  ? ListView(children: const [_EmptyHint()])
                  : ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: apps.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final app = apps[index];
                        return ApplicationCard(
                          key: ValueKey(app.rowIndex),
                          application: app,
                          pulseTrigger: app.rowIndex == _pulseRowIndex
                              ? _pulseTrigger
                              : 0,
                          onTap: () => _openDetail(app),
                        );
                      },
                    ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 200,
      child: Center(child: Text('No se encontraron postulaciones')),
    );
  }
}
