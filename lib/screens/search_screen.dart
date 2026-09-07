import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../helpers/network_error.dart';
import '../models/job_application.dart';
import '../providers/app_state.dart';
import '../widgets/application_card.dart';
import '../widgets/offline_banner.dart';
import 'application_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    context.read<AppState>().fetchApplications();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<JobApplication> _filter(List<JobApplication> apps) {
    if (_query.isEmpty) return apps;
    final q = _query.toLowerCase();
    return apps.where((a) {
      if (a.empresa.toLowerCase().contains(q)) return true;
      if (a.vacante.toLowerCase().contains(q)) return true;
      if (a.ciudad.toLowerCase().contains(q)) return true;
      if (a.contacto.toLowerCase().contains(q)) return true;
      if (a.tipoContrato.toLowerCase().contains(q)) return true;
      if (a.modalidad.toLowerCase().contains(q)) return true;
      if (a.salarioOfrecido.toLowerCase().contains(q)) return true;
      if (a.descripcion.toLowerCase().contains(q)) return true;
      return false;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final results = _filter(state.applications);

    Widget body;
    if (state.loading && state.applications.isEmpty) {
      body = const Center(child: CircularProgressIndicator());
    } else if (state.error != null && state.applications.isEmpty) {
      body = ErrorStateView(
        message: state.error!,
        isOffline: isNetworkError(state.error!),
        onRetry: () => context.read<AppState>().fetchApplications(forceRefresh: true),
      );
    } else if (results.isEmpty) {
      body = Center(
        child: Text(
          _query.isEmpty ? 'Escribe para buscar' : 'Sin resultados para "$_query"',
        ),
      );
    } else {
      body = ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: results.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final app = results[index];
          return ApplicationCard(
            application: app,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ApplicationDetailScreen(application: app)),
            ),
          );
        },
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          onChanged: (v) => setState(() => _query = v),
          decoration: InputDecoration(
            hintText: 'Buscar en todas las postulaciones...',
            border: InputBorder.none,
            suffixIcon: _query.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _controller.clear();
                      setState(() => _query = '');
                    },
                  )
                : null,
          ),
        ),
      ),
      body: Column(
        children: [
          if (state.offline)
            OfflineBanner(
              lastUpdated: state.cacheTimestamp,
              onRetry: () => state.fetchApplications(forceRefresh: true),
            ),
          Expanded(child: body),
        ],
      ),
    );
  }
}
