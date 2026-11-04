import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../helpers/date_formatter.dart';
import '../helpers/network_error.dart';
import '../models/application_options.dart';
import '../models/job_application.dart';
import '../providers/app_state.dart';
import '../theme.dart';
import '../widgets/form_section.dart';
import '../widgets/offline_banner.dart';

/// Abre el formulario de creación y, si se guarda, vuelve a la lista completa
/// con un aviso. Compartido por el FAB y el estado vacío.
Future<void> startCreateApplication(BuildContext context) async {
  final created = await Navigator.push<bool>(
    context,
    MaterialPageRoute(builder: (_) => const ApplicationFormScreen.create()),
  );
  if (created != true || !context.mounted) return;

  context.read<AppState>().openApplications(AppState.filterAll);
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(const SnackBar(content: Text('Postulación creada')));
}

/// Formulario compartido para crear y editar postulaciones.
///
/// En modo creación ([ApplicationFormScreen.create]) arranca con valores
/// razonables (estado `Enviada`, fecha de postulación hoy). En modo edición
/// ([ApplicationFormScreen.edit]) precarga la postulación recibida.
class ApplicationFormScreen extends StatefulWidget {
  final JobApplication? initial;

  const ApplicationFormScreen.create({super.key}) : initial = null;

  const ApplicationFormScreen.edit({
    super.key,
    required JobApplication application,
  }) : initial = application;

  bool get isEditing => initial != null;

  @override
  State<ApplicationFormScreen> createState() => _ApplicationFormScreenState();
}

class _ApplicationFormScreenState extends State<ApplicationFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _empresaCtrl;
  late final TextEditingController _vacanteCtrl;
  late final TextEditingController _ciudadCtrl;
  late final TextEditingController _salarioCtrl;
  late final TextEditingController _linkCtrl;
  late final TextEditingController _descripcionCtrl;
  late final TextEditingController _contactoCtrl;
  late final TextEditingController _comentariosCtrl;
  late final TextEditingController _fechaPostulacionCtrl;
  late final TextEditingController _fechaSeguimientoCtrl;

  late String _tipoContrato;
  late String _modalidad;
  late String _estado;
  late bool _entrevistaRealizada;
  late bool _porGestionar;

  DateTime? _fechaPostulacion;
  DateTime? _fechaSeguimiento;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final app = widget.initial;

    _empresaCtrl = TextEditingController(text: app?.empresa ?? '');
    _vacanteCtrl = TextEditingController(text: app?.vacante ?? '');
    _ciudadCtrl = TextEditingController(text: app?.ciudad ?? '');
    _salarioCtrl = TextEditingController(text: app?.salarioOfrecido ?? '');
    _linkCtrl = TextEditingController(text: app?.link ?? '');
    _descripcionCtrl = TextEditingController(text: app?.descripcion ?? '');
    _contactoCtrl = TextEditingController(text: app?.contacto ?? '');
    _comentariosCtrl = TextEditingController(text: app?.comentarios ?? '');

    _tipoContrato = app?.tipoContrato ?? '';
    _modalidad = app?.modalidad ?? '';
    _estado = app?.estado ?? 'Enviada';
    _entrevistaRealizada = app?.entrevistaRealizada ?? false;
    _porGestionar = app?.porGestionar ?? false;

    if (app == null) {
      final today = _dateOnly(DateTime.now());
      _fechaPostulacion = today;
      _fechaPostulacionCtrl = TextEditingController(
        text: formatDateValue(today),
      );
      _fechaSeguimientoCtrl = TextEditingController();
    } else {
      final postulacionRaw = app.fechaPostulacion.trim();
      final postulacion = parseDate(postulacionRaw);
      _fechaPostulacion = postulacion;
      _fechaPostulacionCtrl = TextEditingController(
        text: postulacion != null
            ? formatDateValue(postulacion)
            : postulacionRaw,
      );

      final seguimientoRaw = app.fechaSeguimiento.trim();
      final seguimiento = parseDate(seguimientoRaw);
      _fechaSeguimiento = seguimiento;
      _fechaSeguimientoCtrl = TextEditingController(
        text: seguimiento != null
            ? formatDateValue(seguimiento)
            : seguimientoRaw,
      );
    }
  }

  @override
  void dispose() {
    _empresaCtrl.dispose();
    _vacanteCtrl.dispose();
    _ciudadCtrl.dispose();
    _salarioCtrl.dispose();
    _linkCtrl.dispose();
    _descripcionCtrl.dispose();
    _contactoCtrl.dispose();
    _comentariosCtrl.dispose();
    _fechaPostulacionCtrl.dispose();
    _fechaSeguimientoCtrl.dispose();
    super.dispose();
  }

  static DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  String _datePayload(DateTime? date, TextEditingController controller) {
    if (date != null) return formatApiDate(date);
    // Conserva una fecha que ya venía en la hoja pero no se pudo parsear.
    return controller.text.trim();
  }

  Future<void> _pickDate({required bool postulacion}) async {
    final firstDate = DateTime(2000);
    final lastDate = DateTime(2100);
    final current = postulacion ? _fechaPostulacion : _fechaSeguimiento;

    var initialDate = current ?? _dateOnly(DateTime.now());
    if (initialDate.isBefore(firstDate)) initialDate = firstDate;
    if (initialDate.isAfter(lastDate)) initialDate = lastDate;

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      initialEntryMode: DatePickerEntryMode.calendarOnly,
      helpText: postulacion ? 'Fecha de postulación' : 'Última novedad',
    );
    if (picked == null || !mounted) return;

    final date = _dateOnly(picked);
    setState(() {
      if (postulacion) {
        _fechaPostulacion = date;
        _fechaPostulacionCtrl.text = formatDateValue(date);
      } else {
        _fechaSeguimiento = date;
        _fechaSeguimientoCtrl.text = formatDateValue(date);
      }
    });
  }

  void _clearSeguimiento() {
    setState(() {
      _fechaSeguimiento = null;
      _fechaSeguimientoCtrl.clear();
    });
  }

  String? _validateRequired(String? value, String message) {
    return (value == null || value.trim().isEmpty) ? message : null;
  }

  String? _validateLink(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;

    final uri = Uri.tryParse(text);
    final validScheme = uri?.scheme == 'http' || uri?.scheme == 'https';
    if (uri == null || !validScheme || uri.host.isEmpty) {
      return 'Ingresa una URL válida (http o https)';
    }
    return null;
  }

  Map<String, String> _buildPayload() {
    return {
      'empresa': _empresaCtrl.text.trim(),
      'vacante': _vacanteCtrl.text.trim(),
      'tipoContrato': _tipoContrato,
      'modalidad': _modalidad,
      'ciudad': _ciudadCtrl.text.trim(),
      'salarioOfrecido': _salarioCtrl.text.trim(),
      'estado': _estado,
      'link': _linkCtrl.text.trim(),
      'descripcion': _descripcionCtrl.text,
      'fechaPostulacion': _datePayload(
        _fechaPostulacion,
        _fechaPostulacionCtrl,
      ),
      'fechaSeguimiento': _datePayload(
        _fechaSeguimiento,
        _fechaSeguimientoCtrl,
      ),
      'contacto': _contactoCtrl.text.trim(),
      'comentarios': _comentariosCtrl.text,
      'entrevistaRealizada': _entrevistaRealizada.toString(),
      'porGestionar': _porGestionar.toString(),
    };
  }

  Future<void> _save() async {
    if (_saving) return;

    if (!_formKey.currentState!.validate()) return;

    final state = context.read<AppState>();
    if (state.offline) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Sin conexión — no se puede guardar en modo solo lectura.',
          ),
        ),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final payload = _buildPayload();

      if (widget.isEditing) {
        await state.updateApplication(widget.initial!.rowIndex, payload);
      } else {
        final draft = const JobApplication(rowIndex: 0).copyWith(
          empresa: payload['empresa'],
          vacante: payload['vacante'],
          tipoContrato: payload['tipoContrato'],
          modalidad: payload['modalidad'],
          ciudad: payload['ciudad'],
          salarioOfrecido: payload['salarioOfrecido'],
          estado: payload['estado'],
          link: payload['link'],
          descripcion: payload['descripcion'],
          fechaPostulacion: payload['fechaPostulacion'],
          fechaSeguimiento: payload['fechaSeguimiento'],
          contacto: payload['contacto'],
          comentarios: payload['comentarios'],
          entrevistaRealizada: _entrevistaRealizada,
          porGestionar: _porGestionar,
        );
        await state.createApplication(draft);
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: ${friendlyErrorMessage(e)}'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  List<DropdownMenuItem<String>> _optionalItems(
    List<String> options,
    String current,
  ) {
    final values = [...options];
    if (current.isNotEmpty && !values.contains(current)) {
      values.insert(0, current);
    }
    return [
      const DropdownMenuItem(value: '', child: Text('Sin especificar')),
      ...values.map((v) => DropdownMenuItem(value: v, child: Text(v))),
    ];
  }

  List<DropdownMenuItem<String>> _statusItems(String current) {
    final values = [...applicationStatuses];
    if (current.isNotEmpty && !values.contains(current)) {
      values.insert(0, current);
    }
    return [
      if (current.isEmpty)
        const DropdownMenuItem(value: '', child: Text('Selecciona un estado')),
      ...values.map((v) => DropdownMenuItem(value: v, child: Text(v))),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final isOffline = context.watch<AppState>().offline;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isEditing ? 'Editar postulación' : 'Nueva postulación',
        ),
      ),
      body: Column(
        children: [
          if (isOffline)
            OfflineBanner(
              lastUpdated: context.watch<AppState>().cacheTimestamp,
              onRetry: () => context.read<AppState>().fetchApplications(
                forceRefresh: true,
              ),
            ),
          Expanded(
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpace.lg,
                  AppSpace.lg,
                  AppSpace.lg,
                  AppSpace.xl,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FormSection(
                      icon: Icons.work_outline,
                      title: 'Vacante',
                      subtitle: 'Datos de la oferta',
                      children: [
                        TextFormField(
                          key: const Key('form-empresa'),
                          controller: _empresaCtrl,
                          textInputAction: TextInputAction.next,
                          textCapitalization: TextCapitalization.words,
                          decoration: const InputDecoration(
                            labelText: 'Empresa',
                            hintText: 'Ej. Acme',
                          ),
                          validator: (v) =>
                              _validateRequired(v, 'Ingresa la empresa'),
                        ),
                        const SizedBox(height: AppSpace.md),
                        TextFormField(
                          key: const Key('form-vacante'),
                          controller: _vacanteCtrl,
                          textInputAction: TextInputAction.next,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: const InputDecoration(
                            labelText: 'Vacante',
                            hintText: 'Ej. Desarrollador Backend',
                          ),
                          validator: (v) =>
                              _validateRequired(v, 'Ingresa la vacante'),
                        ),
                        const SizedBox(height: AppSpace.md),
                        TextFormField(
                          key: const Key('form-link'),
                          controller: _linkCtrl,
                          keyboardType: TextInputType.url,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Link de la oferta',
                            hintText: 'https://...',
                          ),
                          validator: _validateLink,
                        ),
                        const SizedBox(height: AppSpace.md),
                        DropdownButtonFormField<String>(
                          key: const Key('form-tipo-contrato'),
                          initialValue: _tipoContrato,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Tipo de contrato',
                          ),
                          items: _optionalItems(
                            applicationContractTypes,
                            _tipoContrato,
                          ),
                          onChanged: (v) {
                            if (v != null) setState(() => _tipoContrato = v);
                          },
                        ),
                        const SizedBox(height: AppSpace.md),
                        DropdownButtonFormField<String>(
                          key: const Key('form-modalidad'),
                          initialValue: _modalidad,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Modalidad',
                          ),
                          items: _optionalItems(
                            applicationModalities,
                            _modalidad,
                          ),
                          onChanged: (v) {
                            if (v != null) setState(() => _modalidad = v);
                          },
                        ),
                        const SizedBox(height: AppSpace.md),
                        TextFormField(
                          key: const Key('form-ciudad'),
                          controller: _ciudadCtrl,
                          textInputAction: TextInputAction.next,
                          textCapitalization: TextCapitalization.words,
                          decoration: const InputDecoration(
                            labelText: 'Ciudad',
                            hintText: 'Ej. Bogotá',
                          ),
                        ),
                        const SizedBox(height: AppSpace.md),
                        TextFormField(
                          key: const Key('form-salario'),
                          controller: _salarioCtrl,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Salario ofrecido',
                            hintText: 'Ej. 3.500.000',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpace.xl),
                    FormSection(
                      icon: Icons.timeline,
                      title: 'Proceso',
                      subtitle: 'Estado, fechas y seguimiento',
                      children: [
                        DropdownButtonFormField<String>(
                          key: const Key('form-estado'),
                          initialValue: _estado,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Estado',
                          ),
                          items: _statusItems(_estado),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Selecciona el estado'
                              : null,
                          onChanged: (v) {
                            if (v != null) setState(() => _estado = v);
                          },
                        ),
                        const SizedBox(height: AppSpace.md),
                        TextFormField(
                          key: const Key('form-fecha-postulacion'),
                          controller: _fechaPostulacionCtrl,
                          readOnly: true,
                          onTap: () => _pickDate(postulacion: true),
                          decoration: InputDecoration(
                            labelText: 'Fecha de postulación',
                            suffixIcon: IconButton(
                              tooltip: 'Elegir fecha',
                              icon: const Icon(Icons.calendar_month),
                              onPressed: () => _pickDate(postulacion: true),
                            ),
                          ),
                          validator: (_) {
                            if (_fechaPostulacion == null &&
                                _fechaPostulacionCtrl.text.trim().isEmpty) {
                              return 'Selecciona la fecha de postulación';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSpace.md),
                        TextFormField(
                          key: const Key('form-fecha-seguimiento'),
                          controller: _fechaSeguimientoCtrl,
                          readOnly: true,
                          onTap: () => _pickDate(postulacion: false),
                          decoration: InputDecoration(
                            labelText: 'Última novedad',
                            suffixIcon: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (_fechaSeguimientoCtrl.text.isNotEmpty)
                                  IconButton(
                                    tooltip: 'Limpiar fecha',
                                    icon: const Icon(Icons.clear),
                                    visualDensity: VisualDensity.compact,
                                    onPressed: _clearSeguimiento,
                                  ),
                                IconButton(
                                  tooltip: 'Elegir fecha',
                                  icon: const Icon(Icons.calendar_month),
                                  visualDensity: VisualDensity.compact,
                                  onPressed: () =>
                                      _pickDate(postulacion: false),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpace.xs),
                        SwitchListTile(
                          key: const Key('form-entrevista'),
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Entrevista realizada'),
                          value: _entrevistaRealizada,
                          onChanged: (v) =>
                              setState(() => _entrevistaRealizada = v),
                        ),
                        SwitchListTile(
                          key: const Key('form-por-gestionar'),
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Por gestionar'),
                          subtitle: const Text(
                            'Marcar si hay algo pendiente con esta vacante',
                          ),
                          value: _porGestionar,
                          onChanged: (v) => setState(() => _porGestionar = v),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpace.xl),
                    FormSection(
                      icon: Icons.notes,
                      title: 'Notas',
                      subtitle: 'Información adicional',
                      children: [
                        TextFormField(
                          key: const Key('form-descripcion'),
                          controller: _descripcionCtrl,
                          maxLines: 3,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: const InputDecoration(
                            labelText: 'Descripción',
                            alignLabelWithHint: true,
                          ),
                        ),
                        const SizedBox(height: AppSpace.md),
                        TextFormField(
                          key: const Key('form-contacto'),
                          controller: _contactoCtrl,
                          textInputAction: TextInputAction.next,
                          textCapitalization: TextCapitalization.words,
                          decoration: const InputDecoration(
                            labelText: 'Contacto',
                            hintText: 'Ej. Ana Pérez',
                          ),
                        ),
                        const SizedBox(height: AppSpace.md),
                        TextFormField(
                          key: const Key('form-comentarios'),
                          controller: _comentariosCtrl,
                          maxLines: 3,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: const InputDecoration(
                            labelText: 'Comentarios',
                            alignLabelWithHint: true,
                          ),
                        ),
                      ],
                    ),
                    if (isOffline)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpace.md),
                        child: Text(
                          'Modo solo lectura — conéctate a internet para guardar.',
                          style: TextStyle(
                            color: scheme.onSurfaceVariant,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildSaveBar(context, isOffline),
    );
  }

  Widget _buildSaveBar(BuildContext context, bool isOffline) {
    final scheme = Theme.of(context).colorScheme;

    return SafeArea(
      top: false,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.surface,
          border: Border(
            top: BorderSide(color: Theme.of(context).dividerColor),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpace.lg,
            AppSpace.sm,
            AppSpace.lg,
            AppSpace.md,
          ),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              key: const Key('form-save'),
              onPressed: (isOffline || _saving) ? null : _save,
              icon: _saving
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: scheme.primary,
                      ),
                    )
                  : Icon(widget.isEditing ? Icons.save : Icons.add),
              label: Text(
                _saving
                    ? 'Guardando...'
                    : widget.isEditing
                    ? 'Guardar cambios'
                    : 'Crear postulación',
              ),
            ),
          ),
        ),
      ),
    );
  }
}
