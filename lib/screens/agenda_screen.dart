import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../helpers/agenda.dart';
import '../helpers/application_sort.dart';
import '../helpers/network_error.dart';
import '../models/job_application.dart';
import '../providers/app_state.dart';
import '../theme.dart';
import '../widgets/agenda_section_card.dart';
import '../widgets/offline_banner.dart';
import '../widgets/scroll_to_top_button.dart';
import '../widgets/wheel_refresh.dart';
import 'application_detail_screen.dart';
import 'filtered_applications_screen.dart';
import 'pending_applications_screen.dart';

/// Pestaña Agenda: lo que necesita atención hoy, en secciones accionables.
class AgendaScreen extends StatefulWidget {
  const AgendaScreen({super.key});

  @override
  State<AgendaScreen> createState() => _AgendaScreenState();
}

class _AgendaScreenState extends State<AgendaScreen> {
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

  void _openDetail(JobApplication application) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ApplicationDetailScreen(application: application),
      ),
    );
  }

  void _openAll(AgendaSectionKind kind) {
    if (kind == AgendaSectionKind.porGestionar) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const PendingApplicationsScreen(),
        ),
      );
      return;
    }

    final title = agendaSectionTitle(kind);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FilteredApplicationsScreen(
          title: title,
          selector: (apps) => sortApplications(
            apps.where((app) => isInAgendaSection(app, kind)),
          ),
          emptyMessage: 'Sin ${title.toLowerCase()}',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final apps = state.applications;
    final sections = agendaSections(
      apps,
    ).where((section) => section.applications.isNotEmpty).toList();
    final count = agendaCount(apps);

    Widget content;
    if (state.loading && apps.isEmpty) {
      content = const Center(child: CircularProgressIndicator());
    } else if (state.error != null && apps.isEmpty) {
      content = ErrorStateView(
        message: state.error!,
        isOffline: isNetworkError(state.error!),
        onRetry: () => context.read<AppState>().fetchApplications(
          forceRefresh: true,
        ),
      );
    } else {
      final children = <Widget>[
        if (sections.isEmpty)
          const SizedBox(
            height: 320,
            child: _AgendaEmptyContent(),
          )
        else ...[
          Text(
            '$count ${count == 1 ? 'pendiente' : 'pendientes'}',
            style: AppType.section(context),
          ),
          const SizedBox(height: 2),
          Text(
            'Lo que necesita atención hoy',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: AppSpace.md),
          for (var i = 0; i < sections.length; i++) ...[
            AgendaSectionCard(
              section: sections[i],
              onOpen: _openDetail,
              onSeeAll: () => _openAll(sections[i].kind),
            ),
            if (i < sections.length - 1) const SizedBox(height: AppSpace.sm),
          ],
        ],
      ];
      content = ListView(
        controller: _scrollCtrl,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpace.lg),
        children: children,
      );
    }

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

class _AgendaEmptyContent extends StatelessWidget {
  const _AgendaEmptyContent();

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 48,
            color: successColor(Theme.of(context).brightness),
          ),
          const SizedBox(height: AppSpace.md),
          Text('Todo al día', style: AppType.section(context)),
          const SizedBox(height: AppSpace.xs),
          Text(
            'No hay pendientes por atender',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: muted,
                ),
          ),
        ],
      ),
    );
  }
}
