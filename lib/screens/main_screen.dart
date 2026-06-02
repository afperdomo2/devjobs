import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_state.dart';
import '../helpers/date_formatter.dart';
import '../widgets/status_chip.dart';
import '../models/job_application.dart';
import 'application_detail_screen.dart';

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
              _DashboardTab(),
              _ApplicationsTab(filterMode: 'noRejected'),
              _ApplicationsTab(filterMode: 'onlyRejected'),
            ],
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: state.currentTab,
            onDestinationSelected: (i) => state.setTab(i),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: 'Inicio',
              ),
              NavigationDestination(
                icon: Icon(Icons.work_outline),
                selectedIcon: Icon(Icons.work),
                label: 'Postulaciones',
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

  static const _titles = ['DevJobs', 'Postulaciones', 'Rechazadas'];
}

class _DashboardTab extends StatefulWidget {
  const _DashboardTab();

  @override
  State<_DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<_DashboardTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().fetchApplications();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final stats = state.dashboardStats;

    return RefreshIndicator(
      onRefresh: () => context.read<AppState>().fetchApplications(forceRefresh: true),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          _StatCard(
            label: 'Total postulaciones',
            value: stats.total.toString(),
            color: Colors.blue,
            icon: Icons.work,
          ),
          const SizedBox(height: 8),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 1.6,
            children: [
              _StatCard(
                label: 'En revisión',
                value: stats.enRevision.toString(),
                color: Colors.orange,
                icon: Icons.visibility,
              ),
              _StatCard(
                label: 'Entrevistas',
                value: stats.entrevistas.toString(),
                color: Colors.purple,
                icon: Icons.people,
              ),
              _StatCard(
                label: 'Ofertas',
                value: stats.ofertas.toString(),
                color: Colors.green,
                icon: Icons.check_circle,
              ),
              _StatCard(
                label: 'Rechazadas',
                value: stats.rechazadas.toString(),
                color: Colors.red,
                icon: Icons.cancel,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: color),
                const Spacer(),
                Text(
                  value,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _ApplicationsTab extends StatefulWidget {
  final String filterMode;

  const _ApplicationsTab({required this.filterMode});

  @override
  State<_ApplicationsTab> createState() => _ApplicationsTabState();
}

class _ApplicationsTabState extends State<_ApplicationsTab> {
  String _search = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().fetchApplications();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final apps = state.getApplications(widget.filterMode);

    final q = _search.toLowerCase();
    final filtered = apps.where((a) {
      if (q.isEmpty) return true;
      return a.empresa.toLowerCase().contains(q) ||
          a.vacante.toLowerCase().contains(q) ||
          a.ciudad.toLowerCase().contains(q);
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            onChanged: (v) => setState(() => _search = v),
            decoration: InputDecoration(
              hintText: 'Buscar empresa, vacante, ciudad...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _search.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => setState(() => _search = ''),
                    )
                  : null,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => context.read<AppState>().fetchApplications(forceRefresh: true),
            child: state.loading && apps.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : state.error != null && apps.isEmpty
                ? Center(child: Text(state.error!, textAlign: TextAlign.center))
                : filtered.isEmpty
                ? ListView(children: const [_EmptyHint()])
                : ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final app = filtered[index];
                      return _ApplicationCard(
                        application: app,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ApplicationDetailScreen(application: app),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ),
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

class _ApplicationCard extends StatelessWidget {
  final JobApplication application;
  final VoidCallback onTap;

  const _ApplicationCard({required this.application, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      application.empresa,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                  StatusChip(status: application.estado),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                application.vacante,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: _InfoChip(icon: Icons.location_on, label: application.ciudad),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _InfoChip(
                            icon: Icons.business_center,
                            label: application.modalidad,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      formatDateShort(application.fechaPostulacion),
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey),
        const SizedBox(width: 2),
        Flexible(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}
