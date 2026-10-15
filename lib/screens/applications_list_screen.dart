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

class ApplicationsListScreen extends StatefulWidget {
  final String filterMode;

  const ApplicationsListScreen({super.key, required this.filterMode});

  @override
  State<ApplicationsListScreen> createState() => _ApplicationsListScreenState();
}

class _ApplicationsListScreenState extends State<ApplicationsListScreen> {
  final ScrollController _scrollCtrl = ScrollController();
  int? _pulseRowIndex;
  int _pulseTrigger = 0;

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

  Future<void> _openDetail(JobApplication app) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ApplicationDetailScreen(application: app),
      ),
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
    } else if (apps.isEmpty) {
      content = ListView(
        controller: _scrollCtrl,
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [_EmptyHint()],
      );
    } else {
      content = ListView.separated(
        controller: _scrollCtrl,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: apps.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final app = apps[index];
          return ApplicationCard(
            key: ValueKey(app.rowIndex),
            application: app,
            pulseTrigger: app.rowIndex == _pulseRowIndex ? _pulseTrigger : 0,
            onTap: () => _openDetail(app),
          );
        },
      );
    }

    // Show inline offline indicator when we have cached data but are offline.
    // MainScreen already shows a global banner, so avoid duplicating there
    // when used inside IndexedStack. Only show here if not inside MainScreen's banner context:
    // keep minimal placeholder to ensure offline is visible even if used standalone.
    return Stack(
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
        ScrollToTopButton(controller: _scrollCtrl),
      ],
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
