import 'package:flutter/material.dart';

import '../helpers/company_stats.dart';
import '../helpers/date_formatter.dart';
import '../models/company_insight.dart';
import '../theme.dart';
import 'insight_tag_chip.dart';
import 'meta_chip.dart';

/// Card de una empresa en el listado.
///
/// Jerarquía (de más a menos importante):
/// 1. **Identidad**: avatar + nombre con todo el ancho disponible + chevron.
///    Nada más compite en esa fila: el nombre nunca se trunca por un chip.
/// 2. **Subtítulo**: total · activas · última actividad.
/// 3. **Fila IA** (solo con [insight]): chip de recomendación + hasta 2
///    etiquetas. Chips con fondo tintado = análisis IA.
/// 4. **Métricas planas** (`MetaChip.plain`, sin fondo): por gestionar
///    (accionable, fucsia), entrevistas y respondieron (contexto, gris).
///    El color queda reservado a la IA y a lo accionable.
class CompanyCard extends StatelessWidget {
  final CompanyStats company;
  final VoidCallback onTap;
  final CompanyInsight? insight;

  const CompanyCard({
    super.key,
    required this.company,
    required this.onTap,
    this.insight,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final muted = scheme.onSurfaceVariant;
    final brightness = Theme.of(context).brightness;
    final insightData = insight;

    // Métricas planas de contexto; solo "por gestionar" lleva color.
    final metrics = <Widget>[
      if (company.porGestionar > 0)
        MetaChip(
          icon: Icons.label_important,
          label: '${company.porGestionar} por gestionar',
          color: gestionColor(brightness),
          plain: true,
        ),
      if (company.entrevistas > 0)
        MetaChip(
          icon: Icons.record_voice_over_outlined,
          label:
              '${company.entrevistas} ${company.entrevistas == 1 ? 'entrevista' : 'entrevistas'}',
          plain: true,
        ),
      MetaChip(
        icon: Icons.check_circle_outline,
        label: '${company.conNovedad}/${company.total} respondieron',
        plain: true,
      ),
    ];

    // Fila IA: recomendación primero y luego las etiquetas destacadas.
    final iaChips = <Widget>[
      if (insightData != null) ...[
        InsightRecommendationChip(
          recomendacion: insightData.recomendacion,
        ),
        for (final id in insightData.highlightEtiquetas())
          InsightTagChip(tagId: id),
      ],
    ];

    final totalLabel =
        '${company.total} ${company.total == 1 ? 'postulación' : 'postulaciones'}';
    final activasLabel =
        '${company.activas} ${company.activas == 1 ? 'activa' : 'activas'}';
    final ultima = company.ultimaPostulacion;
    final dias = ultima == null
        ? null
        : DateTime.now().difference(ultima).inDays;
    final subtitle = [
      totalLabel,
      activasLabel,
      if (dias != null) formatSinNovedad(dias < 0 ? 0 : dias),
    ].join(' · ');

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
                if (iaChips.isNotEmpty) ...[
                  Wrap(
                    spacing: AppSpace.xs + 2,
                    runSpacing: AppSpace.xs + 2,
                    children: iaChips,
                  ),
                  const SizedBox(height: AppSpace.sm),
                ],
                Wrap(
                  spacing: AppSpace.xs + 2,
                  runSpacing: AppSpace.xs + 2,
                  children: metrics,
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
