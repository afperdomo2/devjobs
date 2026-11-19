import 'package:flutter/material.dart';

import '../helpers/company_stats.dart';
import '../helpers/text_normalizer.dart';
import '../theme.dart';

/// Abre la hoja "Combinar empresas".
///
/// Devuelve el nombre final si el usuario confirmó el merge, o `null` si
/// canceló. [onMerge] debe renombrar las filas y lanzar si falla.
Future<String?> showMergeCompaniesSheet(
  BuildContext context, {
  required List<CompanyStats> companies,
  required Future<void> Function(String finalName, List<String> names) onMerge,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    builder: (_) => MergeCompaniesSheet(companies: companies, onMerge: onMerge),
  );
}

/// Selección múltiple de empresas + nombre final + vista previa de las filas
/// que se renombrarán en el Sheet.
///
/// La lista va en orden alfabético (las nombres similares quedan juntas) y
/// tiene buscador; la selección se conserva mientras se filtra.
class MergeCompaniesSheet extends StatefulWidget {
  final List<CompanyStats> companies;
  final Future<void> Function(String finalName, List<String> names) onMerge;

  const MergeCompaniesSheet({
    super.key,
    required this.companies,
    required this.onMerge,
  });

  @override
  State<MergeCompaniesSheet> createState() => _MergeCompaniesSheetState();
}

class _MergeCompaniesSheetState extends State<MergeCompaniesSheet> {
  final Set<String> _selected = {};
  final _searchCtrl = TextEditingController();
  String _query = '';
  String? _finalName;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  /// Empresas en orden alfabético (sin distinguir mayúsculas ni tildes).
  List<CompanyStats> get _sorted {
    final sorted = List<CompanyStats>.of(widget.companies);
    sorted.sort(
      (a, b) => normalizeText(a.nombre).compareTo(normalizeText(b.nombre)),
    );
    return sorted;
  }

  /// Lista visible: [ _sorted ] filtrada por el buscador.
  List<CompanyStats> get _visible {
    final query = normalizeText(_query);
    if (query.isEmpty) return _sorted;
    return [
      for (final company in _sorted)
        if (normalizeText(company.nombre).contains(query)) company,
    ];
  }

  CompanyStats? _statsOf(String name) {
    for (final company in widget.companies) {
      if (company.nombre == name) return company;
    }
    return null;
  }

  void _toggle(String name, bool checked) {
    setState(() {
      if (checked) {
        _selected.add(name);
        _finalName ??= name;
      } else {
        _selected.remove(name);
        if (_finalName == name) {
          _finalName = _selected.isEmpty ? null : _selected.first;
        }
      }
      _error = null;
    });
  }

  void _clearQuery() {
    _searchCtrl.clear();
    setState(() => _query = '');
  }

  /// Filas que cambiarían: las de las empresas seleccionadas cuyo nombre no
  /// es exactamente el final.
  List<CompanyStats> get _absorbed => [
        for (final name in _selected)
          if (name != _finalName) _statsOf(name),
      ].whereType<CompanyStats>().toList();

  int get _rowsToRename =>
      _absorbed.fold(0, (sum, company) => sum + company.total);

  Future<void> _confirm() async {
    final finalName = _finalName;
    if (finalName == null || _selected.length < 2 || _saving) return;

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.onMerge(finalName, _selected.toList());
      if (mounted) Navigator.pop(context, finalName);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = '$e'.replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final canMerge = _selected.length >= 2 && _finalName != null && !_saving;
    final visible = _visible;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: AppSpace.lg,
          right: AppSpace.lg,
          top: AppSpace.lg,
          bottom: MediaQuery.of(context).viewInsets.bottom + AppSpace.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Combinar empresas', style: AppType.section(context)),
            const SizedBox(height: AppSpace.xs),
            Text(
              'Marca las empresas que son la misma. Las postulaciones '
              'se renombrarán al nombre final en el Sheet.',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpace.md),
            TextField(
              key: const Key('merge-search'),
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _query = v),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                isDense: true,
                hintText: 'Buscar empresa...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: _clearQuery,
                      )
                    : null,
              ),
            ),
            const SizedBox(height: AppSpace.sm),
            Flexible(
              child: visible.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpace.xl,
                      ),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.search_off, size: 32),
                            const SizedBox(height: AppSpace.sm),
                            Text('Sin resultados para "$_query"'),
                            TextButton(
                              onPressed: _clearQuery,
                              child: const Text('Limpiar búsqueda'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView(
                      shrinkWrap: true,
                      children: [
                        for (final company in visible)
                          CheckboxListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            controlAffinity: ListTileControlAffinity.leading,
                            value: _selected.contains(company.nombre),
                            onChanged: _saving
                                ? null
                                : (checked) =>
                                    _toggle(company.nombre, checked ?? false),
                            title: Text(company.nombre),
                            subtitle: Text(
                              '${company.total} '
                              '${company.total == 1 ? 'postulación' : 'postulaciones'}',
                            ),
                          ),
                      ],
                    ),
            ),
            if (_selected.length >= 2) ...[
              const SizedBox(height: AppSpace.sm),
              DropdownButtonFormField<String>(
                key: ValueKey('merge-final-$_finalName'),
                initialValue: _finalName,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Nombre final'),
                items: [
                  for (final name in _selected)
                    DropdownMenuItem(value: name, child: Text(name)),
                ],
                onChanged: _saving
                    ? null
                    : (value) => setState(() {
                          _finalName = value;
                          _error = null;
                        }),
              ),
              const SizedBox(height: AppSpace.md),
              Text('Vista previa', style: AppType.label(context)),
              const SizedBox(height: AppSpace.xs),
              for (final company in _absorbed)
                Text(
                  '· "${company.nombre}" (${company.total} '
                  '${company.total == 1 ? 'fila' : 'filas'}) → "$_finalName"',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
            ],
            if (_error != null) ...[
              const SizedBox(height: AppSpace.sm),
              Text(
                _error!,
                style: TextStyle(
                  color: dangerColor(Theme.of(context).brightness),
                  fontSize: 13,
                ),
              ),
            ],
            const SizedBox(height: AppSpace.md),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: _saving ? null : () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: AppSpace.sm),
                Expanded(
                  child: FilledButton(
                    key: const Key('merge-confirm'),
                    onPressed: canMerge ? _confirm : null,
                    child: _saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            _rowsToRename == 0
                                ? 'Combinar'
                                : 'Combinar $_rowsToRename '
                                    '${_rowsToRename == 1 ? 'postulación' : 'postulaciones'}',
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
