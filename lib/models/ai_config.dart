/// Configuración de la importación con IA.
///
/// Un proveedor OpenAI-compatible (`baseUrl` + `apiKey`) y una lista ordenada
/// de modelos. El orden es el orden de intento: si el primer modelo falla por
/// cuota o disponibilidad, se prueba el siguiente.
class AiConfig {
  final String baseUrl;
  final String apiKey;
  final List<String> models;

  const AiConfig({
    required this.baseUrl,
    required this.apiKey,
    required this.models,
  });

  /// Configuración vacía: la importación con IA queda desactivada.
  static const AiConfig empty = AiConfig(baseUrl: '', apiKey: '', models: []);

  factory AiConfig.fromJson(Map<String, dynamic> json) {
    return AiConfig(
      baseUrl: (json['baseUrl'] as String?)?.trim() ?? '',
      apiKey: (json['apiKey'] as String?)?.trim() ?? '',
      models: _normalizeModels(json['models']),
    );
  }

  static List<String> _normalizeModels(dynamic value) {
    if (value is! List) return const [];
    final seen = <String>{};
    final models = <String>[];
    for (final item in value) {
      if (item is! String) continue;
      final text = item.trim();
      if (text.isEmpty || !seen.add(text)) continue;
      models.add(text);
    }
    return models;
  }

  Map<String, dynamic> toJson() => {
    'baseUrl': baseUrl,
    'apiKey': apiKey,
    'models': models,
  };

  AiConfig copyWith({String? baseUrl, String? apiKey, List<String>? models}) {
    return AiConfig(
      baseUrl: baseUrl ?? this.baseUrl,
      apiKey: apiKey ?? this.apiKey,
      models: models ?? this.models,
    );
  }

  /// La IA está disponible si hay proveedor, clave y al menos un modelo.
  bool get isEnabled =>
      baseUrl.trim().isNotEmpty &&
      apiKey.trim().isNotEmpty &&
      models.isNotEmpty;

  /// Primer modelo de la lista: el que se usa por defecto.
  String get primaryModel => models.isEmpty ? '' : models.first;

  /// Host del proveedor para mostrar en la UI (p. ej. `opencode.ai`).
  String get providerHost => Uri.tryParse(baseUrl.trim())?.host ?? '';

  /// `null` si la URL es válida; un mensaje para el usuario si no.
  String? validateBaseUrl() {
    final uri = Uri.tryParse(baseUrl.trim());
    if (uri == null ||
        !uri.hasAuthority ||
        (uri.scheme != 'http' && uri.scheme != 'https')) {
      return 'La URL debe empezar por http:// o https://';
    }
    return null;
  }

  /// Primer error de validación completo; `null` si la configuración sirve.
  String? validate() {
    return validateBaseUrl() ??
        (apiKey.trim().isEmpty ? 'La API key es obligatoria' : null) ??
        (models.isEmpty ? 'Debe haber al menos un modelo' : null);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AiConfig &&
        other.baseUrl == baseUrl &&
        other.apiKey == apiKey &&
        other.models.length == models.length &&
        Iterable<int>.generate(models.length)
            .every((i) => other.models[i] == models[i]);
  }

  @override
  int get hashCode => Object.hash(baseUrl, apiKey, Object.hashAll(models));
}
