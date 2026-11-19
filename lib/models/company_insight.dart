import '../helpers/comments.dart';
import '../helpers/date_formatter.dart';
import '../helpers/text_normalizer.dart';

/// Recomendación sobre qué tan conveniente es seguir postulando a la empresa.
enum CompanyRecommendation {
  priorizar('Priorizar'),
  seguimientoNormal('Seguimiento normal'),
  bajaPrioridad('Baja prioridad'),
  precaucion('Precaución');

  final String label;

  const CompanyRecommendation(this.label);

  /// Acepta la etiqueta ("Precaución") o el id (`precaucion`), sin depender
  /// de mayúsculas ni tildes. Cualquier valor desconocido cae en
  /// [CompanyRecommendation.seguimientoNormal] para no inventar un juicio.
  static CompanyRecommendation parse(String raw) {
    final value = normalizeText(raw);
    if (value.isEmpty) return CompanyRecommendation.seguimientoNormal;
    for (final item in CompanyRecommendation.values) {
      if (value == normalizeText(item.label) ||
          value == normalizeText(item.name)) {
        return item;
      }
    }
    return CompanyRecommendation.seguimientoNormal;
  }
}

/// Tono visual de una etiqueta de comportamiento.
enum CompanyInsightTone { positive, negative, neutral }

/// Etiqueta de comportamiento del vocabulario cerrado del análisis de empresa.
class CompanyInsightTag {
  final String id;
  final String label;
  final CompanyInsightTone tone;

  const CompanyInsightTag({
    required this.id,
    required this.label,
    required this.tone,
  });
}

/// Vocabulario cerrado de etiquetas. La IA solo puede elegir de aquí; las
/// etiquetas fuera de vocabulario se descartan al mapear.
const kCompanyInsightTags = <CompanyInsightTag>[
  CompanyInsightTag(
    id: 'no-respuesta',
    label: 'No responde',
    tone: CompanyInsightTone.negative,
  ),
  CompanyInsightTag(
    id: 'respuesta-lenta',
    label: 'Respuesta lenta',
    tone: CompanyInsightTone.negative,
  ),
  CompanyInsightTag(
    id: 'respuesta-rapida',
    label: 'Respuesta rápida',
    tone: CompanyInsightTone.positive,
  ),
  CompanyInsightTag(
    id: 'con-feedback',
    label: 'Da feedback',
    tone: CompanyInsightTone.positive,
  ),
  CompanyInsightTag(
    id: 'sin-feedback',
    label: 'Sin feedback',
    tone: CompanyInsightTone.negative,
  ),
  CompanyInsightTag(
    id: 'proceso-agil',
    label: 'Proceso ágil',
    tone: CompanyInsightTone.positive,
  ),
  CompanyInsightTag(
    id: 'proceso-largo',
    label: 'Proceso largo',
    tone: CompanyInsightTone.negative,
  ),
  CompanyInsightTag(
    id: 'vacantes-estancadas',
    label: 'Vacantes estancadas',
    tone: CompanyInsightTone.negative,
  ),
  CompanyInsightTag(
    id: 'reclutamiento-serio',
    label: 'Reclutamiento serio',
    tone: CompanyInsightTone.positive,
  ),
  CompanyInsightTag(
    id: 'salario-transparente',
    label: 'Salario transparente',
    tone: CompanyInsightTone.positive,
  ),
  CompanyInsightTag(
    id: 'pide-prueba',
    label: 'Pide pruebas',
    tone: CompanyInsightTone.neutral,
  ),
  CompanyInsightTag(
    id: 'publica-frecuente',
    label: 'Publica seguido',
    tone: CompanyInsightTone.neutral,
  ),
];

/// Busca una etiqueta por id o por etiqueta visible ("No responde"),
/// insensible a mayúsculas y tildes. `null` si no está en el vocabulario.
CompanyInsightTag? insightTagByValue(String raw) {
  final value = normalizeText(raw);
  if (value.isEmpty) return null;
  for (final tag in kCompanyInsightTags) {
    if (value == normalizeText(tag.id) || value == normalizeText(tag.label)) {
      return tag;
    }
  }
  return null;
}

/// Datos generados por la IA sobre el comportamiento de una empresa.
///
/// Una fila por empresa en la pestaña `EmpresaAnalisis` de la Sheet.
class CompanyInsight {
  /// Nombre de la empresa como aparece en la hoja (para mostrar).
  final String empresa;

  /// Cuándo se generó el análisis.
  final DateTime? fechaAnalisis;

  /// Última novedad incluida en el análisis. Sirve para detectar que el
  /// análisis quedó desactualizado.
  final DateTime? datosAl;

  /// Nº de postulaciones consideradas en el análisis (también staleness).
  final int totalPostulaciones;

  /// Ids canónicos de [kCompanyInsightTags] (ver [insightTagByValue]).
  final List<String> etiquetas;

  final CompanyRecommendation recomendacion;

  /// Síntesis en 2–4 frases: quiénes son, cómo reclutan, qué esperar.
  final String resumen;

  /// Señales positivas concretas ("Siempre responde").
  final List<String> fortalezas;

  /// Señales negativas o a tener en cuenta ("Nunca dan feedback").
  final List<String> riesgos;

  /// Patrones de sus vacantes: roles, contratos, modalidades, salarios.
  final String perfilVacantes;

  /// Cómo es su proceso según las notas: etapas, pruebas, tiempos.
  final String procesoSeleccion;

  /// Personas mencionadas ("Laura — reclutadora, responde por email").
  final List<String> contactos;

  const CompanyInsight({
    required this.empresa,
    this.fechaAnalisis,
    this.datosAl,
    this.totalPostulaciones = 0,
    this.etiquetas = const [],
    this.recomendacion = CompanyRecommendation.seguimientoNormal,
    this.resumen = '',
    this.fortalezas = const [],
    this.riesgos = const [],
    this.perfilVacantes = '',
    this.procesoSeleccion = '',
    this.contactos = const [],
  });

  /// Clave de comparación: minúsculas, sin acentos ni espacios sobrantes.
  String get key => normalizeText(empresa);

  /// Etiquetas a destacar en listas compactas (máx. [max]): primero las
  /// negativas (la señal más accionable), luego las positivas y al final
  /// las neutras, conservando el orden del vocabulario dentro de cada tono.
  List<String> highlightEtiquetas({int max = 2}) {
    final sorted = <String>[];
    for (final tone in const [
      CompanyInsightTone.negative,
      CompanyInsightTone.positive,
      CompanyInsightTone.neutral,
    ]) {
      for (final id in etiquetas) {
        if (insightTagByValue(id)?.tone == tone) sorted.add(id);
      }
    }
    return sorted.length > max ? sorted.sublist(0, max) : sorted;
  }

  factory CompanyInsight.fromJson(Map<String, dynamic> json) {
    return CompanyInsight(
      empresa: (json['empresa'] as String? ?? '').trim(),
      fechaAnalisis: parseDate(json['fechaAnalisis']?.toString() ?? ''),
      datosAl: parseDate(json['datosAl']?.toString() ?? ''),
      totalPostulaciones:
          int.tryParse(json['totalPostulaciones']?.toString() ?? '') ?? 0,
      etiquetas: _parseEtiquetas(json['etiquetas']?.toString() ?? ''),
      recomendacion:
          CompanyRecommendation.parse(json['recomendacion']?.toString() ?? ''),
      resumen: (json['resumen'] as String? ?? '').trim(),
      fortalezas: parseComments(json['fortalezas']?.toString() ?? ''),
      riesgos: parseComments(json['riesgos']?.toString() ?? ''),
      perfilVacantes: (json['perfilVacantes'] as String? ?? '').trim(),
      procesoSeleccion: (json['procesoSeleccion'] as String? ?? '').trim(),
      contactos: parseComments(json['contactos']?.toString() ?? ''),
    );
  }

  /// Versión tolerante: `null` si el registro no parece un análisis de
  /// empresa (p.ej. filas de postulaciones devueltas por un script viejo).
  static CompanyInsight? tryFromJson(Map<String, dynamic> json) {
    final hasInsightKey = json.containsKey('etiquetas') ||
        json.containsKey('recomendacion') ||
        json.containsKey('resumen') ||
        json.containsKey('perfilVacantes');
    if (!hasInsightKey) return null;
    final insight = CompanyInsight.fromJson(json);
    return insight.empresa.isEmpty ? null : insight;
  }

  /// Formato de la hoja: fechas ISO (`yyyy-MM-dd` para Apps Script), listas
  /// como líneas `- item` y etiquetas separadas por coma con su etiqueta
  /// visible ("No responde, Da feedback").
  Map<String, dynamic> toJson() {
    return {
      'empresa': empresa,
      'fechaAnalisis':
          fechaAnalisis == null ? '' : formatApiDate(fechaAnalisis!),
      'datosAl': datosAl == null ? '' : formatApiDate(datosAl!),
      'totalPostulaciones': totalPostulaciones,
      'etiquetas': etiquetas
          .map((id) => insightTagByValue(id)?.label ?? id)
          .join(', '),
      'recomendacion': recomendacion.label,
      'resumen': resumen,
      'fortalezas': _encodeLines(fortalezas),
      'riesgos': _encodeLines(riesgos),
      'perfilVacantes': perfilVacantes,
      'procesoSeleccion': procesoSeleccion,
      'contactos': _encodeLines(contactos),
    };
  }
}

/// Etiquetas guardadas como "No responde, Da feedback" (o ids) -> ids canónicos.
/// Los valores fuera de vocabulario se descartan.
List<String> _parseEtiquetas(String raw) {
  final seen = <String>{};
  final out = <String>[];
  for (final part in raw.split(',')) {
    final tag = insightTagByValue(part);
    if (tag == null) continue;
    if (seen.add(tag.id)) out.add(tag.id);
  }
  return out;
}

String _encodeLines(List<String> lines) {
  return [
    for (final line in lines)
      '- ${line.replaceAll(RegExp(r'\s*\n\s*'), ' ').trim()}',
  ].join('\n');
}
