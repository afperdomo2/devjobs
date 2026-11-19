import '../models/company_insight.dart';
import '../models/job_application.dart';
import 'comments.dart';
import 'date_formatter.dart';
import 'salary_insights.dart';
import 'status.dart';

/// Hechos calculados en Dart sobre las postulaciones de una empresa.
///
/// Se envían al prompt como datos verificables para que la IA se dedique a la
/// síntesis cualitativa y no a "hacer matemáticas".
class CompanyAnalysisFacts {
  final int total;
  final int activas;
  final int finalizadas;
  final int conRespuesta;
  final int entrevistas;
  final int porGestionar;

  /// Activas sin novedad desde hace [kUmbralDiasSinNovedad] días o más.
  final int estancadas;

  /// Notas registradas en `comentarios` (líneas `- fecha: texto`).
  final int notas;

  /// Días promedio desde la postulación hasta la primera respuesta
  /// (postulaciones con respuesta y fecha de seguimiento).
  final int? promedioDiasRespuesta;

  /// Días promedio de cierre (finalizadas con seguimiento).
  final int? promedioCierre;

  /// Resumen salarial por moneda (COP/USD).
  final List<SalaryGroup> salarios;

  /// Conteo de postulaciones por plataforma (enlace vacío => 'sin enlace').
  final Map<String, int> plataformas;

  /// Fecha más reciente del historial (seguimiento o postulación).
  final DateTime? ultimaNovedad;

  const CompanyAnalysisFacts({
    required this.total,
    required this.activas,
    required this.finalizadas,
    required this.conRespuesta,
    required this.entrevistas,
    required this.porGestionar,
    required this.estancadas,
    required this.notas,
    required this.promedioDiasRespuesta,
    required this.promedioCierre,
    required this.salarios,
    required this.plataformas,
    required this.ultimaNovedad,
  });
}

/// Fecha más reciente del historial de [apps]: seguimiento, postulación o
/// fecha de cualquier nota (`- d/M/yyyy: texto`).
DateTime? ultimaNovedadDe(List<JobApplication> apps) {
  DateTime? ultima;

  void consider(DateTime? date) {
    if (date == null) return;
    final current = ultima;
    if (current == null || date.isAfter(current)) {
      ultima = date;
    }
  }

  for (final a in apps) {
    consider(parseDate(a.fechaSeguimiento) ?? parseDate(a.fechaPostulacion));
    for (final note in parseComments(a.comentarios)) {
      consider(_noteDate(note));
    }
  }
  return ultima;
}

final _noteDateRegex = RegExp(r'^(\d{1,2}/\d{1,2}/\d{4})');

/// Fecha del prefijo de una nota (`2/11/2026: Me llamaron`), si lo tiene.
DateTime? _noteDate(String line) {
  final match = _noteDateRegex.firstMatch(line.trim());
  return match == null ? null : parseDate(match[1]!);
}

/// Calcula los hechos deterministas de [apps] (las postulaciones de una
/// empresa). [now] se puede fijar para tests determinísticos.
CompanyAnalysisFacts companyAnalysisFacts(
  List<JobApplication> apps, {
  DateTime? now,
}) {
  final clock = now ?? DateTime.now();

  var activas = 0;
  var finalizadas = 0;
  var conRespuesta = 0;
  var entrevistas = 0;
  var porGestionar = 0;
  var estancadas = 0;
  var notas = 0;
  var sumaRespuesta = 0;
  var cuentaRespuesta = 0;
  var sumaCierre = 0;
  var cuentaCierre = 0;
  final plataformas = <String, int>{};

  for (final a in apps) {
    if (a.isFinalizado) {
      finalizadas++;
    } else {
      activas++;
      final dias = a.diasSinNovedadEn(clock);
      if (dias != null && dias >= kUmbralDiasSinNovedad) estancadas++;
    }

    if (hasResponse(a.estado)) conRespuesta++;
    if (a.entrevistaRealizada) entrevistas++;
    if (a.porGestionar) porGestionar++;
    notas += parseComments(a.comentarios).length;

    final post = parseDate(a.fechaPostulacion);
    final seg = parseDate(a.fechaSeguimiento);

    // Días hasta la primera respuesta: solo postulaciones con respuesta y
    // fecha de seguimiento (el mismo criterio en todas las empresas).
    if (hasResponse(a.estado) && post != null && seg != null) {
      sumaRespuesta += _daysBetween(post, seg);
      cuentaRespuesta++;
    }
    if (a.isFinalizado && post != null && seg != null) {
      sumaCierre += _daysBetween(post, seg);
      cuentaCierre++;
    }

    final plataforma =
        a.plataforma.trim().isEmpty ? 'sin enlace' : a.plataforma.trim();
    plataformas[plataforma] = (plataformas[plataforma] ?? 0) + 1;
  }

  return CompanyAnalysisFacts(
    total: apps.length,
    activas: activas,
    finalizadas: finalizadas,
    conRespuesta: conRespuesta,
    entrevistas: entrevistas,
    porGestionar: porGestionar,
    estancadas: estancadas,
    notas: notas,
    promedioDiasRespuesta:
        cuentaRespuesta == 0 ? null : (sumaRespuesta / cuentaRespuesta).round(),
    promedioCierre:
        cuentaCierre == 0 ? null : (sumaCierre / cuentaCierre).round(),
    salarios: salaryInsights(apps),
    plataformas: plataformas,
    ultimaNovedad: ultimaNovedadDe(apps),
  );
}

int _daysBetween(DateTime from, DateTime to) {
  final days = to.difference(from).inDays;
  return days < 0 ? 0 : days;
}

/// true si el análisis quedó desactualizado: hay postulaciones nuevas o
/// novedades posteriores a las que se tuvieron en cuenta al generarlo.
bool isInsightStale(CompanyInsight insight, List<JobApplication> apps) {
  if (insight.totalPostulaciones != apps.length) return true;

  final ultima = ultimaNovedadDe(apps);
  if (ultima == null) return false;
  if (insight.datosAl == null) return true;
  return ultima.isAfter(insight.datosAl!);
}
