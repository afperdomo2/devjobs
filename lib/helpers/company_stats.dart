import '../models/job_application.dart';
import 'date_formatter.dart';

/// Métricas agregadas de postulaciones por empresa.
class CompanyStats {
  /// Nombre de la empresa (trimmeado).
  final String nombre;

  /// Total de postulaciones a la empresa.
  final int total;

  /// Postulaciones cuyo proceso sigue en curso.
  final int activas;

  /// Postulaciones finalizadas (aceptada, rechazada o retirada).
  final int finalizadas;

  /// Postulaciones con fecha de seguimiento registrada (respuesta/novedad).
  final int conNovedad;

  /// Postulaciones con entrevista realizada.
  final int entrevistas;

  /// Postulaciones marcadas con el flag "Por gestionar".
  final int porGestionar;

  /// Promedio de días de cierre: media de [JobApplication.diasProceso] solo
  /// sobre finalizadas con seguimiento. null si no hay datos suficientes
  /// (se excluyen activas y finalizadas sin seguimiento para no
  /// subestimar el tiempo real de respuesta).
  final int? promedioDias;

  /// Fecha de postulación más reciente a la empresa.
  final DateTime? ultimaPostulacion;

  const CompanyStats({
    required this.nombre,
    required this.total,
    required this.activas,
    required this.finalizadas,
    required this.conNovedad,
    required this.entrevistas,
    required this.porGestionar,
    this.promedioDias,
    this.ultimaPostulacion,
  });
}

/// Agrupa las postulaciones por empresa y calcula sus métricas,
/// ordenadas por nº de postulaciones (descendente; empate alfabético).
///
/// La agrupación es insensible a mayúsculas y espacios: "Acme", "ACME" y
/// " Acme " caen en el mismo grupo. El nombre mostrado es la variante
/// original más frecuente (empate → la que ordena primero).
List<CompanyStats> companiesStats(List<JobApplication> apps) {
  final buckets = <String, _CompanyBucket>{};
  for (final a in apps) {
    final raw = a.empresa.trim();
    if (raw.isEmpty) continue;
    final bucket = buckets.putIfAbsent(raw.toLowerCase(), _CompanyBucket.new);
    bucket.apps.add(a);
    bucket.nameCounts[raw] = (bucket.nameCounts[raw] ?? 0) + 1;
  }

  final stats = <CompanyStats>[];
  for (final bucket in buckets.values) {
    final list = bucket.apps;

    var activas = 0;
    var finalizadas = 0;
    var conNovedad = 0;
    var entrevistas = 0;
    var porGestionar = 0;
    var sumaCierre = 0;
    var cuentaCierre = 0;
    DateTime? ultima;

    for (final a in list) {
      if (a.isFinalizado) {
        finalizadas++;
      } else {
        activas++;
      }

      if (parseDate(a.fechaSeguimiento) != null) conNovedad++;
      if (a.entrevistaRealizada) entrevistas++;
      if (a.porGestionar) porGestionar++;

      // Solo finalizadas con seguimiento aportan al promedio de cierre.
      final dias = a.isFinalizado ? a.diasProceso : null;
      if (dias != null) {
        sumaCierre += dias;
        cuentaCierre++;
      }

      final post = parseDate(a.fechaPostulacion);
      if (post != null && (ultima == null || post.isAfter(ultima))) {
        ultima = post;
      }
    }

    stats.add(CompanyStats(
      nombre: _displayName(bucket.nameCounts),
      total: list.length,
      activas: activas,
      finalizadas: finalizadas,
      conNovedad: conNovedad,
      entrevistas: entrevistas,
      porGestionar: porGestionar,
      promedioDias: cuentaCierre == 0 ? null : (sumaCierre / cuentaCierre).round(),
      ultimaPostulacion: ultima,
    ));
  }

  stats.sort((a, b) {
    final c = b.total.compareTo(a.total);
    if (c != 0) return c;
    return a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase());
  });
  return stats;
}

class _CompanyBucket {
  final List<JobApplication> apps = [];
  final Map<String, int> nameCounts = {};
}

String _displayName(Map<String, int> counts) {
  var best = '';
  var bestCount = -1;
  for (final entry in counts.entries) {
    final better = entry.value > bestCount ||
        (entry.value == bestCount && entry.key.compareTo(best) < 0);
    if (better) {
      best = entry.key;
      bestCount = entry.value;
    }
  }
  return best;
}
