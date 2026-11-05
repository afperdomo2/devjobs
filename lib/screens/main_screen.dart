import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../helpers/agenda.dart';
import '../providers/app_state.dart';
import '../theme.dart';
import '../widgets/offline_banner.dart';
import '../widgets/theme_settings_sheet.dart';
import 'agenda_screen.dart';
import 'application_form_screen.dart';
import 'dashboard_screen.dart';
import 'empresas_screen.dart';
import 'postulaciones_screen.dart';
import 'search_screen.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (_, state, _) {
        final agenda = agendaCount(state.applications);
        return Scaffold(
          appBar: AppBar(
            title: Text(_titles[state.currentTab]),
            actions: [
              // El buscador global filtra postulaciones; oculto en Empresas,
              // que ya tiene su propio filtro por nombre de empresa.
              if (state.currentTab != _empresasTabIndex)
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SearchScreen()),
                  ),
                ),
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                tooltip: 'Ajustes',
                onPressed: () => showThemeSettingsSheet(context),
              ),
            ],
          ),
          body: Column(
            children: [
              if (state.offline)
                OfflineBanner(
                  lastUpdated: state.cacheTimestamp,
                  onRetry: () => state.fetchApplications(forceRefresh: true),
                ),
              Expanded(
                child: IndexedStack(
                  index: state.currentTab,
                  children: const [
                    DashboardScreen(),
                    PostulacionesScreen(),
                    EmpresasScreen(),
                    AgendaScreen(),
                  ],
                ),
              ),
            ],
          ),
          bottomNavigationBar: DecoratedBox(
            position: DecorationPosition.foreground,
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: navDividerColor(Theme.of(context).brightness),
                  width: 1,
                ),
              ),
            ),
            child: NavigationBar(
              selectedIndex: state.currentTab,
              onDestinationSelected: (i) => state.setTab(i),
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              destinations: [
                const NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home),
                  label: 'Inicio',
                ),
                const NavigationDestination(
                  icon: Icon(Icons.assignment_outlined),
                  selectedIcon: Icon(Icons.assignment),
                  label: 'Postulaciones',
                ),
                const NavigationDestination(
                  icon: Icon(Icons.business_outlined),
                  selectedIcon: Icon(Icons.business),
                  label: 'Empresas',
                ),
                NavigationDestination(
                  icon: _AgendaIcon(
                    icon: Icons.event_note_outlined,
                    count: agenda,
                  ),
                  selectedIcon: _AgendaIcon(
                    icon: Icons.event_note,
                    count: agenda,
                  ),
                  label: 'Agenda',
                ),
              ],
            ),
          ),
          floatingActionButton:
              state.currentTab == AppState.tabPostulaciones && !state.offline
              ? FloatingActionButton.extended(
                  heroTag: 'create-application',
                  onPressed: () => startCreateApplication(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Nueva'),
                )
              : null,
        );
      },
    );
  }

  static const _empresasTabIndex = AppState.tabEmpresas;

  static const _titles = ['DevJobs', 'Postulaciones', 'Empresas', 'Agenda'];
}

class _AgendaIcon extends StatelessWidget {
  final IconData icon;
  final int count;

  const _AgendaIcon({required this.icon, required this.count});

  @override
  Widget build(BuildContext context) {
    return Badge(
      isLabelVisible: count > 0,
      label: Text(count > 99 ? '99+' : '$count'),
      child: Icon(icon),
    );
  }
}
