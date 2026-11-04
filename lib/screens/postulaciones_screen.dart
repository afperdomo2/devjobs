import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_state.dart';
import '../widgets/applications_filter_bar.dart';
import 'applications_list_screen.dart';

/// Pestaña única de postulaciones: la lista completa con las pills de estado
/// (Todas / Activas / Enviadas / Finalizadas) encima.
class PostulacionesScreen extends StatelessWidget {
  const PostulacionesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final counts = {
      for (final spec in applicationFilters)
        spec.mode: state.countApplications(spec.mode),
    };

    return Column(
      children: [
        ApplicationsFilterBar(
          selected: state.applicationsFilter,
          counts: counts,
          onSelected: state.setApplicationsFilter,
        ),
        Expanded(
          child: ApplicationsListScreen(
            // Remonta la lista al cambiar de pill para que arranque arriba y
            // no herede el scroll (ni el pulse) del filtro anterior.
            key: ValueKey(state.applicationsFilter),
            filterMode: state.applicationsFilter,
          ),
        ),
      ],
    );
  }
}
