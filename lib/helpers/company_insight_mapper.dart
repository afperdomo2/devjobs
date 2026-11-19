import '../models/company_insight.dart';
import '../models/job_import.dart';

/// Límites del análisis generado: guardas para que un modelo verboso no
/// infle la fila de la hoja.
const int kInsightMaxEtiquetas = 4;
const int kInsightMaxItems = 5;
const int kInsightMaxItemLength = 160;
const int kInsightMaxText = 600;
const int kInsightMaxContactos = 3;
const int kInsightMaxContactoLength = 120;

/// Convierte el JSON que devuelve la IA en un [CompanyInsight] validado.
///
/// - Las etiquetas fuera del vocabulario cerrado se descartan.
/// - La recomendación desconocida cae en "Seguimiento normal".
/// - Los textos y listas se recortan a los límites de arriba.
///
/// Lanza [JobImportException] si el análisis viene vacío: no tiene sentido
/// guardar una fila sin contenido.
CompanyInsight mapAiCompanyInsight(
  Map<String, dynamic> json, {
  required String empresa,
  required DateTime? fechaAnalisis,
  required DateTime? datosAl,
  required int totalPostulaciones,
}) {
  final etiquetas = _mapEtiquetas(json['etiquetas']);
  final resumen = _readText(json['resumen']);
  final fortalezas = _readItems(json['fortalezas']);
  final riesgos = _readItems(json['riesgos']);
  final perfilVacantes = _readText(json['perfilVacantes']);
  final procesoSeleccion = _readText(json['procesoSeleccion']);
  final contactos = _readItems(
    json['contactos'],
    maxItems: kInsightMaxContactos,
    maxLength: kInsightMaxContactoLength,
  );

  if (etiquetas.isEmpty &&
      resumen.isEmpty &&
      fortalezas.isEmpty &&
      riesgos.isEmpty &&
      perfilVacantes.isEmpty &&
      procesoSeleccion.isEmpty &&
      contactos.isEmpty) {
    throw const JobImportException(
      JobImportErrorKind.invalidResponse,
      'La IA devolvió un análisis vacío. Intenta de nuevo.',
    );
  }

  return CompanyInsight(
    empresa: empresa.trim(),
    fechaAnalisis: fechaAnalisis,
    datosAl: datosAl,
    totalPostulaciones: totalPostulaciones,
    etiquetas: etiquetas,
    recomendacion:
        CompanyRecommendation.parse(json['recomendacion']?.toString() ?? ''),
    resumen: resumen,
    fortalezas: fortalezas,
    riesgos: riesgos,
    perfilVacantes: perfilVacantes,
    procesoSeleccion: procesoSeleccion,
    contactos: contactos,
  );
}

/// Etiquetas del vocabulario cerrado, sin duplicados y con tope.
List<String> _mapEtiquetas(dynamic value) {
  final seen = <String>{};
  final out = <String>[];

  void add(dynamic item) {
    if (item is String) {
      final tag = insightTagByValue(item);
      if (tag != null && seen.add(tag.id)) out.add(tag.id);
    } else if (item is List) {
      for (final child in item) {
        add(child);
      }
    } else if (item is Map) {
      for (final child in item.values) {
        add(child);
      }
    }
  }

  if (value is String) {
    for (final part in value.split(',')) {
      add(part);
    }
  } else {
    add(value);
  }

  return out.length > kInsightMaxEtiquetas
      ? out.sublist(0, kInsightMaxEtiquetas)
      : out;
}

/// Texto único recortado a [kInsightMaxText] (acepta listas: usa el primero).
String _readText(dynamic value, {int max = kInsightMaxText}) {
  if (value is String) return _clip(value, max);
  if (value is List) {
    for (final item in value) {
      if (item is String && item.trim().isNotEmpty) {
        return _clip(item, max);
      }
    }
  }
  return '';
}

/// Lista de frases recortada en cantidad y longitud. Acepta
/// `["frase"]` o `{"clave": "valor"}` como hace el extractor de vacantes.
List<String> _readItems(
  dynamic value, {
  int maxItems = kInsightMaxItems,
  int maxLength = kInsightMaxItemLength,
}) {
  final items = <String>[];

  void add(dynamic item) {
    if (items.length >= maxItems) return;
    if (item is String) {
      final text = _clip(item, maxLength);
      if (text.isNotEmpty) items.add(text);
    } else if (item is List) {
      for (final child in item) {
        add(child);
      }
    } else if (item is Map) {
      for (final child in item.values) {
        add(child);
      }
    }
  }

  add(value);

  final seen = <String>{};
  return [
    for (final item in items)
      if (seen.add(item.toLowerCase())) item,
  ];
}

String _clip(String raw, int max) {
  final text = raw.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (text.length <= max) return text;
  return text.substring(0, max).trimRight();
}
