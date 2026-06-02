import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/job_application.dart';
import '../services/sheets_api_service.dart';
import '../widgets/status_chip.dart';

class ApplicationDetailScreen extends StatefulWidget {
  final SheetsApiService apiService;
  final JobApplication application;

  const ApplicationDetailScreen({
    super.key,
    required this.apiService,
    required this.application,
  });

  @override
  State<ApplicationDetailScreen> createState() => _ApplicationDetailScreenState();
}

class _ApplicationDetailScreenState extends State<ApplicationDetailScreen> {
  final List<String> _estados = [
    'Enviada',
    'En revisión',
    'Entrevista realizada',
    'Oferta recibida',
    'Rechazada',
  ];

  late String _selectedEstado;
  bool _updating = false;

  @override
  void initState() {
    super.initState();
    _selectedEstado = widget.application.estado;
  }

  Future<void> _updateEstado(String nuevoEstado) async {
    setState(() => _updating = true);
    try {
      await widget.apiService.updateRow(widget.application.rowIndex, {
        'estado': nuevoEstado,
      });
      if (mounted) {
        setState(() {
          _selectedEstado = nuevoEstado;
          _updating = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _updating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = widget.application;
    return Scaffold(
      appBar: AppBar(title: Text(app.empresa)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          StatusChip(status: _selectedEstado.isNotEmpty ? _selectedEstado : app.estado),
          if (_updating)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: LinearProgressIndicator(),
            ),
          const SizedBox(height: 8),
          Text(
            app.vacante,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          _buildInfoSection(context, app),

          if (_selectedEstado.isNotEmpty) ...[
            const Divider(height: 32),
            const Text('Cambiar estado', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _selectedEstado,
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
              items: _estados
                  .map(
                    (e) => DropdownMenuItem(value: e, child: Row(children: [StatusChip(status: e)])),
                  )
                  .toList(),
              onChanged: _updating
                  ? null
                  : (v) {
                      if (v != null && v != _selectedEstado) _updateEstado(v);
                    },
            ),
          ],

          if (app.descripcion.isNotEmpty) ...[
            const Divider(height: 32),
            const Text('Descripción', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(app.descripcion),
          ],

          if (app.link.isNotEmpty) ...[
            const Divider(height: 32),
            const Text('Enlace externo', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: app.link));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Enlace copiado al portapapeles')),
                );
              },
              child: Text(app.link, style: TextStyle(color: Colors.blue[700], fontSize: 13)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoSection(BuildContext context, JobApplication app) {
    final fields = [
      ('Empresa', app.empresa),
      ('Tipo de contrato', app.tipoContrato),
      ('Modalidad', app.modalidad),
      ('Ciudad', app.ciudad),
      ('Salario ofrecido', app.salarioOfrecido),
      ('Fecha postulación', app.fechaPostulacion),
      ('Fecha seguimiento', app.fechaSeguimiento),
      ('Contacto', app.contacto),
    ].where((f) => f.$2.isNotEmpty);

    return Column(
      children: fields.map((f) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 120,
                child: Text(
                  f.$1,
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
              ),
              Expanded(child: Text(f.$2, style: const TextStyle(fontSize: 14))),
            ],
          ),
        );
      }).toList(),
    );
  }
}
