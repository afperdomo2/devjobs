import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../helpers/company_stats.dart';
import '../helpers/network_error.dart';
import '../models/company_insight.dart';
import '../providers/app_state.dart';
import '../theme.dart';
import '../widgets/company_card.dart';
import '../widgets/company_sort_bar.dart';
import '../widgets/filter_pill.dart';
import '../widgets/merge_companies_sheet.dart';
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
  String _behavior = _behaviorAll;
  CompanySortMode _sortMode = CompanySortMode.total;

  /// Filtro por defecto: sin restricción de comportamiento.
  static const _behaviorAll = 'todas';

  /// Filtros de comportamiento (selección única). Los ids que no son
  /// especiales coinciden con los ids de etiquetas del análisis IA.
  static const _behaviors = <(String, String, IconData)>[
    (_behaviorAll, 'Todas', Icons.apps_outlined),
    ('con-analisis', 'Con análisis', Icons.auto_awesome),
    ('priorizar', 'Priorizar', Icons.star_outline),
    ('no-respuesta', 'No responde', Icons.notifications_off_outlined),
    ('con-feedback', 'Da feedback', Icons.forum_outlined),
    ('sin-feedback', 'Sin feedback', Icons.sms_failed_outlined),
    (
      'vacantes-estancadas',
      'Vacantes estancadas',
      Icons.pause_circle_outline,
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = context.read<AppState>();
      state.fetchApplications();
      state.loadCompanyInsights();
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

  void _clearFilters() {
    _searchCtrl.clear();
    setState(() {
      _query = '';
      _behavior = _behaviorAll;
    });
  }

  bool get _hasFilters => _query.trim().isNotEmpty || _behavior != _behaviorAll;

  bool _matchesBehavior(CompanyInsight? insight) {
    switch (_behavior) {
      case _behaviorAll:
        return true;
      case 'con-analisis':
        return insight != null;
      case 'priorizar':
        return insight?.recomendacion == CompanyRecommendation.priorizar;
      default:
        return insight?.etiquetas.contains(_behavior) ?? false;
    }
  }

  /// Abre la hoja "Combinar empresas" y avisa al terminar.
  Future<void> _openMerge(List<CompanyStats> all) async {
    final finalName = await showMergeCompaniesSheet(
      context,
      companies: all,
      onMerge: (finalName, names) => context.read<AppState>().mergeCompanies(
        finalName: finalName,
        names: names,
      ),
    );
    if (finalName == null || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Postulaciones combinadas en "$finalName"')),
    );
  }

  List<CompanyStats> _filter(List<CompanyStats> all, AppState state) {
    final q = _query.trim().toLowerCase();
    return all.where((c) {
      if (q.isNotEmpty && !c.nombre.toLowerCase().contains(q)) return false;
      return _matchesBehavior(state.insightFor(c.nombre));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final all = companiesStats(state.applications);
    final companies = sortCompanies(
      _filter(all, state),
      _sortMode,
      insightFor: state.insightFor,
    );

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
                      _hasFilters ? Icons.search_off : Icons.business_outlined,
                      size: 40,
                      color: muted,
                    ),
                    const SizedBox(height: AppSpace.sm),
                    Text(
                      !_hasFilters
                          ? 'Sin empresas para mostrar'
                          : (_query.trim().isNotEmpty
                              ? 'Sin resultados para "$_query"'
                              : 'Sin empresas con este comportamiento'),
                      textAlign: TextAlign.center,
                    ),
                    if (_hasFilters) ...[
                      const SizedBox(height: AppSpace.xs),
                      TextButton(
                        onPressed: _clearFilters,
                        child: const Text('Limpiar filtros'),
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
            insight: state.insightFor(company.nombre),
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
          SizedBox(
            height: 44,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpace.lg,
                vertical: AppSpace.xs,
              ),
              child: Row(
                children: [
                  for (var i = 0; i < _behaviors.length; i++) ...[
                    FilterPill(
                      label: _behaviors[i].$2,
                      icon: _behaviors[i].$3,
                      selected: _behaviors[i].$1 == _behavior,
                      onTap: () =>
                          setState(() => _behavior = _behaviors[i].$1),
                      semanticLabel: 'Filtrar por ${_behaviors[i].$2}',
                    ),
                    if (i < _behaviors.length - 1)
                      const SizedBox(width: AppSpace.sm),
                  ],
                ],
              ),
            ),
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
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    !_hasFilters
                        ? '${companies.length} '
                            '${companies.length == 1 ? 'empresa' : 'empresas'}'
                        : '${companies.length} de ${all.length} empresas',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ),
                if (all.length >= 2 && !state.offline)
                  TextButton.icon(
                    key: const Key('merge-companies'),
                    onPressed: () => _openMerge(all),
                    icon: const Icon(Icons.merge_type, size: AppIconSize.row),
                    label: const Text('Combinar'),
                  ),
              ],
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

