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
