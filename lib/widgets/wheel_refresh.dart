import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../helpers/wheel_overscroll.dart';

/// Dispara [onRefresh] cuando el usuario hace "pull" con la rueda del mouse
/// estando en el tope de la lista — el equivalente en escritorio del
/// pull-to-refresh táctil. Muestra una barra de progreso fina mientras dura
/// la recarga. No añade botones ni obstaculiza el scroll normal.
class WheelRefreshIndicator extends StatefulWidget {
  final ScrollController controller;
  final Future<void> Function() onRefresh;
  final Widget child;

  const WheelRefreshIndicator({
    super.key,
    required this.controller,
    required this.onRefresh,
    required this.child,
  });

  @override
  State<WheelRefreshIndicator> createState() => _WheelRefreshIndicatorState();
}

class _WheelRefreshIndicatorState extends State<WheelRefreshIndicator> {
  final _tracker = WheelOverscrollTracker();
  bool _refreshing = false;

  Future<void> _refresh() async {
    if (_refreshing) return;
    setState(() => _refreshing = true);
    try {
      await widget.onRefresh();
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  void _onPointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent || _refreshing) return;
    final controller = widget.controller;
    if (!controller.hasClients) return;

    final position = controller.position;
    final atTop = position.pixels <= position.minScrollExtent + 0.5;
    if (_tracker.addScroll(event.scrollDelta.dy, atTop: atTop)) {
      _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerSignal: _onPointerSignal,
      child: Stack(
        children: [
          widget.child,
          if (_refreshing)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(minHeight: 2),
            ),
        ],
      ),
    );
  }
}
