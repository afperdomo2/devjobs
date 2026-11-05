import 'dart:math' as math;

import '../models/job_application.dart';
import 'date_formatter.dart';

/// Métricas agregadas de postulaciones por plataforma (dominio del enlace).
class PlatformStats {
  /// Nombre visible de la plataforma (variante original más frecuente).
  final String nombre;

  /// Total de postulaciones hechas desde esta plataforma.
  final int total;

  /// Fecha de la aplicación más reciente en esta plataforma.
  final DateTime? ultimaPostulacion;

  const PlatformStats({
    required this.nombre,
    required this.total,
    this.ultimaPostulacion,
  });

  /// Días transcurridos desde la última aplicación. null si ninguna de las
  /// postulaciones de la plataforma tiene una fecha válida.
  int? diasDesdeUltima(DateTime now) {
    final ultima = ultimaPostulacion;
    if (ultima == null) return null;
    return math.max(0, now.difference(ultima).inDays);
  }
}

/// Criterios de orden del listado de plataformas.
enum PlatformSortMode {
  /// Más postulaciones primero (por defecto).
  total,

  /// Última aplicación más reciente primero.
  recent,

  /// Más días desde la última aplicación primero (la más antigua).
  oldest,
}

/// Agrupa las postulaciones por [JobApplication.plataforma] (derivada del
/// enlace) y calcula el total y la última aplicación de cada una.
///
/// La agrupación es insensible a mayúsculas y espacios; el nombre mostrado es
/// la variante original más frecuente (empate → la que ordena primero). Las
/// postulaciones sin enlace no aportan plataforma y se omiten.
///
/// El resultado llega ordenado por [PlatformSortMode.total].
List<PlatformStats> platformsStats(List<JobApplication> apps) {
  final buckets = <String, _PlatformBucket>{};
  for (final app in apps) {
    final raw = app.plataforma.trim();
    if (raw.isEmpty) continue;
    final bucket = buckets.putIfAbsent(raw.toLowerCase(), _PlatformBucket.new);
    bucket.count++;
    bucket.nameCounts[raw] = (bucket.nameCounts[raw] ?? 0) + 1;

    final fecha = parseDate(app.fechaPostulacion);
    if (fecha != null &&
        (bucket.ultima == null || fecha.isAfter(bucket.ultima!))) {
      bucket.ultima = fecha;
    }
  }

  final stats = <PlatformStats>[
    for (final bucket in buckets.values)
      PlatformStats(
        nombre: _displayName(bucket.nameCounts),
        total: bucket.count,
        ultimaPostulacion: bucket.ultima,
      ),
  ];

  return sortPlatforms(stats, PlatformSortMode.total);
}

/// Devuelve una copia ordenada de [platforms] según [mode].
///
/// En todos los modos, las plataformas sin fecha quedan al final y el
/// desempate es por total (descendente) y luego alfabético.
List<PlatformStats> sortPlatforms(
  List<PlatformStats> platforms,
  PlatformSortMode mode,
) {
  final sorted = List<PlatformStats>.of(platforms);
  sorted.sort((a, b) {
    final primary = switch (mode) {
      PlatformSortMode.total => b.total.compareTo(a.total),
      PlatformSortMode.recent => _compareDates(
        a.ultimaPostulacion,
        b.ultimaPostulacion,
        ascending: false,
      ),
      PlatformSortMode.oldest => _compareDates(
        a.ultimaPostulacion,
        b.ultimaPostulacion,
        ascending: true,
      ),
    };
    if (primary != 0) return primary;

    final byTotal = b.total.compareTo(a.total);
    if (byTotal != 0) return byTotal;
    return a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase());
  });
  return sorted;
}

int _compareDates(DateTime? a, DateTime? b, {required bool ascending}) {
  if (a == null && b == null) return 0;
  if (a == null) return 1;
  if (b == null) return -1;
  return ascending ? a.compareTo(b) : b.compareTo(a);
}

class _PlatformBucket {
  int count = 0;
  DateTime? ultima;
  final Map<String, int> nameCounts = {};
}

String _displayName(Map<String, int> counts) {
  var best = '';
  var bestCount = -1;
  for (final entry in counts.entries) {
    final better =
        entry.value > bestCount ||
        (entry.value == bestCount && entry.key.compareTo(best) < 0);
    if (better) {
      best = entry.key;
      bestCount = entry.value;
    }
  }
  return best;
}
