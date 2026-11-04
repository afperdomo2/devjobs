import 'package:flutter/material.dart';

import '../theme.dart';
import 'app_chip.dart';

/// Etiqueta del flag "Por gestionar". Es un indicador; si recibe [onTap]
/// funciona como toggle (se usa en las cards de postulación).
class GestionTag extends StatelessWidget {
  final VoidCallback? onTap;

  const GestionTag({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return AppChip(
      icon: Icons.label_important,
      label: 'Por gestionar',
      variant: AppChipVariant.flag,
      color: gestionColor(Theme.of(context).brightness),
      onTap: onTap,
    );
  }
}
