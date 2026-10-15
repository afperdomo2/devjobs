import 'package:flutter/material.dart';

import '../theme.dart';

/// Etiqueta del flag "Por gestionar". Es un indicador; si recibe [onTap]
/// funciona como toggle (se usa en las cards de postulación).
class GestionTag extends StatelessWidget {
  final VoidCallback? onTap;

  const GestionTag({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = gestionColor(Theme.of(context).brightness);
    final content = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.label_important, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            'Por gestionar',
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return content;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: content,
    );
  }
}
