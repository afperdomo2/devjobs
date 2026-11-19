import 'package:flutter/material.dart';

import '../helpers/company_stats.dart';
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
  String? _finalName;
  bool _saving = false;
  String? _error;

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
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final company in widget.companies)
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
