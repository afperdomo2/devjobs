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

  /// Confirma antes de gastar tokens y arranca el lote de análisis.
  ///
  /// El diálogo explica el costo (una llamada a la IA por empresa) y lista
  /// las empresas; solo "Analizar" dispara [AppState.analyzePendingCompanies].
  Future<void> _confirmAnalyzePending(AppState state) async {
    final pending = state.pendingAnalysisCompanies;
    if (pending.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          '¿Analizar ${pending.length} '
          '${pending.length == 1 ? 'empresa' : 'empresas'} con IA?',
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Se hará un análisis por cada empresa (${pending.length} '
              '${pending.length == 1 ? 'llamada' : 'llamadas'} a la IA). '
              'Puedes detenerlo cuando quieras; lo completado se guarda.',
            ),
            const SizedBox(height: AppSpace.md),
            Text('Se analizarán:', style: AppType.label(context)),
            const SizedBox(height: AppSpace.xs),
            for (final name in pending.take(3)) Text('· $name'),
            if (pending.length > 3) Text('… y ${pending.length - 3} más'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Analizar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    await state.analyzePendingCompanies();
    if (!mounted) return;

    final done = state.batchDone;
    final total = state.batchTotal;
    final error = state.batchError;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          error != null
              ? 'Se detuvo el análisis: $error ($done de $total completados)'
              : 'Análisis completados: $done de $total',
        ),
      ),
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
                if (state.batchRunning) ...[
                  const SizedBox(width: 6),
                  const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'Analizando ${state.batchCurrent ?? ''} '
                      '(${state.batchDone + 1} de ${state.batchTotal})…',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ),
                  TextButton(
                    key: const Key('analyze-stop'),
                    onPressed: state.stopBatchAnalysis,
                    child: const Text('Detener'),
                  ),
                ] else ...[
                  if (state.aiEnabled &&
                      !state.offline &&
                      state.pendingAnalysisCount > 0)
                    TextButton.icon(
                      key: const Key('analyze-pending'),
                      onPressed: () => _confirmAnalyzePending(state),
                      icon:
                          const Icon(Icons.auto_awesome, size: AppIconSize.row),
                      label: Text('Analizar (${state.pendingAnalysisCount})'),
                    ),
                  if (all.length >= 2 && !state.offline)
                    TextButton.icon(
                      key: const Key('merge-companies'),
                      onPressed: () => _openMerge(all),
                      icon: const Icon(Icons.merge_type, size: AppIconSize.row),
                      label: const Text('Combinar'),
                    ),
                ],
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

