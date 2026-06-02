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
              ApplicationsListScreen(filterMode: 'noRejected'),
              ApplicationsListScreen(filterMode: 'onlyRejected'),
            ],
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: state.currentTab,
            onDestinationSelected: (i) => state.setTab(i),
            destinations: const [
              NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Inicio'),
              NavigationDestination(icon: Icon(Icons.work_outline), selectedIcon: Icon(Icons.work), label: 'Postulaciones'),
              NavigationDestination(icon: Icon(Icons.cancel_outlined), selectedIcon: Icon(Icons.cancel), label: 'Rechazadas'),
            ],
          ),
        );
      },
    );
  }

  static const _titles = ['DevJobs', 'Postulaciones', 'Rechazadas'];
}
