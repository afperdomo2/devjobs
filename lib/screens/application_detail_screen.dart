import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:provider/provider.dart';

import '../helpers/date_formatter.dart';
import '../helpers/network_error.dart';
import '../helpers/salary_formatter.dart';
import '../models/job_application.dart';
import '../providers/app_state.dart';
import '../theme.dart';
import '../widgets/gestion_tag.dart';
import '../widgets/offline_banner.dart';
import '../widgets/status_chip.dart';
import 'application_edit_screen.dart';

List<String> _parseComments(String raw) {
  return raw
      .split('\n')
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .map((line) => line.startsWith('- ') ? line.substring(2) : line)
      .toList();
}

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

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    // Tras editar, AppState tiene la versión parchada; la instancia original
    // que llegó por parámetro queda obsoleta, así que se resuelve por rowIndex.
    final app = state.applications.firstWhere(
      (a) => a.rowIndex == widget.application.rowIndex,
      orElse: () => widget.application,
    );
    final comentarios = _parseComments(app.comentarios);
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
                      MaterialPageRoute(builder: (_) => ApplicationEditScreen(application: app)),
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
                if (comentarios.isNotEmpty) ...[
                  const Divider(height: 32),
                  Row(
                    children: [
                      Icon(Icons.chat_bubble_outline, size: 18, color: Theme.of(context).colorScheme.onSurfaceVariant),
                      const SizedBox(width: 6),
                      const Text('Comentarios', style: TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 8),
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
                      Icon(Icons.description_outlined, size: 18, color: Theme.of(context).colorScheme.onSurfaceVariant),
                      const SizedBox(width: 6),
                      const Text('Descripción', style: TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(app.descripcion),
                ],
                if (app.link.isNotEmpty) ...[
                  const Divider(height: 32),
                  Row(
                    children: [
                      Icon(Icons.link, size: 18, color: Theme.of(context).colorScheme.onSurfaceVariant),
                      const SizedBox(width: 6),
                      const Text('Enlace externo', style: TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: app.link));
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(const SnackBar(content: Text('Enlace copiado al portapapeles')));
                    },
                    child: Text(app.link,
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontSize: 13)),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildInfoSection(BuildContext context, JobApplication app) {
    final warningColor = Theme.of(context).brightness == Brightness.dark
        ? AppColorsDark.warning
        : AppColors.warning;

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
            Icon(Icons.people, size: 18, color: Theme.of(context).colorScheme.onSurfaceVariant),
            const SizedBox(width: 8),
            SizedBox(
              width: 100,
              child: Text('Entrevista', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13)),
            ),
            Transform.scale(
              scale: 0.6,
              child: Switch(
                value: app.entrevistaRealizada,
                onChanged: null,
                thumbColor: WidgetStateProperty.resolveWith<Color>((states) {
                  if (states.contains(WidgetState.selected)) {
                    return Theme.of(context).colorScheme.tertiary;
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
          Icon(f.$1, size: 18, color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(width: 8),
          SizedBox(
            width: 112,
            child: Text(f.$2, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13)),
          ),
          Expanded(
            child: Text(
              f.$3,
              style: TextStyle(
                fontSize: 14,
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
