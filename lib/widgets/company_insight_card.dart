import 'package:flutter/material.dart';

import '../helpers/date_formatter.dart';
import '../models/company_insight.dart';
import '../theme.dart';
import 'ai_badge.dart';
import 'insight_tag_chip.dart';

/// Tarjeta del análisis IA de una empresa.
///
/// Modos:
/// - **Completo** (por defecto): todo el análisis sin cortes — es lo que se
///   ve en el detalle de la empresa, sin "ver más".
/// - **Colapsable** ([collapsible]): vista previa con chips compactos y el
///   resumen recortado a [resumenMaxLines]; **"Ver más"** expande el análisis
///   completo inline (acordeón, sin modales ni navegación) y **"Ver menos"**
///   vuelve a la vista previa.
///
/// [showCard] = false renderiza sin el contenedor `Card` (para bloques
/// planos como el del detalle de la vacante). [title] personaliza el rótulo.
class CompanyInsightCard extends StatefulWidget {
  final CompanyInsight? insight;
  final bool aiEnabled;
  final bool stale;
  final bool loading;
  final bool offline;
  final String? error;
  final VoidCallback? onAnalyze;
  final String title;
  final bool collapsible;
  final bool showCard;
  final int resumenMaxLines;

  const CompanyInsightCard({
    super.key,
    this.insight,
    this.aiEnabled = false,
    this.stale = false,
    this.loading = false,
    this.offline = false,
    this.error,
    this.onAnalyze,
    this.title = 'Análisis IA',
    this.collapsible = false,
    this.showCard = true,
    this.resumenMaxLines = 3,
  });

  @override
  State<CompanyInsightCard> createState() => _CompanyInsightCardState();
}

class _CompanyInsightCardState extends State<CompanyInsightCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final insight = widget.insight;
    if (insight == null && !widget.aiEnabled) return const SizedBox.shrink();

    final brightness = Theme.of(context).brightness;

    final content = Padding(
      padding: widget.showCard ? const EdgeInsets.all(16) : EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flexible(
                child: Text(widget.title, style: AppType.section(context)),
              ),
              const SizedBox(width: AppSpace.sm),
              const AiBadge(),
            ],
          ),
          const SizedBox(height: AppSpace.md),
          if (insight == null)
            _EmptyState(
              loading: widget.loading,
              offline: widget.offline,
              error: widget.error,
              onAnalyze: widget.onAnalyze,
            )
          else ...[
            if (widget.stale)
              _StaleBanner(brightness: brightness, loading: widget.loading),
            if (widget.stale) const SizedBox(height: AppSpace.md),
            if (widget.loading) ...[
              const _ProgressRow(label: 'Reanalizando vacantes y notas…'),
              const SizedBox(height: AppSpace.md),
            ],
            if (widget.error != null) ...[
              _ErrorText(widget.error!),
              const SizedBox(height: AppSpace.md),
            ],
            if (widget.collapsible && !_expanded) ...[
              _PreviewContent(
                insight: insight,
                maxResumenLines: widget.resumenMaxLines,
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => setState(() => _expanded = true),
                  icon: const Icon(Icons.expand_more, size: AppIconSize.row),
                  label: const Text('Ver más'),
                ),
              ),
            ] else ...[
              if (insight.etiquetas.isNotEmpty) ...[
                _TagRow(ids: insight.etiquetas),
                const SizedBox(height: AppSpace.md),
              ],
              if (insight.resumen.isNotEmpty) ...[
                Text(
                  insight.resumen,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        height: 1.45,
                      ),
                ),
                const SizedBox(height: AppSpace.md),
              ],
              if (insight.fortalezas.isNotEmpty) ...[
                _BulletList(
                  icon: Icons.check_circle_outline,
                  color: successColor(brightness),
                  title: 'Señales positivas',
                  items: insight.fortalezas,
                ),
                const SizedBox(height: AppSpace.md),
              ],
              if (insight.riesgos.isNotEmpty) ...[
                _BulletList(
                  icon: Icons.warning_amber_outlined,
                  color: warningTextColor(brightness),
                  title: 'A tener en cuenta',
                  items: insight.riesgos,
                ),
                const SizedBox(height: AppSpace.md),
              ],
              _RecommendationBlock(
                recomendacion: insight.recomendacion,
                brightness: brightness,
              ),
              if (insight.perfilVacantes.isNotEmpty) ...[
                const SizedBox(height: AppSpace.sm),
                _ExpandableSection(
                  title: 'Perfil de vacantes',
                  child: Text(insight.perfilVacantes),
                ),
              ],
              if (insight.procesoSeleccion.isNotEmpty) ...[
                _ExpandableSection(
                  title: 'Proceso de selección',
                  child: Text(insight.procesoSeleccion),
                ),
              ],
              if (insight.contactos.isNotEmpty) ...[
                _ExpandableSection(
                  title: 'Contactos',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final contacto in insight.contactos)
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpace.xs),
                          child: Text('• $contacto'),
                        ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: AppSpace.md),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      insight.fechaAnalisis == null
                          ? 'Análisis guardado'
                          : 'Analizado el '
                              '${formatDateValueShort(insight.fechaAnalisis!)}',
                      style: AppType.label(context),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: (widget.loading || widget.offline)
                        ? null
                        : widget.onAnalyze,
                    icon: const Icon(Icons.refresh, size: AppIconSize.row),
                    label: const Text('Reanalizar'),
                  ),
                ],
              ),
              if (widget.collapsible)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => setState(() => _expanded = false),
                    icon: const Icon(Icons.expand_less, size: AppIconSize.row),
                    label: const Text('Ver menos'),
                  ),
                ),
            ],
          ],
        ],
      ),
    );

    return widget.showCard ? Card(child: content) : content;
  }
}

/// Vista previa del análisis: chips compactos + resumen recortado.
class _PreviewContent extends StatelessWidget {
  final CompanyInsight insight;
  final int maxResumenLines;

  const _PreviewContent({
    required this.insight,
    required this.maxResumenLines,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppSpace.xs + 2,
          runSpacing: AppSpace.xs + 2,
          children: [
            InsightRecommendationChip(
              recomendacion: insight.recomendacion,
              compact: true,
            ),
            for (final id in insight.highlightEtiquetas())
              InsightTagChip(tagId: id, compact: true),
          ],
        ),
        if (insight.resumen.isNotEmpty) ...[
          const SizedBox(height: AppSpace.sm),
          Text(
            insight.resumen,
            maxLines: maxResumenLines,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  height: 1.45,
                ),
          ),
        ],
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool loading;
  final bool offline;
  final String? error;
  final VoidCallback? onAnalyze;

  const _EmptyState({
    required this.loading,
    required this.offline,
    required this.error,
    required this.onAnalyze,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Genera un perfil del comportamiento de la empresa a partir de sus '
          'vacantes, notas y novedades: quién responde, cuánto tarda, si da '
          'retroalimentación y qué esperar de su proceso.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.45),
        ),
        const SizedBox(height: AppSpace.md),
        if (loading) ...[
          const _ProgressRow(label: 'Analizando vacantes y notas…'),
        ] else ...[
          if (error != null) ...[
            _ErrorText(error!),
            const SizedBox(height: AppSpace.md),
          ],
          FilledButton.icon(
            onPressed: (offline || onAnalyze == null) ? null : onAnalyze,
            icon: const Icon(Icons.auto_awesome, size: AppIconSize.row),
            label: const Text('Analizar con IA'),
          ),
          if (offline) ...[
            const SizedBox(height: AppSpace.sm),
            Text(
              'Conecta a internet para analizar.',
              style: AppType.label(context).copyWith(
                    color: warningTextColor(brightness),
                  ),
            ),
          ],
        ],
      ],
    );
  }
}

class _ProgressRow extends StatelessWidget {
  final String label;

  const _ProgressRow({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        const SizedBox(width: AppSpace.sm),
        Expanded(child: Text(label, style: AppType.label(context))),
      ],
    );
  }
}

class _ErrorText extends StatelessWidget {
  final String message;

  const _ErrorText(this.message);

  @override
  Widget build(BuildContext context) {
    return Text(
      message,
      style: TextStyle(
        color: dangerColor(Theme.of(context).brightness),
        fontSize: 13,
      ),
    );
  }
}

class _StaleBanner extends StatelessWidget {
  final Brightness brightness;
  final bool loading;

  const _StaleBanner({required this.brightness, required this.loading});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.md,
        vertical: AppSpace.sm,
      ),
      decoration: BoxDecoration(
        color: warningContainer(brightness),
        borderRadius: const BorderRadius.all(Radius.circular(AppRadius.chip)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber_outlined,
            size: AppIconSize.chip,
            color: warningTextColor(brightness),
          ),
          const SizedBox(width: AppSpace.sm),
          Expanded(
            child: Text(
              loading
                  ? 'Analizando con los datos más recientes…'
                  : 'Datos desactualizados: hay novedades desde el análisis.',
              style: TextStyle(
                fontSize: 12,
                color: warningTextColor(brightness),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TagRow extends StatelessWidget {
  final List<String> ids;

  const _TagRow({required this.ids});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpace.xs + 2,
      runSpacing: AppSpace.xs + 2,
      children: [for (final id in ids) InsightTagChip(tagId: id)],
    );
  }
}

class _BulletList extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final List<String> items;

  const _BulletList({
    required this.icon,
    required this.color,
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: AppIconSize.chip, color: color),
            const SizedBox(width: 6),
            Text(
              title,
              style: AppType.label(context).copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
        const SizedBox(height: AppSpace.xs + 2),
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpace.xs),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('•', style: TextStyle(color: color, height: 1.4)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    item,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(height: 1.4),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _RecommendationBlock extends StatelessWidget {
  final CompanyRecommendation recomendacion;
  final Brightness brightness;

  const _RecommendationBlock({
    required this.recomendacion,
    required this.brightness,
  });

  @override
  Widget build(BuildContext context) {
    final color = insightRecommendationColor(recomendacion, brightness);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.md,
        vertical: AppSpace.sm,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: const BorderRadius.all(Radius.circular(AppRadius.chip)),
      ),
      child: Row(
        children: [
          Icon(
            insightRecommendationIcon(recomendacion),
            size: AppIconSize.metric,
            color: color,
          ),
          const SizedBox(width: AppSpace.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Recomendación', style: AppType.label(context)),
                Text(
                  recomendacion.label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpandableSection extends StatelessWidget {
  final String title;
  final Widget child;

  const _ExpandableSection({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(
          left: AppSpace.xs,
          bottom: AppSpace.md,
        ),
        dense: true,
        iconColor: scheme.onSurfaceVariant,
        title: Text(title, style: AppType.label(context)),
        children: [
          DefaultTextStyle(
            style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(height: 1.45) ??
                const TextStyle(),
            child: child,
          ),
        ],
      ),
    );
  }
}
