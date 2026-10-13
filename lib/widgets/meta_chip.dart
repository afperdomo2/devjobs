import 'package:flutter/material.dart';

import '../theme.dart';

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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: chipBorderColor(Theme.of(context).brightness),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: tint),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: tint,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
