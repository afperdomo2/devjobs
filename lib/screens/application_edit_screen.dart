import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/job_application.dart';
import '../providers/app_state.dart';

const _tiposContrato = [
  'Tiempo completo',
  'Tiempo Parcial',
  'Por proyecto',
  'Temporal',
  'Freelance',
  'Otro',
];

const _modalidades = ['Remoto', 'Híbrido', 'Presencial', 'Otro'];

const _estados = [
  'Enviada',
  'En revisión',
  'Entrevista agendada',
  'Entrevista realizada',
  'Prueba técnica',
  'Oferta recibida',
  'Rechazada',
  'Sin respuesta',
  'Aceptada',
  'Retirada',
];

class ApplicationEditScreen extends StatefulWidget {
  final JobApplication application;

  const ApplicationEditScreen({super.key, required this.application});

  @override
  State<ApplicationEditScreen> createState() => _ApplicationEditScreenState();
}

class _ApplicationEditScreenState extends State<ApplicationEditScreen> {
  late final TextEditingController _empresaCtrl;
  late final TextEditingController _vacanteCtrl;
  late final TextEditingController _ciudadCtrl;
  late final TextEditingController _salarioCtrl;
  late final TextEditingController _linkCtrl;
  late final TextEditingController _descripcionCtrl;
  late final TextEditingController _contactoCtrl;
  late final TextEditingController _comentariosCtrl;

  late String _tipoContrato;
  late String _modalidad;
  late String _estado;
  late bool _entrevistaRealizada;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final app = widget.application;
    _empresaCtrl = TextEditingController(text: app.empresa);
    _vacanteCtrl = TextEditingController(text: app.vacante);
    _ciudadCtrl = TextEditingController(text: app.ciudad);
    _salarioCtrl = TextEditingController(text: app.salarioOfrecido);
    _linkCtrl = TextEditingController(text: app.link);
    _descripcionCtrl = TextEditingController(text: app.descripcion);
    _contactoCtrl = TextEditingController(text: app.contacto);
    _comentariosCtrl = TextEditingController(text: app.comentarios);
    _tipoContrato = app.tipoContrato;
    _modalidad = app.modalidad;
    _estado = app.estado;
    _entrevistaRealizada = app.entrevistaRealizada;
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
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);

    try {
      await context.read<AppState>().updateApplication(
        widget.application.rowIndex,
        {
          'empresa': _empresaCtrl.text,
          'vacante': _vacanteCtrl.text,
          'tipoContrato': _tipoContrato,
          'modalidad': _modalidad,
          'ciudad': _ciudadCtrl.text,
          'salarioOfrecido': _salarioCtrl.text,
          'estado': _estado,
          'link': _linkCtrl.text,
          'descripcion': _descripcionCtrl.text,
          'contacto': _contactoCtrl.text,
          'comentarios': _comentariosCtrl.text,
          'entrevistaRealizada': _entrevistaRealizada.toString(),
        },
      );

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  List<DropdownMenuItem<String>> _buildDropdownItems(
    List<String> options,
    String currentValue,
  ) {
    final values = options.contains(currentValue) ? options : [currentValue, ...options];
    return values.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList();
  }

  @override
  Widget build(BuildContext context) {
    final app = widget.application;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar postulación'),
      ),
      body: Form(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _empresaCtrl,
              decoration: const InputDecoration(labelText: 'Empresa'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _vacanteCtrl,
              decoration: const InputDecoration(labelText: 'Vacante'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _tipoContrato,
              decoration: const InputDecoration(labelText: 'Tipo de contrato'),
              items: _buildDropdownItems(_tiposContrato, app.tipoContrato),
              onChanged: (v) {
                if (v != null) setState(() => _tipoContrato = v);
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _modalidad,
              decoration: const InputDecoration(labelText: 'Modalidad'),
              items: _buildDropdownItems(_modalidades, app.modalidad),
              onChanged: (v) {
                if (v != null) setState(() => _modalidad = v);
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _ciudadCtrl,
              decoration: const InputDecoration(labelText: 'Ciudad'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _salarioCtrl,
              decoration: const InputDecoration(labelText: 'Salario ofrecido'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _estado,
              decoration: const InputDecoration(labelText: 'Estado'),
              items: _buildDropdownItems(_estados, app.estado),
              onChanged: (v) {
                if (v != null) setState(() => _estado = v);
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _linkCtrl,
              decoration: const InputDecoration(labelText: 'Link'),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descripcionCtrl,
              decoration: const InputDecoration(labelText: 'Descripción'),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _contactoCtrl,
              decoration: const InputDecoration(labelText: 'Contacto'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _comentariosCtrl,
              decoration: const InputDecoration(labelText: 'Comentarios'),
              maxLines: 3,
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Entrevista realizada'),
              value: _entrevistaRealizada,
              onChanged: (v) => setState(() => _entrevistaRealizada = v),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _saving ? null : _save,
              icon: const Icon(Icons.save),
              label: Text(_saving ? 'Guardando...' : 'Guardar cambios'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
