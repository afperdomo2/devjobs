import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config.dart';
import '../helpers/date_formatter.dart';
import '../helpers/job_duplicate.dart';
import '../helpers/network_error.dart';
import '../models/application_options.dart';
import '../models/job_application.dart';
import '../models/job_import.dart';
import '../providers/app_state.dart';
import '../services/job_import_service.dart';
import '../theme.dart';
import '../widgets/ai_badge.dart';
import '../widgets/form_section.dart';
import '../widgets/import_application_sheet.dart';
import '../widgets/markdown_description.dart';
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
  final JobImporter? importService;

  const ApplicationFormScreen.create({super.key, this.importService})
    : initial = null;

  const ApplicationFormScreen.edit({
    super.key,
    required JobApplication application,
  }) : initial = application,
       importService = null;

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

  final _tipoContratoFieldKey = GlobalKey<FormFieldState<String>>();
  final _modalidadFieldKey = GlobalKey<FormFieldState<String>>();
  final _vacanteSectionKey = GlobalKey();

  final Set<String> _importedFields = {};
  JobImportResult? _importResult;
  bool _bannerDismissed = false;
  bool _showDescriptionPreview = false;

  static const _vacanteKeys = {
    'empresa',
    'vacante',
    'tipoContrato',
    'modalidad',
    'ciudad',
    'salarioOfrecido',
    'link',
  };

  static const _notasKeys = {'descripcion', 'contacto', 'comentarios'};

  bool get _aiAvailable => kAiEnabled && !widget.isEditing;

  bool _hasImported(Set<String> keys) => keys.any(_importedFields.contains);

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

  void _markUserEdited(String key) {
    if (!_importedFields.contains(key)) return;
    setState(() => _importedFields.remove(key));
  }

  Future<void> _openImport() async {
    final description = _descripcionCtrl.text.trim();
    final result = await showImportApplicationSheet(
      context,
      initialLink: _linkCtrl.text.trim(),
      initialText: description.length >= 40 ? description : null,
      service: widget.importService,
    );
    if (!mounted || result == null) return;
    _applyImport(result);
  }

  void _applyImport(JobImportResult result) {
    final applied = <String>{};

    void putText(TextEditingController controller, String key) {
      final value = (result.fields[key] ?? '').trim();
      if (value.isEmpty || controller.text.trim().isNotEmpty) return;
      controller.text = value;
      applied.add(key);
    }

    putText(_empresaCtrl, 'empresa');
    putText(_vacanteCtrl, 'vacante');
    putText(_ciudadCtrl, 'ciudad');
    putText(_salarioCtrl, 'salarioOfrecido');
    putText(_linkCtrl, 'link');
    putText(_descripcionCtrl, 'descripcion');
    putText(_contactoCtrl, 'contacto');
    putText(_comentariosCtrl, 'comentarios');

    String? contractValue;
    if (_tipoContrato.trim().isEmpty) {
      final value = (result.fields['tipoContrato'] ?? '').trim();
      if (value.isNotEmpty) {
        _tipoContrato = value;
        contractValue = value;
        applied.add('tipoContrato');
      }
    }

    String? modalityValue;
    if (_modalidad.trim().isEmpty) {
      final value = (result.fields['modalidad'] ?? '').trim();
      if (value.isNotEmpty) {
        _modalidad = value;
        modalityValue = value;
        applied.add('modalidad');
      }
    }

    setState(() {
      _importedFields
        ..clear()
        ..addAll(applied);
      _importResult = result;
      _bannerDismissed = false;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Se actualiza después del rebuild para que los ítems del dropdown ya
      // incluyan el valor importado (p. ej. "Indefinido").
      if (contractValue != null) {
        _tipoContratoFieldKey.currentState?.didChange(contractValue);
      }
      if (modalityValue != null) {
        _modalidadFieldKey.currentState?.didChange(modalityValue);
      }

      final section = _vacanteSectionKey.currentContext;
      if (section != null) {
        Scrollable.ensureVisible(
          section,
          duration: const Duration(milliseconds: 300),
          alignment: 0.05,
        );
      }
    });

    if (applied.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Los campos ya estaban completos; no se sobrescribió nada.',
          ),
        ),
      );
    }
  }

  void _clearImported() {
    setState(() {
      for (final key in _importedFields) {
        switch (key) {
          case 'empresa':
            _empresaCtrl.clear();
          case 'vacante':
            _vacanteCtrl.clear();
          case 'ciudad':
            _ciudadCtrl.clear();
          case 'salarioOfrecido':
            _salarioCtrl.clear();
          case 'link':
            _linkCtrl.clear();
          case 'descripcion':
            _descripcionCtrl.clear();
          case 'contacto':
            _contactoCtrl.clear();
          case 'comentarios':
            _comentariosCtrl.clear();
          case 'tipoContrato':
            _tipoContrato = '';
            _tipoContratoFieldKey.currentState?.didChange('');
          case 'modalidad':
            _modalidad = '';
            _modalidadFieldKey.currentState?.didChange('');
        }
      }
      _importedFields.clear();
      _importResult = null;
      _bannerDismissed = false;
    });
  }

  void _dismissBanner() {
    setState(() => _bannerDismissed = true);
  }

  Future<bool> _confirmDuplicate(JobApplication duplicate) async {
    final date = parseDate(duplicate.fechaPostulacion);
    final dateLabel = date != null ? formatDateValue(date) : 'sin fecha';

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Ya existe una postulación'),
        content: Text(
          'Ya registraste "${duplicate.vacante}" en ${duplicate.empresa} '
          'el $dateLabel (${duplicate.estado}).\n\n'
          '¿Crear otra de todos modos?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Crear otra'),
          ),
        ],
      ),
    );

    return result == true;
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

    final payload = _buildPayload();

    if (!widget.isEditing) {
      final duplicate = findDuplicateByLink(
        state.applications,
        payload['link'] ?? '',
      );
      if (duplicate != null) {
        final proceed = await _confirmDuplicate(duplicate);
        if (!proceed || !mounted) return;
      }
    }

    setState(() => _saving = true);

    try {
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
    final showImportEntry =
        _aiAvailable && (_importedFields.isEmpty || _bannerDismissed);
    final showImportBanner =
        _aiAvailable && _importedFields.isNotEmpty && !_bannerDismissed;
    final importWarnings = _importResult == null
        ? const <String>[]
        : (_importResult!.warnings.isNotEmpty
              ? _importResult!.warnings
              : <String>[
                  if (_importResult!.message != null) _importResult!.message!,
                ]);

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
                    if (showImportEntry) ...[
                      ImportEntryCard(
                        key: const Key('import-entry'),
                        onTap: isOffline ? null : _openImport,
                        subtitle: isOffline
                            ? 'Sin conexión'
                            : (_importedFields.isEmpty
                                  ? 'Pega el link o la descripción'
                                  : 'Volver a importar'),
                      ),
                      const SizedBox(height: AppSpace.xl),
                    ],
                    if (showImportBanner) ...[
                      ImportSummaryBanner(
                        key: const Key('import-summary'),
                        count: _importedFields.length,
                        warnings: importWarnings,
                        duplicate: _importResult?.duplicate,
                        onClear: _clearImported,
                        onDismiss: _dismissBanner,
                      ),
                      const SizedBox(height: AppSpace.xl),
                    ],
                    KeyedSubtree(
                      key: _vacanteSectionKey,
                      child: FormSection(
                        icon: Icons.work_outline,
                        title: 'Vacante',
                        subtitle: 'Datos de la oferta',
                        trailing: _hasImported(_vacanteKeys)
                            ? const AiBadge()
                            : null,
                        children: [
                          TextFormField(
                            key: const Key('form-empresa'),
                            controller: _empresaCtrl,
                            onChanged: (_) => _markUserEdited('empresa'),
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
                            onChanged: (_) => _markUserEdited('vacante'),
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
                            onChanged: (_) => _markUserEdited('link'),
                            keyboardType: TextInputType.url,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Link de la oferta',
                              hintText: 'https://...',
                            ),
                            validator: _validateLink,
                          ),
                          const SizedBox(height: AppSpace.md),
                          KeyedSubtree(
                            key: const Key('form-tipo-contrato'),
                            child: DropdownButtonFormField<String>(
                              key: _tipoContratoFieldKey,
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
                                if (v == null) return;
                                setState(() => _tipoContrato = v);
                                _markUserEdited('tipoContrato');
                              },
                            ),
                          ),
                          const SizedBox(height: AppSpace.md),
                          KeyedSubtree(
                            key: const Key('form-modalidad'),
                            child: DropdownButtonFormField<String>(
                              key: _modalidadFieldKey,
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
                                if (v == null) return;
                                setState(() => _modalidad = v);
                                _markUserEdited('modalidad');
                              },
                            ),
                          ),
                          const SizedBox(height: AppSpace.md),
                          TextFormField(
                            key: const Key('form-ciudad'),
                            controller: _ciudadCtrl,
                            onChanged: (_) => _markUserEdited('ciudad'),
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
                            onChanged: (_) =>
                                _markUserEdited('salarioOfrecido'),
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Salario ofrecido',
                              hintText: 'Ej. 3.500.000',
                            ),
                          ),
                        ],
                      ),
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
                      trailing: _hasImported(_notasKeys)
                          ? const AiBadge()
                          : null,
                      children: [
                        if (!_showDescriptionPreview)
                          TextFormField(
                            key: const Key('form-descripcion'),
                            controller: _descripcionCtrl,
                            onChanged: (_) => _markUserEdited('descripcion'),
                            minLines: 3,
                            maxLines: 8,
                            keyboardType: TextInputType.multiline,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: const InputDecoration(
                              labelText: 'Descripción',
                              alignLabelWithHint: true,
                            ),
                          )
                        else
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(AppSpace.md),
                            decoration: BoxDecoration(
                              color: scheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(
                                AppRadius.control,
                              ),
                              border: Border.all(
                                color: Theme.of(context).dividerColor,
                              ),
                            ),
                            child: _descripcionCtrl.text.trim().isEmpty
                                ? Text(
                                    'Sin descripción',
                                    style: AppType.label(context),
                                  )
                                : MarkdownDescription(
                                    data: _descripcionCtrl.text,
                                  ),
                          ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            key: const Key('form-descripcion-preview'),
                            onPressed: () => setState(
                              () => _showDescriptionPreview =
                                  !_showDescriptionPreview,
                            ),
                            icon: Icon(
                              _showDescriptionPreview
                                  ? Icons.edit_outlined
                                  : Icons.visibility_outlined,
                              size: 18,
                            ),
                            label: Text(
                              _showDescriptionPreview
                                  ? 'Editar'
                                  : 'Vista previa',
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpace.md),
                        TextFormField(
                          key: const Key('form-contacto'),
                          controller: _contactoCtrl,
                          onChanged: (_) => _markUserEdited('contacto'),
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
                          onChanged: (_) => _markUserEdited('comentarios'),
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
