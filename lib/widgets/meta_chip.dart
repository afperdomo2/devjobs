import 'package:flutter/material.dart';

import 'app_chip.dart';

/// Chip compacto con borde para meta-datos (icono + texto corto).
/// Se usa en las cards de postulación y en la lista de empresas.
class MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;

  /// Tinte del icono y texto. Default: gris secundario del tema.
  final Color? color;

  /// Al presionar el chip (opcional). Si es null el chip es solo informativo.
  final VoidCallback? onTap;

  /// Estilo plano (sin fondo ni borde): métricas de contexto que no deben
  /// competir con la identidad de la card ni con los chips IA.
  final bool plain;

  const MetaChip({
    super.key,
    required this.icon,
    required this.label,
    this.color,
    this.onTap,
    this.plain = false,
  });

  @override
  Widget build(BuildContext context) {
    final tint = color ?? Theme.of(context).colorScheme.onSurfaceVariant;
    return AppChip(
      icon: icon,
      label: label,
      variant: plain ? AppChipVariant.plain : AppChipVariant.meta,
      color: tint,
      onTap: onTap,
    );
  }
}
