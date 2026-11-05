import 'text_normalizer.dart';

/// Normaliza un estado para compararlo sin depender de mayúsculas, tildes
/// ni espacios sobrantes. Así 'En revisión' y 'en revision' son lo mismo.
String normalizeStatus(String status) => normalizeText(status);

/// true si el estado continúa en curso y ya no avanzará por sí solo.
bool isTerminalStatus(String status) {
  final normalized = normalizeStatus(status);
  return normalized == 'aceptada' ||
      normalized == 'rechazada' ||
      normalized == 'retirada';
}

/// true si el estado indica una entrevista agendada (aún no realizada).
///
/// Tolera variantes como "Entrevista agendada (virtual)".
bool isInterviewScheduled(String status) {
  return normalizeStatus(status).contains('entrevista agendada');
}

/// true si la empresa ya dio alguna respuesta.
///
/// Se excluyen los estados que todavía no implican respuesta:
/// `Enviada`, `Sin respuesta` y `Retirada`. Cualquier otro estado cuenta,
/// incluida `Rechazada`.
bool hasResponse(String status) {
  final normalized = normalizeStatus(status);
  if (normalized.isEmpty) return false;
  return normalized != 'enviada' &&
      normalized != 'sin respuesta' &&
      normalized != 'retirada';
}
