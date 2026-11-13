import 'package:flutter/material.dart';

import '../helpers/date_formatter.dart';
import '../models/application_options.dart';
import '../theme.dart';

/// Resultado del diálogo "Cambiar estado". [nota] puede estar vacía.
class ChangeStatusResult {
  final String estado;
  final DateTime fecha;
  final String nota;
  final bool entrevistaRealizada;

  const ChangeStatusResult({
    required this.estado,
    required this.fecha,
    required this.nota,
    required this.entrevistaRealizada,
  });
}

/// Abre el diálogo "Cambiar estado" y devuelve la elección del usuario,
/// o null si cancela.
///
/// [fechaActual] es la última novedad registrada (`fechaSeguimiento`); se usa
/// para saber si algo cambió, no como fecha por defecto: un avance nuevo se
/// registra con la fecha de hoy. [today] permite fijarla en tests.
Future<ChangeStatusResult?> showChangeStatusDialog(
  BuildContext context, {
  required String empresa,
  required String vacante,
  required String estadoActual,
  required bool entrevistaRealizada,
  DateTime? fechaActual,
  DateTime? today,
}) {
  return showDialog<ChangeStatusResult>(
    context: context,
    builder: (_) => ChangeStatusDialog(
      empresa: empresa,
      vacante: vacante,
      estadoActual: estadoActual,
      entrevistaRealizada: entrevistaRealizada,
      fechaActual: fechaActual,
      today: today,
    ),
  );
}

/// Diálogo único para mover el estado de una postulación, con fecha y nota.
///
/// Reemplaza al antiguo "Finalizar proceso": los estados de cierre
/// ([applicationFinalStatuses]) son un grupo más del mismo selector, así que
/// también sirve para corregir un proceso ya finalizado.
class ChangeStatusDialog extends StatefulWidget {
  final String empresa;
  final String vacante;
  final String estadoActual;
  final bool entrevistaRealizada;
  final DateTime? fechaActual;
  final DateTime? today;

  const ChangeStatusDialog({
    super.key,
    required this.empresa,
    required this.vacante,
    required this.estadoActual,
    required this.entrevistaRealizada,
    this.fechaActual,
    this.today,
  });

  @override
  State<ChangeStatusDialog> createState() => _ChangeStatusDialogState();
}

class _ChangeStatusDialogState extends State<ChangeStatusDialog> {
  late final DateTime _today;
  late final DateTime _initialFecha;
  late DateTime _fecha;
  late String _estado;
  late bool _entrevista;
  final _notaCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _today = DateUtils.dateOnly(widget.today ?? DateTime.now());
    _initialFecha = DateUtils.dateOnly(widget.fechaActual ?? _today);
    _fecha = _today;
    _estado = widget.estadoActual.trim();
    _entrevista = widget.entrevistaRealizada;
    _notaCtrl.addListener(_onNotaChanged);
  }

  @override
  void dispose() {
    _notaCtrl.removeListener(_onNotaChanged);
    _notaCtrl.dispose();
    super.dispose();
  }

  void _onNotaChanged() => setState(() {});

  /// Sin cambios no se escribe en la hoja: el botón queda deshabilitado.
  bool get _canSave =>
      _estado != widget.estadoActual.trim() ||
      _fecha != _initialFecha ||
      _notaCtrl.text.trim().isNotEmpty ||
      _entrevista != widget.entrevistaRealizada;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime(2000),
      lastDate: _today,
      initialEntryMode: DatePickerEntryMode.calendarOnly,
      helpText: 'Fecha de la novedad',
    );
    if (picked == null || !mounted) return;
    setState(() => _fecha = DateUtils.dateOnly(picked));
  }

  void _submit() {
    if (!_canSave) return;
    Navigator.pop(
      context,
      ChangeStatusResult(
        estado: _estado,
        fecha: _fecha,
        nota: _notaCtrl.text.trim(),
        entrevistaRealizada: _entrevista,
      ),
    );
  }

  /// Estados en curso. Si el estado actual no existe en el catálogo (dato
  /// viejo o un valor escrito a mano en el Sheet) se agrega primero para no
  /// perderlo; los estados de cierre viven en su propio grupo.
  List<String> get _processStatuses {
    final values = applicationStatuses
        .where((estado) => !applicationFinalStatuses.contains(estado))
        .toList();
    final actual = widget.estadoActual.trim();
    if (actual.isNotEmpty && !applicationStatuses.contains(actual)) {
      values.insert(0, actual);
    }
    return values;
  }

  /// Estados de cierre, con el actual primero cuando ya está finalizada.
  List<String> get _finalStatuses {
    final actual = widget.estadoActual.trim();
    if (!applicationFinalStatuses.contains(actual)) {
      return applicationFinalStatuses;
    }
    return [
      actual,
      ...applicationFinalStatuses.where((estado) => estado != actual),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final subject = [
      widget.empresa.trim(),
      widget.vacante.trim(),
    ].where((value) => value.isNotEmpty).join(' · ');

    return AlertDialog(
      title: const Text('Cambiar estado'),
      scrollable: true,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (subject.isNotEmpty) ...[
            Text(
              subject,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: muted),
            ),
            const SizedBox(height: AppSpace.md),
          ],
          _GroupLabel('Estado'),
          const SizedBox(height: AppSpace.xs),
          _statusChips(context, _processStatuses, brightness),
          const SizedBox(height: AppSpace.md),
          _GroupLabel('Cerrar proceso'),
          const SizedBox(height: AppSpace.xs),
          _statusChips(context, _finalStatuses, brightness),
          const SizedBox(height: AppSpace.md),
          InkWell(
            key: const Key('status-dialog-fecha'),
            onTap: _pickDate,
            borderRadius: const BorderRadius.all(
              Radius.circular(AppRadius.control),
            ),
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Fecha de la novedad',
                suffixIcon: Icon(Icons.calendar_month),
              ),
              child: Text(formatDateValue(_fecha)),
            ),
          ),
          const SizedBox(height: AppSpace.md),
          TextField(
            key: const Key('status-dialog-nota'),
            controller: _notaCtrl,
            minLines: 3,
            maxLines: 5,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Nota (opcional)',
              hintText: 'Ej. Pasé a la entrevista técnica, acepté la oferta...',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: AppSpace.sm),
          CheckboxListTile(
            key: const Key('status-dialog-entrevista'),
            value: _entrevista,
            onChanged: (value) =>
                setState(() => _entrevista = value ?? false),
            title: const Text('Ya hice la entrevista'),
            subtitle: const Text('Solo marca que la entrevista ocurrió'),
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            dense: true,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _canSave ? _submit : null,
          child: const Text('Guardar'),
        ),
      ],
    );
  }

  Widget _statusChips(
    BuildContext context,
    List<String> estados,
    Brightness brightness,
  ) {
    return Wrap(
      spacing: AppSpace.sm,
      runSpacing: AppSpace.xs,
      children: [
        for (final estado in estados)
          ChoiceChip(
            label: Text(estado),
            selected: _estado == estado,
            showCheckmark: false,
            selectedColor: statusColor(
              estado,
              brightness,
            ).withValues(alpha: 0.2),
            side: BorderSide(
              color: _estado == estado
                  ? statusColor(estado, brightness)
                  : Theme.of(context).colorScheme.outlineVariant,
            ),
            onSelected: (_) => setState(() => _estado = estado),
          ),
      ],
    );
  }
}

class _GroupLabel extends StatelessWidget {
  final String text;

  const _GroupLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(text, style: AppType.label(context));
}
