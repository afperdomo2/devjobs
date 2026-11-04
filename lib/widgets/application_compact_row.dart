import 'package:flutter/material.dart';

import '../models/job_application.dart';
import '../theme.dart';

/// Fila compacta para listas dentro de tarjetas (seguimiento, agenda).
///
/// Muestra empresa y vacante, un texto opcional a la derecha y un chevron.
/// No reutiliza [ApplicationCard] para evitar cards anidadas.
class ApplicationCompactRow extends StatelessWidget {
  final JobApplication application;
  final VoidCallback onTap;
  final String? trailingLabel;
  final Color? trailingColor;
  final IconData? leadingIcon;
  final Color? leadingColor;

  const ApplicationCompactRow({
    super.key,
    required this.application,
    required this.onTap,
    this.trailingLabel,
    this.trailingColor,
    this.leadingIcon,
    this.leadingColor,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      label: '${application.empresa}. ${application.vacante}',
      child: InkWell(
        onTap: onTap,
        borderRadius: const BorderRadius.all(Radius.circular(AppRadius.chip)),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.xs,
            vertical: AppSpace.sm,
          ),
          child: Row(
            children: [
              if (leadingIcon != null) ...[
                Icon(
                  leadingIcon,
                  size: AppIconSize.row,
                  color: leadingColor ?? scheme.onSurfaceVariant,
                ),
                const SizedBox(width: AppSpace.sm),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      application.empresa,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (application.vacante.trim().isNotEmpty) ...[
                      const SizedBox(height: 1),
                      Text(
                        application.vacante,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailingLabel != null) ...[
                const SizedBox(width: AppSpace.sm),
                Text(
                  trailingLabel!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: trailingColor ?? scheme.onSurfaceVariant,
                        fontWeight:
                            trailingColor != null ? FontWeight.w600 : null,
                      ),
                ),
              ],
              const SizedBox(width: AppSpace.xs),
              Icon(
                Icons.chevron_right,
                size: 16,
                color: scheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
