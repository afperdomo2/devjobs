import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../helpers/company_stats.dart';
import '../helpers/date_formatter.dart';
import '../helpers/network_error.dart';
import '../providers/app_state.dart';
import '../theme.dart';
import '../widgets/meta_chip.dart';
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

  List<CompanyStats> _filter(List<CompanyStats> all) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return all;
    return all.where((c) => c.nombre.toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final all = companiesStats(state.applications);
    final companies = _filter(all);

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
    } else if (companies.isEmpty) {
      content = ListView(
        controller: _scrollCtrl,
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: 220,
            child: Center(
              child: Text(
                _query.isEmpty
                    ? 'Sin empresas para mostrar'
                    : 'Sin resultados para "$_query"',
              ),
            ),
          ),
        ],
      );
    } else {
      content = ListView.separated(
        controller: _scrollCtrl,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
            AppSpace.lg, AppSpace.xs, AppSpace.lg, AppSpace.sm),
        itemCount: companies.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpace.sm),
        itemBuilder: (context, index) {
          final company = companies[index];
          return _CompanyCard(
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
          onClear: () {
            _searchCtrl.clear();
            setState(() => _query = '');
          },
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

class _CompanyCard extends StatelessWidget {
  final CompanyStats company;
  final VoidCallback onTap;

  const _CompanyCard({required this.company, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final muted = scheme.onSurfaceVariant;
    final brightness = Theme.of(context).brightness;

    final chips = <Widget>[
      MetaChip(
        icon: Icons.notifications_active_outlined,
        label:
            '${company.activas} ${company.activas == 1 ? 'activa' : 'activas'}',
        color: tealColor(brightness),
      ),
      MetaChip(
        icon: Icons.check_circle_outline,
        label: '${company.conNovedad}/${company.total} respondieron',
        color: infoColor(brightness),
      ),
    ];

    final ultima = company.ultimaPostulacion;
    if (ultima != null) {
      final dias = DateTime.now().difference(ultima).inDays;
      chips.add(MetaChip(
        icon: Icons.schedule,
        label: formatSinNovedad(dias < 0 ? 0 : dias),
      ));
    }

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius:
            const BorderRadius.all(Radius.circular(AppRadius.card)),
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _CompanyAvatar(nombre: company.nombre),
                  const SizedBox(width: AppSpace.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          company.nombre,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppType.cardTitle(context),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${company.total} '
                          '${company.total == 1 ? 'postulación' : 'postulaciones'}',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: muted),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: scheme.primary),
                ],
              ),
              const SizedBox(height: AppSpace.md - 2),
              Wrap(
                spacing: AppSpace.xs + 2,
                runSpacing: AppSpace.xs + 2,
                children: chips,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompanyAvatar extends StatelessWidget {
  final String nombre;

  const _CompanyAvatar({required this.nombre});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final initial = nombre.trim().isEmpty
        ? '?'
        : nombre.trim().characters.first.toUpperCase();
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Text(
        initial,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          color: scheme.primary,
        ),
      ),
    );
  }
}
