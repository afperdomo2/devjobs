import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_state.dart';
import 'dashboard_screen.dart';
import 'applications_list_screen.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (_, state, _) {
        return Scaffold(
          appBar: AppBar(title: Text(_titles[state.currentTab])),
          body: IndexedStack(
            index: state.currentTab,
            children: const [
              DashboardScreen(),
              ApplicationsListScreen(filterMode: 'activas'),
              ApplicationsListScreen(filterMode: 'pendientes'),
              ApplicationsListScreen(filterMode: 'onlyRejected'),
            ],
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: state.currentTab,
            onDestinationSelected: (i) => state.setTab(i),
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: 'Inicio',
              ),
              NavigationDestination(
                icon: Icon(Icons.notifications_active_outlined),
                selectedIcon: Icon(Icons.notifications_active),
                label: 'Activas',
              ),
              NavigationDestination(
                icon: Icon(Icons.schedule_outlined),
                selectedIcon: Icon(Icons.schedule),
                label: 'Sin novedad',
              ),
              NavigationDestination(
                icon: Icon(Icons.cancel_outlined),
                selectedIcon: Icon(Icons.cancel),
                label: 'Rechazadas',
              ),
            ],
          ),
        );
      },
    );
  }

  static const _titles = ['DevJobs', 'Activas', 'Sin novedad', 'Rechazadas'];
}
