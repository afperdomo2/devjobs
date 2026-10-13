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
    this.promedioDias,
    this.ultimaPostulacion,
  });
}

/// Agrupa las postulaciones por empresa y calcula sus métricas,
/// ordenadas por nº de postulaciones (descendente; empate alfabético).
List<CompanyStats> companiesStats(List<JobApplication> apps) {
  final byCompany = <String, List<JobApplication>>{};
  for (final a in apps) {
    final name = a.empresa.trim();
    if (name.isEmpty) continue;
    byCompany.putIfAbsent(name, () => []).add(a);
  }

  final stats = <CompanyStats>[];
  for (final entry in byCompany.entries) {
    final list = entry.value;

    var activas = 0;
    var finalizadas = 0;
    var conNovedad = 0;
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
      nombre: entry.key,
      total: list.length,
      activas: activas,
      finalizadas: finalizadas,
      conNovedad: conNovedad,
      promedioDias: cuentaCierre == 0 ? null : (sumaCierre / cuentaCierre).round(),
      ultimaPostulacion: ultima,
    ));
  }

  stats.sort((a, b) {
    final c = b.total.compareTo(a.total);
    if (c != 0) return c;
    return a.nombre.compareTo(b.nombre);
  });
  return stats;
}
