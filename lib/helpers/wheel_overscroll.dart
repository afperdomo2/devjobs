/// Acumula los deltas de la rueda del mouse cuando el scrollable está en su
/// tope superior. Cuando la acumulación supera el umbral, indica que debe
/// dispararse el refresh (equivalente desktop del pull-to-refresh táctil).
class WheelOverscrollTracker {
  WheelOverscrollTracker({this.threshold = 180});

  /// Distancia acumulada (en píxeles de scroll) necesaria para disparar.
  final double threshold;

  double _accumulated = 0;

  /// [dy] es el `scrollDelta.dy` de un `PointerScrollEvent`
  /// (negativo = rueda hacia arriba / hacia el inicio de la lista).
  /// [atTop] indica que el scrollable está en su offset mínimo.
  ///
  /// Devuelve `true` cuando se supera el umbral y debe ejecutarse el refresh.
  bool addScroll(double dy, {required bool atTop}) {
    if (dy < 0 && atTop) {
      _accumulated += -dy;
      if (_accumulated >= threshold) {
        _accumulated = 0;
        return true;
      }
    } else {
      _accumulated = 0;
    }
    return false;
  }

  void reset() {
    _accumulated = 0;
  }
}
