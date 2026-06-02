import 'package:flutter/material.dart';

import '../models/job_application.dart';
import '../services/sheets_api_service.dart';
import '../widgets/status_chip.dart';
import 'application_detail_screen.dart';

class ApplicationsListScreen extends StatefulWidget {
  final SheetsApiService apiService;

  const ApplicationsListScreen({super.key, required this.apiService});

  @override
  State<ApplicationsListScreen> createState() => _ApplicationsListScreenState();
}

class _ApplicationsListScreenState extends State<ApplicationsListScreen> {
  List<JobApplication>? _all;
  List<JobApplication>? _filtered;
  bool _loading = true;
  String? _error;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final apps = await widget.apiService.fetchAll();
      if (mounted) {
        setState(() {
          _all = apps;
          _applyFilter();
          _loading = false;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  void _applyFilter() {
    final q = _search.toLowerCase();
    _filtered = _all
        ?.where(
          (a) =>
              a.empresa.toLowerCase().contains(q) ||
              a.vacante.toLowerCase().contains(q) ||
              a.ciudad.toLowerCase().contains(q) ||
              a.estado.toLowerCase().contains(q),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Postulaciones'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              onChanged: (v) {
                _search = v;
                _applyFilter();
                setState(() {});
              },
              decoration: InputDecoration(
                hintText: 'Buscar empresa, vacante, ciudad...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _search.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _search = '';
                          _applyFilter();
                          setState(() {});
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          Expanded(child: _buildList()),
        ],
      ),
    );
  }

  Widget _buildList() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(child: Text(_error!, textAlign: TextAlign.center));
    }
    if (_filtered == null || _filtered!.isEmpty) {
      return const Center(child: Text('No se encontraron postulaciones'));
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: _filtered!.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final app = _filtered![index];
        return _ApplicationCard(
          application: app,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ApplicationDetailScreen(
                  apiService: widget.apiService,
                  application: app,
                ),
              ),
            ).then((_) => _load());
          },
        );
      },
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
                  _InfoChip(icon: Icons.location_on, label: application.ciudad),
                  const SizedBox(width: 8),
                  _InfoChip(icon: Icons.business_center, label: application.modalidad),
                  const Spacer(),
                  Text(
                    application.fechaPostulacion,
                    style: Theme.of(context).textTheme.bodySmall,
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
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
