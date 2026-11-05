import 'package:flutter/material.dart';

import '../theme.dart';

/// Encabezado + contenido de una sección dentro de un formulario.
///
/// Agrupa campos relacionados sin esconderlos (a diferencia de un acordeón),
/// manteniendo el formulario completo visible en un solo scroll.
class FormSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final List<Widget> children;

  const FormSection({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(icon, size: AppIconSize.row, color: scheme.onSurfaceVariant),
            const SizedBox(width: AppSpace.sm),
            Expanded(child: Text(title, style: AppType.section(context))),
            ?trailing,
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: AppSpace.xs),
          Text(subtitle!, style: AppType.label(context)),
        ],
        const SizedBox(height: AppSpace.md),
        ...children,
      ],
    );
  }
}
