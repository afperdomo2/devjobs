import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../helpers/comments.dart';
import '../helpers/date_formatter.dart';
import '../helpers/network_error.dart';
import '../helpers/offer_link.dart';
import '../helpers/salary_formatter.dart';
import '../models/job_application.dart';
import '../providers/app_state.dart';
import '../theme.dart';
import '../widgets/add_note_dialog.dart';
import '../widgets/gestion_tag.dart';
import '../widgets/offline_banner.dart';
import '../widgets/status_chip.dart';
import 'application_form_screen.dart';

class ApplicationDetailScreen extends StatefulWidget {
  final JobApplication application;

  const ApplicationDetailScreen({super.key, required this.application});

  @override
  State<ApplicationDetailScreen> createState() => _ApplicationDetailScreenState();
}

class _ApplicationDetailScreenState extends State<ApplicationDetailScreen> {
  Future<void> _toggleGestion(JobApplication app) async {
    try {
      await context.read<AppState>().updateApplication(
        app.rowIndex,
        {'porGestionar': (!app.porGestionar).toString()},
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${friendlyErrorMessage(e)}')),
        );
      }
    }
  }

  Future<void> _addNote(JobApplication app) async {
    final text = await showAddNoteDialog(context);
    if (text == null || text.trim().isEmpty || !mounted) return;

    final state = context.read<AppState>();
    if (state.offline) return;

    final current = state.applications.firstWhere(
      (item) => item.rowIndex == app.rowIndex,
      orElse: () => app,
    );

    try {
      await state.updateApplication(
        app.rowIndex,
        {'comentarios': appendComment(current.comentarios, text)},
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nota agregada')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${friendlyErrorMessage(e)}')),
        );
      }
    }
  }

  Future<void> _openLink(Uri uri) async {
    try {
      final opened = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!opened && mounted) _showSnack('No se pudo abrir el enlace.');
    } catch (_) {
      if (mounted) _showSnack('No se pudo abrir el enlace.');
    }
  }

  Future<void> _copyLink(String link) async {
    await Clipboard.setData(ClipboardData(text: link));
    if (!mounted) return;
    _showSnack('Enlace copiado al portapapeles');
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    // Tras editar, AppState tiene la versión parchada; la instancia original
    // que llegó por parámetro queda obsoleta, así que se resuelve por rowIndex.
    final app = state.applications.firstWhere(
      (a) => a.rowIndex == widget.application.rowIndex,
      orElse: () => widget.application,
    );
    final comentarios = parseComments(app.comentarios);
    final offerUri = parseOfferUri(app.link);
    final offerDomain = offerLinkDomain(app.link);
    final isOffline = state.offline;
    final cacheTs = state.cacheTimestamp;

    return Scaffold(
      appBar: AppBar(
        title: Text(app.empresa),
        actions: [
          if (isOffline)
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: Tooltip(
                message: 'Sin conexión — edición deshabilitada',
                child: Icon(Icons.wifi_off, size: 20),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.note_add_outlined),
            tooltip: isOffline
                ? 'Sin conexión — edición deshabilitada'
                : 'Agregar nota',
            onPressed: isOffline ? null : () => _addNote(app),
          ),
          IconButton(
            icon: Icon(
              app.porGestionar
                  ? Icons.label_important
                  : Icons.label_important_outline,
              color: app.porGestionar
                  ? gestionColor(Theme.of(context).brightness)
                  : null,
            ),
            tooltip: isOffline
                ? 'Sin conexión — edición deshabilitada'
                : (app.porGestionar ? 'Quitar "Por gestionar"' : 'Marcar "Por gestionar"'),
            onPressed: isOffline ? null : () => _toggleGestion(app),
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: isOffline ? 'Sin conexión — edición deshabilitada' : 'Editar postulación',
            onPressed: isOffline
                ? null
                : () async {
                    final result = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            ApplicationFormScreen.edit(application: app),
                      ),
                    );
                    if (result == true && mounted) {
                      setState(() {});
                    }
                  },
          ),
        ],
      ),
      body: Column(
        children: [
          if (isOffline)
            OfflineBanner(
              lastUpdated: cacheTs,
              onRetry: () => context.read<AppState>().fetchApplications(forceRefresh: true),
            ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                StatusChip(status: app.estado),
                if (app.porGestionar) ...[
                  const SizedBox(height: 8),
                  Row(children: [GestionTag(onTap: () => _toggleGestion(app))]),
                ],
                const SizedBox(height: 8),
                Text(
                  app.vacante,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ..._buildInfoSection(context, app),
                if (app.link.isNotEmpty) ...[
                  const Divider(height: 32),
                  Row(
                    children: [
                      Icon(Icons.link,
                          size: AppIconSize.row,
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant),
                      const SizedBox(width: 6),
                      Text('Enlace externo', style: AppType.section(context)),
                    ],
                  ),
                  const SizedBox(height: AppSpace.sm),
                  if (offerDomain.isNotEmpty)
                    Tooltip(
                      message: app.link,
                      child: Text(
                        offerDomain,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppType.label(context),
                      ),
                    ),
                  if (offerDomain.isNotEmpty)
                    const SizedBox(height: AppSpace.sm),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: offerUri == null
                              ? null
                              : () => _openLink(offerUri),
                          icon: const Icon(Icons.open_in_new,
                              size: AppIconSize.row),
                          label: const Text('Abrir'),
                        ),
                      ),
                      const SizedBox(width: AppSpace.sm),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _copyLink(app.link),
                          icon: const Icon(Icons.copy, size: AppIconSize.row),
                          label: const Text('Copiar'),
                        ),
                      ),
                    ],
                  ),
                  if (offerUri == null) ...[
                    const SizedBox(height: AppSpace.sm),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: AppIconSize.row,
                          color:
                              dangerColor(Theme.of(context).brightness),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'El enlace no parece válido.',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: dangerColor(
                                      Theme.of(context).brightness),
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
                if (comentarios.isNotEmpty) ...[
                  const Divider(height: 32),
                  Row(
                    children: [
                      Icon(Icons.chat_bubble_outline,
                          size: AppIconSize.row,
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant),
                      const SizedBox(width: 6),
                      Text('Comentarios', style: AppType.section(context)),
                    ],
                  ),
                  const SizedBox(height: AppSpace.sm),
                  for (final c in comentarios)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('• ', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 14)),
                          Expanded(child: Text(c, style: const TextStyle(fontSize: 14))),
                        ],
                      ),
                    ),
                ],
                if (app.descripcion.isNotEmpty) ...[
                  const Divider(height: 32),
                  Row(
                    children: [
                      Icon(Icons.description_outlined,
                          size: AppIconSize.row,
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant),
                      const SizedBox(width: 6),
                      Text('Descripción', style: AppType.section(context)),
                    ],
                  ),
                  const SizedBox(height: AppSpace.sm),
                  Text(app.descripcion),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildInfoSection(BuildContext context, JobApplication app) {
    final warningColor =
        warningTextColor(Theme.of(context).brightness);

    final baseFields = [
      (Icons.business, 'Empresa', app.empresa),
      (Icons.work_outline, 'Tipo de contrato', app.tipoContrato),
      (Icons.laptop_mac_outlined, 'Modalidad', app.modalidad),
      (Icons.location_on_outlined, 'Ciudad', app.ciudad),
      (Icons.attach_money_outlined, 'Salario ofrecido', formatSalario(app.salarioOfrecido)),
      (Icons.language, 'Plataforma', app.plataforma),
      (Icons.calendar_today, 'F. postulación', formatDate(app.fechaPostulacion)),
      (Icons.notifications_outlined, 'Últ. novedad', formatDate(app.fechaSeguimiento)),
    ].where((f) => f.$3.isNotEmpty).map(_fieldRow).toList();

    // Tiempo del proceso: duración total si finalizado; avance y
    // días sin novedad si sigue activo.
    final processFields = <Widget>[
      if (app.isFinalizado)
        if (app.diasProceso != null)
          _fieldRow((
            Icons.check_circle_outline,
            'Duración proceso',
            formatDuracion(app.diasProceso!),
          ))
      else ...[
        if (app.diasProceso != null)
          _fieldRow((
            Icons.schedule,
            'En proceso',
            formatDias(app.diasProceso!),
          )),
        if (app.diasSinNovedad != null)
          _fieldRow(
            (
              Icons.notifications_outlined,
              'Sin novedad',
              formatSinNovedad(app.diasSinNovedad!),
            ),
            color: app.diasSinNovedad! >= kUmbralDiasSinNovedad
                ? warningColor
                : null,
          ),
      ],
    ];

    final afterFields = [
      (Icons.person_outline, 'Contacto', app.contacto),
    ].where((f) => f.$3.isNotEmpty).map(_fieldRow).toList();

    return [
      ...baseFields,
      ...processFields,
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Icon(Icons.people,
                size: AppIconSize.row,
                color: Theme.of(context).colorScheme.onSurfaceVariant),
            const SizedBox(width: AppSpace.sm),
            SizedBox(
              width: 100,
              child: Text('Entrevista', style: AppType.label(context)),
            ),
            Transform.scale(
              scale: 0.6,
              child: Switch(
                value: app.entrevistaRealizada,
                onChanged: null,
                thumbColor: WidgetStateProperty.resolveWith<Color>((states) {
                  if (states.contains(WidgetState.selected)) {
                    return successColor(Theme.of(context).brightness);
                  }
                  return Theme.of(context).colorScheme.surface;
                }),
              ),
            ),
          ],
        ),
      ),
      ...afterFields,
    ];
  }

  Widget _fieldRow((IconData, String, String) f, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(f.$1,
              size: AppIconSize.row,
              color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(width: AppSpace.sm),
          SizedBox(
            width: 112,
            child: Text(f.$2, style: AppType.label(context)),
          ),
          Expanded(
            child: Text(
              f.$3,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: color,
                    fontWeight: color != null ? FontWeight.w600 : null,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
