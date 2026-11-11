import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/ai_config.dart';
import '../providers/app_state.dart';
import '../theme.dart';

/// Pantalla para configurar el proveedor y los modelos de la importación con IA.
///
/// Los cambios se guardan en `LocalCache` y se aplican de inmediato: la
/// siguiente importación usa la nueva lista, en el orden mostrado.
class AiSettingsScreen extends StatefulWidget {
  const AiSettingsScreen({super.key});

  @override
  State<AiSettingsScreen> createState() => _AiSettingsScreenState();
}

class _AiSettingsScreenState extends State<AiSettingsScreen> {
  late final TextEditingController _baseUrlCtrl;
  late final TextEditingController _apiKeyCtrl;
  late List<String> _models;
  bool _showApiKey = false;
  String? _baseUrlError;
  String? _apiKeyError;
  String? _modelError;

  @override
  void initState() {
    super.initState();
    final config = context.read<AppState>().aiConfig;
    _baseUrlCtrl = TextEditingController(text: config.baseUrl);
    _apiKeyCtrl = TextEditingController(text: config.apiKey);
    _models = [...config.models];
  }

  @override
  void dispose() {
    _baseUrlCtrl.dispose();
    _apiKeyCtrl.dispose();
    super.dispose();
  }

  void _clearErrors() {
    _baseUrlError = null;
    _apiKeyError = null;
    _modelError = null;
  }

  Future<void> _save() async {
    final config = AiConfig(
      baseUrl: _baseUrlCtrl.text.trim(),
      apiKey: _apiKeyCtrl.text.trim(),
      models: [..._models],
    );

    setState(() {
      _baseUrlError = config.validateBaseUrl();
      _apiKeyError = config.apiKey.isEmpty ? 'La API key es obligatoria' : null;
      _modelError = config.models.isEmpty ? 'Debe haber al menos un modelo' : null;
    });
    if (_baseUrlError != null || _apiKeyError != null || _modelError != null) {
      return;
    }

    await context.read<AppState>().updateAiConfig(config);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Configuración guardada')));
    Navigator.of(context).pop();
  }

  Future<void> _reset() async {
    await context.read<AppState>().resetAiConfig();
    if (!mounted) return;
    final config = context.read<AppState>().aiConfig;
    setState(() {
      _baseUrlCtrl.text = config.baseUrl;
      _apiKeyCtrl.text = config.apiKey;
      _models = [...config.models];
      _clearErrors();
    });
  }

  Future<void> _addModel() async {
    final value = await _promptModel(existing: _models);
    if (value == null || !mounted) return;
    setState(() {
      _models = [..._models, value];
      _modelError = null;
    });
  }

  Future<void> _editModel(int index) async {
    final others = [..._models]..removeAt(index);
    final value = await _promptModel(initial: _models[index], existing: others);
    if (value == null || !mounted) return;
    setState(() {
      final updated = [..._models];
      updated[index] = value;
      _models = updated;
      _modelError = null;
    });
  }

  void _removeModel(int index) {
    if (_models.length <= 1) return;
    setState(() {
      final updated = [..._models]..removeAt(index);
      _models = updated;
    });
  }

  void _moveModel(int index, int delta) {
    final target = index + delta;
    if (target < 0 || target >= _models.length) return;
    setState(() {
      final updated = [..._models];
      final item = updated.removeAt(index);
      updated.insert(target, item);
      _models = updated;
    });
  }

  Future<String?> _promptModel({
    String? initial,
    required List<String> existing,
  }) {
    return showDialog<String>(
      context: context,
      builder: (_) => _ModelDialog(initial: initial, existing: existing),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Importación con IA')),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.lg,
                AppSpace.lg,
                AppSpace.lg,
                AppSpace.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('PROVEEDOR', style: AppType.section(context)),
                  const SizedBox(height: AppSpace.sm),
                  TextField(
                    key: const Key('ai-base-url'),
                    controller: _baseUrlCtrl,
                    keyboardType: TextInputType.url,
                    decoration: InputDecoration(
                      labelText: 'Base URL',
                      hintText: 'https://...',
                      errorText: _baseUrlError,
                    ),
                  ),
                  const SizedBox(height: AppSpace.md),
                  TextField(
                    key: const Key('ai-api-key'),
                    controller: _apiKeyCtrl,
                    obscureText: !_showApiKey,
                    decoration: InputDecoration(
                      labelText: 'API key',
                      errorText: _apiKeyError,
                      suffixIcon: IconButton(
                        key: const Key('ai-toggle-key'),
                        tooltip: _showApiKey ? 'Ocultar clave' : 'Mostrar clave',
                        icon: Icon(
                          _showApiKey ? Icons.visibility_off : Icons.visibility,
                        ),
                        onPressed: () =>
                            setState(() => _showApiKey = !_showApiKey),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpace.xl),
                  Text('MODELOS', style: AppType.section(context)),
                  const SizedBox(height: AppSpace.xs),
                  Text(
                    'Se prueban en orden si un modelo falla.',
                    style: AppType.label(context),
                  ),
                  const SizedBox(height: AppSpace.sm),
                  if (_modelError != null) ...[
                    Text(
                      _modelError!,
                      style: TextStyle(
                        fontSize: 12,
                        color: scheme.error,
                      ),
                    ),
                    const SizedBox(height: AppSpace.xs),
                  ],
                  ..._buildModelRows(context),
                  const SizedBox(height: AppSpace.sm),
                  OutlinedButton.icon(
                    key: const Key('ai-add-model'),
                    onPressed: _addModel,
                    icon: const Icon(Icons.add),
                    label: const Text('Agregar modelo'),
                  ),
                  const SizedBox(height: AppSpace.md),
                  Container(
                    padding: const EdgeInsets.all(AppSpace.md),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(AppRadius.card),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: scheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: AppSpace.sm),
                        Expanded(
                          child: Text(
                            'El primero es el modelo principal. Si se agota su '
                            'cuota o no está disponible, se usa el siguiente.',
                            style: AppType.label(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.lg,
                AppSpace.sm,
                AppSpace.lg,
                AppSpace.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FilledButton(
                    key: const Key('ai-save'),
                    onPressed: _save,
                    child: const Text('Guardar'),
                  ),
                  TextButton(
                    key: const Key('ai-reset'),
                    onPressed: _reset,
                    child: const Text('Restablecer a los valores del .env'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildModelRows(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (_models.isEmpty) {
      return [
        Container(
          padding: const EdgeInsets.all(AppSpace.md),
          decoration: BoxDecoration(
            color: scheme.surfaceContainer,
            borderRadius: BorderRadius.circular(AppRadius.card),
          ),
          child: Text('Sin modelos. Agrega al menos uno.', style: AppType.label(context)),
        ),
      ];
    }

    return [
      for (var i = 0; i < _models.length; i++)
        Container(
          key: Key('ai-model-$i'),
          margin: const EdgeInsets.only(bottom: AppSpace.xs),
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.xs),
          decoration: BoxDecoration(
            color: scheme.surfaceContainer,
            borderRadius: BorderRadius.circular(AppRadius.chip),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 24,
                child: Text(
                  '${i + 1}',
                  textAlign: TextAlign.center,
                  style: AppType.label(context),
                ),
              ),
              const SizedBox(width: AppSpace.xs),
              Expanded(
                child: Text(
                  _models[i],
                  overflow: TextOverflow.ellipsis,
                  style: AppType.cardTitle(context),
                ),
              ),
              IconButton(
                key: Key('ai-model-up-$i'),
                tooltip: 'Subir',
                visualDensity: VisualDensity.compact,
                onPressed: i == 0 ? null : () => _moveModel(i, -1),
                icon: const Icon(Icons.arrow_upward, size: 18),
              ),
              IconButton(
                key: Key('ai-model-down-$i'),
                tooltip: 'Bajar',
                visualDensity: VisualDensity.compact,
                onPressed: i == _models.length - 1
                    ? null
                    : () => _moveModel(i, 1),
                icon: const Icon(Icons.arrow_downward, size: 18),
              ),
              IconButton(
                key: Key('ai-model-edit-$i'),
                tooltip: 'Editar',
                visualDensity: VisualDensity.compact,
                onPressed: () => _editModel(i),
                icon: const Icon(Icons.edit_outlined, size: 18),
              ),
              IconButton(
                key: Key('ai-model-delete-$i'),
                tooltip: 'Eliminar',
                visualDensity: VisualDensity.compact,
                onPressed: _models.length <= 1
                    ? null
                    : () => _removeModel(i),
                icon: Icon(
                  Icons.delete_outline,
                  size: 18,
                  color: _models.length <= 1
                      ? scheme.outline
                      : scheme.error,
                ),
              ),
            ],
          ),
        ),
    ];
  }
}

class _ModelDialog extends StatefulWidget {
  final String? initial;
  final List<String> existing;

  const _ModelDialog({this.initial, required this.existing});

  @override
  State<_ModelDialog> createState() => _ModelDialogState();
}

class _ModelDialogState extends State<_ModelDialog> {
  late final TextEditingController _ctrl;
  String? _error;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initial ?? '');
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _submit() {
    final value = _ctrl.text.trim();
    if (value.isEmpty) {
      setState(() => _error = 'Escribe el nombre del modelo');
      return;
    }
    if (widget.existing.contains(value)) {
      setState(() => _error = 'Ese modelo ya está en la lista');
      return;
    }
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.initial != null;

    return AlertDialog(
      title: Text(editing ? 'Editar modelo' : 'Agregar modelo'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            key: const Key('model-input'),
            controller: _ctrl,
            autofocus: true,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              labelText: 'Nombre del modelo',
              hintText: 'deepseek-v4.1-flash',
              errorText: _error,
            ),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: AppSpace.sm),
          Text(
            'Ej.: deepseek-v4.1-flash, glm-5.3-flash',
            style: AppType.label(context),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          key: const Key('model-submit'),
          onPressed: _submit,
          child: Text(editing ? 'Guardar' : 'Agregar'),
        ),
      ],
    );
  }
}
