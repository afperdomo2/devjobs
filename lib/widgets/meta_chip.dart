import 'package:flutter/material.dart';

import 'app_chip.dart';

/// Chip compacto con borde para meta-datos (icono + texto corto).
/// Se usa en las cards de postulación y en la lista de empresas.
class MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;

  /// Tinte del icono y texto. Default: gris secundario del tema.
  final Color? color;

  const MetaChip({
    super.key,
    required this.icon,
    required this.label,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final tint = color ?? Theme.of(context).colorScheme.onSurfaceVariant;
    return AppChip(
      icon: icon,
      label: label,
      variant: AppChipVariant.meta,
      color: tint,
    );
  }
}
