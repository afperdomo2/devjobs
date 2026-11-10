import 'package:flutter/material.dart';

import '../helpers/date_formatter.dart';
import '../models/application_options.dart';
import '../theme.dart';

/// Resultado del diálogo de finalización. [nota] puede estar vacía.
class FinalizeApplicationResult {
  final String estado;
  final DateTime fecha;
  final String nota;

  const FinalizeApplicationResult({
    required this.estado,
    required this.fecha,
    required this.nota,
  });
}

/// Abre el diálogo "Finalizar proceso" y devuelve la elección del usuario,
/// o null si cancela.
///
/// [today] permite fijar la fecha por defecto en tests; en producción se usa
/// la fecha actual del dispositivo.
Future<FinalizeApplicationResult?> showFinalizeApplicationDialog(
  BuildContext context, {
  required String empresa,
  required String vacante,
  DateTime? today,
}) {
  return showDialog<FinalizeApplicationResult>(
    context: context,
    builder: (_) => FinalizeApplicationDialog(
      empresa: empresa,
      vacante: vacante,
      today: today,
    ),
  );
}

class FinalizeApplicationDialog extends StatefulWidget {
  final String empresa;
  final String vacante;
  final DateTime? today;

  const FinalizeApplicationDialog({
    super.key,
    required this.empresa,
    required this.vacante,
    this.today,
  });

  @override
  State<FinalizeApplicationDialog> createState() =>
      _FinalizeApplicationDialogState();
}

class _FinalizeApplicationDialogState extends State<FinalizeApplicationDialog> {
  late final DateTime _today;
  late DateTime _fecha;
  final _notaCtrl = TextEditingController();
  String? _estado;

  @override
  void initState() {
    super.initState();
    _today = DateUtils.dateOnly(widget.today ?? DateTime.now());
    _fecha = _today;
  }

  @override
  void dispose() {
    _notaCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime(2000),
      lastDate: _today,
      initialEntryMode: DatePickerEntryMode.calendarOnly,
      helpText: 'Fecha de finalización',
    );
    if (picked == null || !mounted) return;
    setState(() => _fecha = DateUtils.dateOnly(picked));
  }

  void _submit() {
    final estado = _estado;
    if (estado == null) return;
    Navigator.pop(
      context,
      FinalizeApplicationResult(
        estado: estado,
        fecha: _fecha,
        nota: _notaCtrl.text.trim(),
      ),
    );
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
      title: const Text('Finalizar proceso'),
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
          Text('Estado final', style: AppType.label(context)),
          const SizedBox(height: AppSpace.xs),
          Wrap(
            spacing: AppSpace.sm,
            runSpacing: AppSpace.xs,
            children: [
              for (final estado in applicationFinalStatuses)
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
          ),
          const SizedBox(height: AppSpace.md),
          InkWell(
            key: const Key('finalize-fecha'),
            onTap: _pickDate,
            borderRadius: const BorderRadius.all(
              Radius.circular(AppRadius.control),
            ),
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Fecha de finalización',
                suffixIcon: Icon(Icons.calendar_month),
              ),
              child: Text(formatDateValue(_fecha)),
            ),
          ),
          const SizedBox(height: AppSpace.md),
          TextField(
            key: const Key('finalize-nota'),
            controller: _notaCtrl,
            minLines: 3,
            maxLines: 5,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Nota (opcional)',
              hintText: 'Ej. Acepté la oferta, rechacé por el salario...',
              alignLabelWithHint: true,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _estado == null ? null : _submit,
          child: const Text('Finalizar'),
        ),
      ],
    );
  }
}
