import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_state.dart';
import '../widgets/application_card.dart';
import 'application_detail_screen.dart';

class ApplicationsListScreen extends StatefulWidget {
  final String filterMode;

  const ApplicationsListScreen({super.key, required this.filterMode});

  @override
  State<ApplicationsListScreen> createState() => _ApplicationsListScreenState();
}

class _ApplicationsListScreenState extends State<ApplicationsListScreen> {
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
                              return ApplicationCard(
                                application: app,
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ApplicationDetailScreen(application: app),
                                  ),
                                ),
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
