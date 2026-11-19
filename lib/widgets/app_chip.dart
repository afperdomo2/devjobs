import 'package:flutter/material.dart';

import '../theme.dart';

/// Variantes visuales de [AppChip].
enum AppChipVariant {
  /// Tinte del color de estado + borde al 40 %. Usado por StatusChip.
  status,

  /// Sin tinte, borde neutro. Usado por MetaChip.
  meta,

  /// Tinte suave + borde sólido. Usado por GestionTag ("Por gestionar").
  flag,

  /// Sin fondo ni borde: solo icono + texto. Métricas de contexto en cards,
  /// para no competir visualmente con la identidad ni con los chips IA.
  plain,
}

/// Cascarón único de los chips de la app: padding, radio, tamaño de icono y
/// tipografía idénticos para las tres variantes. Los widgets de dominio
/// (StatusChip, MetaChip, GestionTag) se construyen sobre esto para que no
/// haya tres recetas visuales distintas.
class AppChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final AppChipVariant variant;
  final Color color;
  final VoidCallback? onTap;

  const AppChip({
    super.key,
    required this.icon,
    required this.label,
    required this.variant,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final (Color background, Color borderColor, FontWeight weight) =
        switch (variant) {
      AppChipVariant.status => (
          color.withValues(alpha: 0.12),
          color.withValues(alpha: 0.4),
          FontWeight.w600,
        ),
      AppChipVariant.meta => (
          Colors.transparent,
          chipBorderColor(Theme.of(context).brightness),
          FontWeight.w500,
        ),
      AppChipVariant.flag => (
          color.withValues(alpha: 0.12),
          color,
          FontWeight.w600,
        ),
      AppChipVariant.plain => (
          Colors.transparent,
          Colors.transparent,
          FontWeight.w500,
        ),
    };

    final content = Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.sm,
        vertical: AppSpace.xs,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: const BorderRadius.all(Radius.circular(AppRadius.chip)),
        border: borderColor == Colors.transparent
            ? null
            : Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: AppIconSize.chip, color: color),
          const SizedBox(width: AppSpace.xs),
          // Flexible + ellipsis: el chip nunca excede el ancho disponible.
          // Sin esto, un label largo (p. ej. una ciudad con varias sedes)
          // desborda la card, porque el Row da ancho infinito a los hijos no
          // flexibles.
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: weight,
              ),
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return content;
    return InkWell(
      onTap: onTap,
      borderRadius: const BorderRadius.all(Radius.circular(AppRadius.chip)),
      child: content,
    );
  }
}
