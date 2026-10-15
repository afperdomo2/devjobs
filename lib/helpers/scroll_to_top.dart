/// Decide si el botón "ir arriba" debe mostrarse para un desplazamiento dado.
///
/// Aparece cuando el usuario ya recorrió al menos [fraction] de la altura
/// visible de la lista, con un piso [minOffset] para no dispararse por un
/// desplazamiento insignificante en listas cortas o pantallas pequeñas.
bool shouldShowScrollToTop({
  required double offset,
  required double viewportHeight,
  double fraction = 0.5,
  double minOffset = 350,
}) {
  if (offset <= 0) return false;
  final threshold = viewportHeight * fraction;
  final effective = threshold > minOffset ? threshold : minOffset;
  return offset >= effective;
}
