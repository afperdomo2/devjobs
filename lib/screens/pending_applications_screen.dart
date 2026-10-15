import 'package:flutter/material.dart';

import 'applications_list_screen.dart';

/// Listado de las postulaciones marcadas "Por gestionar", abierto desde la
/// card del dashboard. Reutiliza el listado estándar con su propio Scaffold.
class PendingApplicationsScreen extends StatelessWidget {
  const PendingApplicationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Por gestionar')),
      body: const ApplicationsListScreen(filterMode: 'porGestionar'),
    );
  }
}
