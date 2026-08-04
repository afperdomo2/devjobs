import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;

import '../helpers/date_formatter.dart';
import '../models/job_application.dart';
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
  @override
  Widget build(BuildContext context) {
    final app = widget.application;
    final comentarios = _parseComments(app.comentarios);

    return Scaffold(
      appBar: AppBar(
        title: Text(app.empresa),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Editar postulación',
            onPressed: () async {
              final result = await Navigator.push<bool>(
                context,
                MaterialPageRoute(builder: (_) => ApplicationEditScreen(application: app)),
              );
              if (result == true) {
                setState(() {});
              }
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          StatusChip(status: app.estado),
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
                Icon(Icons.chat_bubble_outline, size: 18, color: Colors.grey[600]),
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
                    Text('• ', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                    Expanded(child: Text(c, style: const TextStyle(fontSize: 14))),
                  ],
                ),
              ),
          ],
          if (app.descripcion.isNotEmpty) ...[
            const Divider(height: 32),
            Row(
              children: [
                Icon(Icons.description_outlined, size: 18, color: Colors.grey[600]),
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
                Icon(Icons.link, size: 18, color: Colors.grey[600]),
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
              child: Text(app.link, style: TextStyle(color: Colors.blue[700], fontSize: 13)),
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildInfoSection(BuildContext context, JobApplication app) {
    final baseFields = [
      (Icons.business, 'Empresa', app.empresa),
      (Icons.work_outline, 'Tipo de contrato', app.tipoContrato),
      (Icons.laptop_mac_outlined, 'Modalidad', app.modalidad),
      (Icons.location_on_outlined, 'Ciudad', app.ciudad),
      (Icons.attach_money_outlined, 'Salario ofrecido', app.salarioOfrecido),
      (Icons.calendar_today, 'F. postulación', formatDate(app.fechaPostulacion)),
      (Icons.calendar_today, 'F. seguimiento', formatDate(app.fechaSeguimiento)),
      (
        Icons.schedule,
        'Tiempo del proceso',
        app.diasProceso != null ? '${app.diasProceso} días' : '',
      ),
    ].where((f) => f.$3.isNotEmpty).map(_fieldRow).toList();

    final afterFields = [
      (Icons.person_outline, 'Contacto', app.contacto),
    ].where((f) => f.$3.isNotEmpty).map(_fieldRow).toList();

    return [
      ...baseFields,
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Icon(Icons.people, size: 18, color: Colors.grey[600]),
            const SizedBox(width: 8),
            SizedBox(
              width: 100,
              child: Text('Entrevista', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
            ),
            Transform.scale(
              scale: 0.6,
              child: Switch(
                value: app.entrevistaRealizada,
                onChanged: null,
                thumbColor: WidgetStateProperty.resolveWith<Color>((states) {
                  if (states.contains(WidgetState.selected)) {
                    return Colors.lightGreen;
                  }
                  return Colors.white;
                }),
              ),
            ),
          ],
        ),
      ),
      ...afterFields,
    ];
  }

  Widget _fieldRow((IconData, String, String) f) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(f.$1, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 8),
          SizedBox(
            width: 112,
            child: Text(f.$2, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          ),
          Expanded(child: Text(f.$3, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }
}
