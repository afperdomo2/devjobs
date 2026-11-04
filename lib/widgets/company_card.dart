import 'package:flutter/material.dart';

import '../helpers/company_stats.dart';
import '../helpers/date_formatter.dart';
import '../theme.dart';
import 'meta_chip.dart';

/// Card de una empresa en el listado: identidad, actividad reciente y chips
/// con las señales que importan (pendientes, entrevistas, activas y respuestas).
class CompanyCard extends StatelessWidget {
  final CompanyStats company;
  final VoidCallback onTap;

  const CompanyCard({super.key, required this.company, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final muted = scheme.onSurfaceVariant;
    final brightness = Theme.of(context).brightness;

    final chips = <Widget>[
      if (company.porGestionar > 0)
        MetaChip(
          icon: Icons.label_important,
          label: '${company.porGestionar} por gestionar',
          color: gestionColor(brightness),
        ),
      if (company.entrevistas > 0)
        MetaChip(
          icon: Icons.record_voice_over_outlined,
          label:
              '${company.entrevistas} ${company.entrevistas == 1 ? 'entrevista' : 'entrevistas'}',
          color: statusColor('entrevista', brightness),
        ),
      MetaChip(
        icon: Icons.notifications_active_outlined,
        label:
            '${company.activas} ${company.activas == 1 ? 'activa' : 'activas'}',
        color: tealColor(brightness),
      ),
      MetaChip(
        icon: Icons.check_circle_outline,
        label: '${company.conNovedad}/${company.total} respondieron',
        color: infoColor(brightness),
      ),
    ];

    final totalLabel =
        '${company.total} ${company.total == 1 ? 'postulación' : 'postulaciones'}';
    final ultima = company.ultimaPostulacion;
    final dias = ultima == null
        ? null
        : DateTime.now().difference(ultima).inDays;
    final subtitle = dias == null
        ? totalLabel
        : '$totalLabel · ${formatSinNovedad(dias < 0 ? 0 : dias)}';

    final resumen = [
      totalLabel,
      '${company.activas} activas',
      if (company.entrevistas > 0) '${company.entrevistas} entrevistas',
      if (company.porGestionar > 0) '${company.porGestionar} por gestionar',
    ].join(', ');

    return Semantics(
      label: '${company.nombre}. $resumen',
      child: Card(
        child: InkWell(
          onTap: onTap,
          borderRadius:
              const BorderRadius.all(Radius.circular(AppRadius.card)),
          child: Padding(
            padding: const EdgeInsets.all(AppSpace.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _CompanyAvatar(nombre: company.nombre),
                    const SizedBox(width: AppSpace.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            company.nombre,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppType.cardTitle(context),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: muted),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right, color: scheme.primary),
                  ],
                ),
                const SizedBox(height: AppSpace.md - 2),
                Wrap(
                  spacing: AppSpace.xs + 2,
                  runSpacing: AppSpace.xs + 2,
                  children: chips,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CompanyAvatar extends StatelessWidget {
  final String nombre;

  const _CompanyAvatar({required this.nombre});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final initial = nombre.trim().isEmpty
        ? '?'
        : nombre.trim().characters.first.toUpperCase();
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Text(
        initial,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          color: scheme.primary,
        ),
      ),
    );
  }
}
