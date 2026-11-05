import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../helpers/company_stats.dart';
import '../helpers/network_error.dart';
import '../providers/app_state.dart';
import '../theme.dart';
import '../widgets/company_card.dart';
import '../widgets/company_sort_bar.dart';
import '../widgets/offline_banner.dart';
import '../widgets/scroll_to_top_button.dart';
import '../widgets/wheel_refresh.dart';
import 'company_detail_screen.dart';

/// Listado de todas las empresas con postulaciones, con filtro propio por
/// nombre (independiente del buscador global de postulaciones).
class EmpresasScreen extends StatefulWidget {
  const EmpresasScreen({super.key});

  @override
  State<EmpresasScreen> createState() => _EmpresasScreenState();
}

class _EmpresasScreenState extends State<EmpresasScreen> {
  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  String _query = '';
  CompanySortMode _sortMode = CompanySortMode.total;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().fetchApplications();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _refresh() {
    return context.read<AppState>().fetchApplications(forceRefresh: true);
  }

  void _clearQuery() {
    _searchCtrl.clear();
    setState(() => _query = '');
  }

  List<CompanyStats> _filter(List<CompanyStats> all) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return all;
    return all.where((c) => c.nombre.toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final all = companiesStats(state.applications);
    final companies = sortCompanies(_filter(all), _sortMode);

    Widget content;
    if (state.loading && all.isEmpty) {
      content = const Center(child: CircularProgressIndicator());
    } else if (state.error != null && all.isEmpty) {
      content = ErrorStateView(
        message: state.error!,
        isOffline: isNetworkError(state.error!),
        onRetry: () =>
            context.read<AppState>().fetchApplications(forceRefresh: true),
      );
    } else {
      final isEmpty = companies.isEmpty;
      content = ListView.separated(
        controller: _scrollCtrl,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
            AppSpace.lg, AppSpace.xs, AppSpace.lg, AppSpace.sm),
        itemCount: isEmpty ? 1 : companies.length,
        separatorBuilder: (_, _) =>
            isEmpty ? const SizedBox.shrink() : const SizedBox(height: AppSpace.sm),
        itemBuilder: (context, index) {
          if (isEmpty) {
            final muted = Theme.of(context).colorScheme.onSurfaceVariant;
            return SizedBox(
              height: 260,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _query.isEmpty
                          ? Icons.business_outlined
                          : Icons.search_off,
                      size: 40,
                      color: muted,
                    ),
                    const SizedBox(height: AppSpace.sm),
                    Text(
                      _query.isEmpty
                          ? 'Sin empresas para mostrar'
                          : 'Sin resultados para "$_query"',
                      textAlign: TextAlign.center,
                    ),
                    if (_query.isNotEmpty) ...[
                      const SizedBox(height: AppSpace.xs),
                      TextButton(
                        onPressed: _clearQuery,
                        child: const Text('Limpiar búsqueda'),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }

          final company = companies[index];
          return CompanyCard(
            company: company,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CompanyDetailScreen(nombre: company.nombre),
              ),
            ),
          );
        },
      );
    }

    return Column(
      children: [
        _SearchField(
          controller: _searchCtrl,
          query: _query,
          onChanged: (v) => setState(() => _query = v),
          onClear: _clearQuery,
        ),
        if (all.isNotEmpty)
          CompanySortBar(
            selected: _sortMode,
            onSelected: (mode) => setState(() => _sortMode = mode),
          ),
        if (companies.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpace.lg,
              0,
              AppSpace.lg,
              AppSpace.xs,
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _query.isEmpty
                    ? '${companies.length} '
                        '${companies.length == 1 ? 'empresa' : 'empresas'}'
                    : '${companies.length} de ${all.length} empresas',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ),
          ),
        Expanded(
          child: Stack(
            fit: StackFit.expand,
            children: [
              WheelRefreshIndicator(
                controller: _scrollCtrl,
                onRefresh: _refresh,
                child: content,
              ),
              ScrollToTopButton(controller: _scrollCtrl),
            ],
          ),
        ),
      ],
    );
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final String query;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _SearchField({
    required this.controller,
    required this.query,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpace.md, AppSpace.sm, AppSpace.md, AppSpace.sm),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          isDense: true,
          hintText: 'Filtrar empresas...',
          prefixIcon: const Icon(Icons.search, size: 20),
          suffixIcon: query.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 20),
                  onPressed: onClear,
                )
              : null,
          filled: true,
          fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          border: OutlineInputBorder(
            borderRadius: const BorderRadius.all(
                Radius.circular(AppRadius.control)),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
        ),
      ),
    );
  }
}

