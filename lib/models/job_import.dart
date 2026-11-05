import 'job_application.dart';

/// Tipo de página que se encontró al abrir un enlace de vacante.
enum JobPageKind { detail, listing, spa, blocked, notAJob, unknown }

/// Estado de una importación asistida.
enum JobImportStatus { success, partial, needsText, failed }

/// Errores esperados al consultar la IA.
enum JobImportErrorKind {
  network,
  timeout,
  unauthorized,
  quota,
  server,
  invalidResponse,
  unknown,
}

/// Datos crudos que devuelve el modelo. Todos los campos son opcionales:
/// el modelo tiene instrucciones de usar `null` cuando el dato no aparece.
class AiJobData {
  final String? empresa;
  final String? vacante;
  final String? tipoContrato;
  final String? modalidad;
  final String? ciudad;
  final String? salarioTexto;
  final String? resumen;
  final List<String> responsabilidades;
  final List<String> requisitos;
  final List<String> beneficios;
  final List<String> observaciones;
  final String? contacto;
  final List<String> datosClave;

  const AiJobData({
    this.empresa,
    this.vacante,
    this.tipoContrato,
    this.modalidad,
    this.ciudad,
    this.salarioTexto,
    this.resumen,
    this.responsabilidades = const [],
    this.requisitos = const [],
    this.beneficios = const [],
    this.observaciones = const [],
    this.contacto,
    this.datosClave = const [],
  });

  factory AiJobData.fromJson(Map<String, dynamic> json) {
    String? readString(String key) {
      final value = json[key];
      if (value is String) {
        final text = value.trim();
        return text.isEmpty ? null : text;
      }
      if (value is num) return value.toString();
      if (value is List) {
        for (final item in value) {
          if (item is String && item.trim().isNotEmpty) return item.trim();
        }
      }
      return null;
    }

    return AiJobData(
      empresa: readString('empresa'),
      vacante: readString('vacante'),
      tipoContrato: readString('tipoContrato'),
      modalidad: readString('modalidad'),
      ciudad: readString('ciudad'),
      salarioTexto: readString('salarioTexto'),
      resumen: readString('resumen'),
      responsabilidades: _readStringList(json['responsabilidades']),
      requisitos: _readStringList(json['requisitos']),
      beneficios: _readStringList(json['beneficios']),
      observaciones: _readStringList(json['observaciones']),
      contacto: readString('contacto'),
      datosClave: _readStringList(json['datosClave']),
    );
  }

  /// Acepta `["Inglés B2"]` o `{"ingles": "B2", "beneficios": ["..."]}`.
  /// El modelo a veces devuelve un objeto aunque se le pida un array.
  static List<String> _readStringList(dynamic value) {
    final items = <String>[];

    void add(dynamic item) {
      if (item is String) {
        final text = item.trim();
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
}

/// Resultado de leer una página: datos estructurados (JSON-LD), texto visible
/// y una clasificación para decidir si vale la pena llamar a la IA.
class ParsedJobPage {
  final JobPageKind kind;
  final String text;
  final String? title;
  final String? company;
  final String? city;
  final String? employmentType;
  final String? salaryText;
  final String? description;
  final String? warning;
  final bool hasJobPosting;

  const ParsedJobPage({
    required this.kind,
    required this.text,
    this.title,
    this.company,
    this.city,
    this.employmentType,
    this.salaryText,
    this.description,
    this.warning,
    this.hasJobPosting = false,
  });
}

/// Resultado listo para aplicar al formulario.
class JobImportResult {
  final JobImportStatus status;
  final Map<String, String> fields;
  final Set<String> importedFields;
  final List<String> warnings;
  final String? message;
  final JobApplication? duplicate;
  final String source;
  final JobPageKind kind;

  const JobImportResult({
    required this.status,
    required this.fields,
    required this.importedFields,
    required this.warnings,
    this.message,
    this.duplicate,
    this.source = '',
    this.kind = JobPageKind.detail,
  });

  int get filledCount => importedFields.length;

  bool get hasData =>
      fields.entries.any((e) => e.key != 'link' && e.value.trim().isNotEmpty);
}

class JobImportException implements Exception {
  final JobImportErrorKind kind;
  final String message;

  const JobImportException(this.kind, this.message);

  @override
  String toString() => message;
}
