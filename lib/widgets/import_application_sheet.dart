import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../config.dart';
import '../helpers/date_formatter.dart';
import '../helpers/network_error.dart';
import '../helpers/offer_link.dart';
import '../models/job_application.dart';
import '../models/job_import.dart';
import '../providers/app_state.dart';
import '../services/job_import_service.dart';
import '../theme.dart';

const Map<String, String> _fieldLabels = {
  'empresa': 'Empresa',
  'vacante': 'Vacante',
  'tipoContrato': 'Contrato',
  'modalidad': 'Modalidad',
  'ciudad': 'Ciudad',
  'salarioOfrecido': 'Salario',
  'descripcion': 'Descripción',
  'contacto': 'Contacto',
  'comentarios': 'Comentarios',
  'link': 'Link',
};

Future<JobImportResult?> showImportApplicationSheet(
  BuildContext context, {
  String? initialLink,
  String? initialText,
  JobImporter? service,
}) {
  if (!kAiEnabled) return Future<JobImportResult?>.value();

  return showModalBottomSheet<JobImportResult>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => ImportApplicationSheet(
      initialLink: initialLink,
      initialText: initialText,
      service: service ?? JobImportService(),
    ),
  );
}

/// Tarjeta de entrada al formulario. Solo se muestra si hay API key.
class ImportEntryCard extends StatelessWidget {
  final VoidCallback? onTap;
  final String subtitle;

  const ImportEntryCard({
    super.key,
    this.onTap,
    this.subtitle = 'Pega el link o la descripción',
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final enabled = onTap != null;

    return Opacity(
      opacity: enabled ? 1 : 0.6,
      child: Material(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.card),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpace.md),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: scheme.primary,
                  child: Icon(
                    Icons.auto_awesome,
                    size: 18,
                    color: scheme.onPrimary,
                  ),
                ),
                const SizedBox(width: AppSpace.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Autocompletar con IA',
                        style: AppType.cardTitle(
                          context,
                        ).copyWith(color: scheme.onPrimaryContainer),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: AppType.label(
                          context,
                        ).copyWith(color: scheme.onPrimaryContainer),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: scheme.onPrimaryContainer),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Resumen persistente en el formulario después de importar.
class ImportSummaryBanner extends StatelessWidget {
  final int count;
  final List<String> warnings;
  final JobApplication? duplicate;
  final VoidCallback onClear;
  final VoidCallback onDismiss;

  const ImportSummaryBanner({
    super.key,
    required this.count,
    required this.warnings,
    required this.duplicate,
    required this.onClear,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;
    final dup = duplicate;

    return Container(
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.35)),
      ),
      padding: const EdgeInsets.all(AppSpace.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                Icons.auto_awesome,
                size: AppIconSize.row,
                color: scheme.onPrimaryContainer,
              ),
              const SizedBox(width: AppSpace.sm),
              Expanded(
                child: Text(
                  'Datos importados · $count ${count == 1 ? 'campo' : 'campos'}',
                  style: AppType.section(
                    context,
                  ).copyWith(color: scheme.onPrimaryContainer),
                ),
              ),
              IconButton(
                key: const Key('import-dismiss'),
                tooltip: 'Ocultar aviso',
                visualDensity: VisualDensity.compact,
                icon: Icon(
                  Icons.close,
                  size: 18,
                  color: scheme.onPrimaryContainer,
                ),
                onPressed: onDismiss,
              ),
            ],
          ),
          Text(
            'Revisa antes de guardar.',
            style: AppType.label(
              context,
            ).copyWith(color: scheme.onPrimaryContainer),
          ),
          if (warnings.isNotEmpty) ...[
            const SizedBox(height: AppSpace.sm),
            for (final warning in warnings.take(3))
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.warning_amber,
                      size: 14,
                      color: warningTextColor(brightness),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        warning,
                        style: TextStyle(
                          fontSize: 12,
                          color: scheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (warnings.length > 3)
              Text(
                '+${warnings.length - 3} avisos más',
                style: AppType.label(
                  context,
                ).copyWith(color: scheme.onPrimaryContainer),
              ),
          ],
          if (dup != null) ...[
            const SizedBox(height: AppSpace.sm),
            Container(
              padding: const EdgeInsets.all(AppSpace.sm),
              decoration: BoxDecoration(
                color: warningContainer(brightness),
                borderRadius: BorderRadius.circular(AppRadius.chip),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.warning_amber,
                    size: 16,
                    color: warningTextColor(brightness),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Ya registraste esta vacante el '
                      '${_duplicateDate(dup.fechaPostulacion)} '
                      '(${dup.estado}). Búscala en Postulaciones.',
                      style: TextStyle(
                        fontSize: 12,
                        color: warningTextColor(brightness),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpace.xs),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              key: const Key('import-clear'),
              onPressed: onClear,
              icon: const Icon(Icons.delete_sweep_outlined, size: 18),
              label: const Text('Vaciar IA'),
              style: TextButton.styleFrom(
                foregroundColor: scheme.onPrimaryContainer,
                padding: const EdgeInsets.symmetric(horizontal: 4),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _duplicateDate(String raw) {
    final date = parseDate(raw);
    return date == null ? 'sin fecha' : formatDateValue(date);
  }
}

class ImportApplicationSheet extends StatefulWidget {
  final String? initialLink;
  final String? initialText;
  final JobImporter service;

  const ImportApplicationSheet({
    super.key,
    this.initialLink,
    this.initialText,
    required this.service,
  });

  @override
  State<ImportApplicationSheet> createState() => _ImportApplicationSheetState();
}

class _ImportApplicationSheetState extends State<ImportApplicationSheet> {
  late final TextEditingController _linkCtrl;
  late final TextEditingController _textCtrl;
  final FocusNode _textFocus = FocusNode();

  bool _loading = false;
  String? _error;
  JobImportResult? _result;
  int _requestId = 0;

  @override
  void initState() {
    super.initState();
    _linkCtrl = TextEditingController(text: widget.initialLink ?? '');
    _textCtrl = TextEditingController(text: widget.initialText ?? '');
    _linkCtrl.addListener(_rebuild);
    _textCtrl.addListener(_rebuild);
  }

  @override
  void dispose() {
    _linkCtrl.removeListener(_rebuild);
    _textCtrl.removeListener(_rebuild);
    _linkCtrl.dispose();
    _textCtrl.dispose();
    _textFocus.dispose();
    super.dispose();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  bool get _canAnalyze =>
      !_loading &&
      (_linkCtrl.text.trim().isNotEmpty || _textCtrl.text.trim().length >= 40);

  Future<void> _paste() async {
    final data = await Clipboard.getData('text/plain');
    final value = data?.text?.trim() ?? '';
    if (value.isEmpty) return;

    setState(() {
      if (parseOfferUri(value) != null) {
        _linkCtrl.text = value;
        _textCtrl.clear();
      } else {
        _textCtrl.text = value;
      }
      _error = null;
    });
  }

  Future<void> _analyze() async {
    final link = _linkCtrl.text.trim();
    final text = _textCtrl.text.trim();

    if (link.isEmpty && text.isEmpty) {
      setState(() => _error = 'Pega un enlace o una descripción.');
      return;
    }
    if (link.isNotEmpty && parseOfferUri(link) == null) {
      setState(() => _error = 'El enlace no es válido (http o https).');
      return;
    }
    if (text.isNotEmpty && text.length < 40) {
      setState(
        () => _error = 'El texto es muy corto; pega la descripción completa.',
      );
      return;
    }

    final state = context.read<AppState>();
    if (state.offline) {
      setState(() => _error = 'Sin conexión. Conéctate para importar.');
      return;
    }

    final id = ++_requestId;
    setState(() {
      _loading = true;
      _error = null;
      _result = null;
    });

    try {
      final result = text.isNotEmpty
          ? await widget.service.fromText(
              text,
              existing: state.applications,
              link: link.isEmpty ? null : link,
            )
          : await widget.service.fromLink(link, existing: state.applications);

      if (!mounted || id != _requestId) return;
      setState(() {
        _loading = false;
        _result = result;
        final normalized = result.fields['link'];
        if (normalized != null && normalized.isNotEmpty) {
          _linkCtrl.text = normalized;
        }
      });
    } catch (error) {
      if (!mounted || id != _requestId) return;
      setState(() {
        _loading = false;
        _error = friendlyErrorMessage(error);
      });
    }
  }

  void _cancel() {
    setState(() {
      _loading = false;
      _requestId++;
    });
  }

  void _switchToText() {
    setState(() {
      _result = null;
      _error = null;
    });
    _textFocus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpace.lg,
            0,
            AppSpace.lg,
            AppSpace.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(context),
              const SizedBox(height: AppSpace.lg),
              if (_loading)
                _buildLoading(context)
              else if (_result != null)
                _buildResult(context, _result!)
              else
                _buildForm(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: scheme.primaryContainer,
          child: Icon(
            Icons.auto_awesome,
            size: 20,
            color: scheme.onPrimaryContainer,
          ),
        ),
        const SizedBox(width: AppSpace.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Importar vacante',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                'Completa el formulario con IA',
                style: AppType.label(context),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildForm(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          key: const Key('import-link'),
          controller: _linkCtrl,
          keyboardType: TextInputType.url,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            labelText: 'Link de la vacante',
            hintText: 'https://...',
            suffixIcon: IconButton(
              tooltip: 'Pegar del portapapeles',
              icon: const Icon(Icons.content_paste),
              onPressed: _paste,
            ),
          ),
        ),
        const SizedBox(height: AppSpace.md),
        Row(
          children: [
            const Expanded(child: Divider()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.sm),
              child: Text('o pega el texto', style: AppType.label(context)),
            ),
            const Expanded(child: Divider()),
          ],
        ),
        const SizedBox(height: AppSpace.md),
        TextField(
          key: const Key('import-text'),
          controller: _textCtrl,
          focusNode: _textFocus,
          minLines: 4,
          maxLines: 8,
          keyboardType: TextInputType.multiline,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: 'Descripción de la vacante',
            alignLabelWithHint: true,
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: AppSpace.sm),
          _ErrorText(_error!),
        ],
        const SizedBox(height: AppSpace.lg),
        FilledButton.icon(
          key: const Key('import-analyze'),
          onPressed: _canAnalyze ? _analyze : null,
          icon: const Icon(Icons.auto_awesome),
          label: const Text('Analizar'),
        ),
        const SizedBox(height: AppSpace.sm),
        Text(
          'Modelo: $kAiModel',
          textAlign: TextAlign.center,
          style: AppType.label(context),
        ),
        Text(
          'Solo se envía el texto de la vacante.',
          textAlign: TextAlign.center,
          style: AppType.label(context),
        ),
      ],
    );
  }

  Widget _buildLoading(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const LinearProgressIndicator(),
        const SizedBox(height: AppSpace.lg),
        Text(
          'Analizando la vacante…',
          textAlign: TextAlign.center,
          style: AppType.section(context),
        ),
        const SizedBox(height: AppSpace.xs),
        Text(
          'Puede tardar unos segundos.',
          textAlign: TextAlign.center,
          style: AppType.label(context),
        ),
        const SizedBox(height: AppSpace.md),
        TextButton(onPressed: _cancel, child: const Text('Cancelar')),
      ],
    );
  }

  Widget _buildResult(BuildContext context, JobImportResult result) {
    if (result.status == JobImportStatus.needsText ||
        result.status == JobImportStatus.failed) {
      return _buildMessage(context, result);
    }
    return _buildSummary(context, result);
  }

  Widget _buildSummary(BuildContext context, JobImportResult result) {
    final scheme = Theme.of(context).colorScheme;
    final success = result.status == JobImportStatus.success;
    final fields = result.importedFields
        .map((key) => _fieldLabels[key] ?? key)
        .join(' · ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(
              success ? Icons.check_circle_outline : Icons.info_outline,
              color: success
                  ? scheme.primary
                  : warningTextColor(Theme.of(context).brightness),
            ),
            const SizedBox(width: AppSpace.sm),
            Text(
              success ? 'Datos extraídos' : 'Datos parciales',
              style: AppType.section(context),
            ),
          ],
        ),
        const SizedBox(height: AppSpace.sm),
        Text(
          '${result.filledCount} ${result.filledCount == 1 ? 'campo encontrado' : 'campos encontrados'}',
          style: AppType.label(context),
        ),
        if (fields.isNotEmpty) ...[
          const SizedBox(height: AppSpace.xs),
          Text(fields, style: AppType.label(context)),
        ],
        if (result.warnings.isNotEmpty) ...[
          const SizedBox(height: AppSpace.md),
          for (final warning in result.warnings) _WarningRow(warning),
        ],
        if (result.duplicate != null) ...[
          const SizedBox(height: AppSpace.sm),
          _DuplicateRow(duplicate: result.duplicate!),
        ],
        if (result.source.isNotEmpty) ...[
          const SizedBox(height: AppSpace.sm),
          Text('Fuente: ${result.source}', style: AppType.label(context)),
        ],
        const SizedBox(height: AppSpace.lg),
        FilledButton(
          key: const Key('import-use'),
          onPressed: () => Navigator.of(context).pop(result),
          child: const Text('Usar estos datos'),
        ),
        TextButton(
          onPressed: () => setState(() => _result = null),
          child: const Text('Volver'),
        ),
      ],
    );
  }

  Widget _buildMessage(BuildContext context, JobImportResult result) {
    final message =
        result.message ?? 'No se pudieron extraer datos de la vacante.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.info_outline,
              color: warningTextColor(Theme.of(context).brightness),
            ),
            const SizedBox(width: AppSpace.sm),
            Expanded(
              child: Text(message, style: const TextStyle(fontSize: 14)),
            ),
          ],
        ),
        if (result.fields['link'] != null) ...[
          const SizedBox(height: AppSpace.sm),
          Text(
            'Puedes guardar solo el enlace y completar el resto a mano.',
            style: AppType.label(context),
          ),
        ],
        const SizedBox(height: AppSpace.lg),
        FilledButton.icon(
          key: const Key('import-paste-text'),
          onPressed: _switchToText,
          icon: const Icon(Icons.content_paste),
          label: const Text('Pegar texto'),
        ),
        if (result.fields['link'] != null)
          TextButton(
            key: const Key('import-use-link'),
            onPressed: () => Navigator.of(context).pop(result),
            child: const Text('Usar solo el enlace'),
          ),
        TextButton(
          key: const Key('import-retry'),
          onPressed: _analyze,
          child: const Text('Reintentar'),
        ),
      ],
    );
  }
}

class _ErrorText extends StatelessWidget {
  final String message;

  const _ErrorText(this.message);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.error_outline,
          size: 16,
          color: Theme.of(context).colorScheme.error,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            message,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.error,
            ),
          ),
        ),
      ],
    );
  }
}

class _WarningRow extends StatelessWidget {
  final String message;

  const _WarningRow(this.message);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.warning_amber,
            size: 15,
            color: warningTextColor(Theme.of(context).brightness),
          ),
          const SizedBox(width: 6),
          Expanded(child: Text(message, style: const TextStyle(fontSize: 12))),
        ],
      ),
    );
  }
}

class _DuplicateRow extends StatelessWidget {
  final JobApplication duplicate;

  const _DuplicateRow({required this.duplicate});

  @override
  Widget build(BuildContext context) {
    final date = parseDate(duplicate.fechaPostulacion);
    final dateLabel = date == null ? 'sin fecha' : formatDateValue(date);

    return Container(
      padding: const EdgeInsets.all(AppSpace.sm),
      decoration: BoxDecoration(
        color: warningContainer(Theme.of(context).brightness),
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.warning_amber,
            size: 16,
            color: warningTextColor(Theme.of(context).brightness),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'Ya registraste esta vacante el $dateLabel '
              '(${duplicate.estado}).',
              style: TextStyle(
                fontSize: 12,
                color: warningTextColor(Theme.of(context).brightness),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
