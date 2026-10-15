import 'package:flutter/material.dart';

import '../helpers/scroll_to_top.dart';

/// Botón flotante "ir arriba" para una lista cuyo desplazamiento controla
/// [controller].
///
/// Se muestra solo cuando el usuario ya recorrió suficiente de la lista
/// (ver [shouldShowScrollToTop]) y entra/sale con un fade + scale suave.
///
/// No depende de un [Scaffold]: debe colocarse como hijo directo de un [Stack]
/// que envuelva la lista, de modo que funcione igual en pantallas con su propio
/// Scaffold que en tabs embebidas dentro de un [IndexedStack].
class ScrollToTopButton extends StatefulWidget {
  final ScrollController controller;
  final double bottom;
  final double right;

  const ScrollToTopButton({
    super.key,
    required this.controller,
    this.bottom = 16,
    this.right = 16,
  });

  @override
  State<ScrollToTopButton> createState() => _ScrollToTopButtonState();
}

class _ScrollToTopButtonState extends State<ScrollToTopButton> {
  static const _duration = Duration(milliseconds: 200);

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(ScrollToTopButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onScroll);
      widget.controller.addListener(_onScroll);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onScroll);
    super.dispose();
  }

  void _onScroll() {
    if (mounted) setState(() {});
  }

  void _scrollToTop() {
    if (!widget.controller.hasClients) return;
    widget.controller.animateTo(
      0,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final position = widget.controller.hasClients
        ? widget.controller.position
        : null;
    final visible =
        position != null &&
        shouldShowScrollToTop(
          offset: position.pixels,
          viewportHeight: position.viewportDimension,
        );

    final scheme = Theme.of(context).colorScheme;

    return Positioned(
      right: widget.right,
      bottom: widget.bottom,
      child: IgnorePointer(
        ignoring: !visible,
        child: AnimatedScale(
          scale: visible ? 1 : 0.85,
          duration: _duration,
          curve: Curves.easeOut,
          child: AnimatedOpacity(
            opacity: visible ? 1 : 0,
            duration: _duration,
            curve: Curves.easeOut,
            child: FloatingActionButton.small(
              heroTag: null,
              tooltip: 'Ir arriba',
              elevation: 3,
              backgroundColor: scheme.surface,
              foregroundColor: scheme.primary,
              shape: CircleBorder(side: BorderSide(color: scheme.outline)),
              onPressed: _scrollToTop,
              child: const Icon(Icons.keyboard_arrow_up),
            ),
          ),
        ),
      ),
    );
  }
}
