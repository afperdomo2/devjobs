import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../helpers/network_error.dart';
import '../models/job_application.dart';
import '../providers/app_state.dart';
import '../theme.dart';
import '../widgets/application_card.dart';
import '../widgets/offline_banner.dart';
import '../widgets/scroll_to_top_button.dart';
import '../widgets/wheel_refresh.dart';
import 'application_detail_screen.dart';

class ApplicationsListScreen extends StatefulWidget {
  final String filterMode;

  /// Reserva espacio inferior para que el botón "ir arriba" no quede debajo
  /// del FAB de "Nueva postulación".
  final bool hasFloatingAction;

  /// Acción del estado vacío. Null cuando no aplica o no hay conexión.
  final VoidCallback? onCreate;

  const ApplicationsListScreen({
    super.key,
    required this.filterMode,
    this.hasFloatingAction = false,
    this.onCreate,
  });

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

  String get _emptyMessage {
    switch (widget.filterMode) {
      case AppState.filterActivas:
        return 'No hay postulaciones activas';
      case AppState.filterEnviadas:
        return 'No hay postulaciones enviadas';
      case AppState.filterFinalizadas:
        return 'No hay postulaciones finalizadas';
      case AppState.filterPorGestionar:
        return 'No hay postulaciones por gestionar';
      default:
        return 'No se encontraron postulaciones';
    }
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
    } else {
      final isEmpty = apps.isEmpty;
      content = ListView.separated(
        controller: _scrollCtrl,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          AppSpace.lg,
          AppSpace.sm,
          AppSpace.lg,
          widget.hasFloatingAction ? 88 : AppSpace.sm,
        ),
        itemCount: isEmpty ? 1 : apps.length,
        separatorBuilder: (_, _) =>
            isEmpty ? const SizedBox.shrink() : const SizedBox(height: AppSpace.sm),
        itemBuilder: (context, index) {
          if (isEmpty) {
            return _EmptyHint(
              message: _emptyMessage,
              onCreate: widget.onCreate,
            );
          }
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
        ScrollToTopButton(
          controller: _scrollCtrl,
          bottom: widget.hasFloatingAction ? 88 : 16,
        ),
      ],
    );
  }
}

class _EmptyHint extends StatelessWidget {
  final String message;
  final VoidCallback? onCreate;

  const _EmptyHint({required this.message, this.onCreate});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 240,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            if (onCreate != null) ...[
              const SizedBox(height: AppSpace.lg),
              FilledButton.icon(
                onPressed: onCreate,
                icon: const Icon(Icons.add),
                label: const Text('Crear postulación'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
