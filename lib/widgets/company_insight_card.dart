import 'package:flutter/material.dart';

import '../helpers/date_formatter.dart';
import '../models/company_insight.dart';
import '../theme.dart';
import 'ai_badge.dart';

/// Tarjeta "Análisis IA" del detalle de empresa.
///
/// Sin análisis y con IA configurada ofrece "Analizar con IA"; con análisis
/// muestra etiquetas de comportamiento, resumen, señales, recomendación y
/// secciones expandibles. Si hay novedades desde el análisis, avisa que está
/// desactualizado y ofrece "Reanalizar".
class CompanyInsightCard extends StatelessWidget {
  final CompanyInsight? insight;
  final bool aiEnabled;
  final bool stale;
  final bool loading;
  final bool offline;
  final String? error;
  final VoidCallback? onAnalyze;

  const CompanyInsightCard({
    super.key,
    this.insight,
    this.aiEnabled = false,
    this.stale = false,
    this.loading = false,
    this.offline = false,
    this.error,
    this.onAnalyze,
  });

  @override
  Widget build(BuildContext context) {
    if (insight == null && !aiEnabled) return const SizedBox.shrink();

    final brightness = Theme.of(context).brightness;
    final current = insight;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Análisis IA', style: AppType.section(context)),
                const SizedBox(width: AppSpace.sm),
                const AiBadge(),
              ],
            ),
            const SizedBox(height: AppSpace.md),
            if (current == null)
              _EmptyState(
                loading: loading,
                offline: offline,
                error: error,
                onAnalyze: onAnalyze,
              )
            else ...[
              if (stale)
                _StaleBanner(brightness: brightness, loading: loading),
              if (stale) const SizedBox(height: AppSpace.md),
              if (loading) ...[
                const _ProgressRow(label: 'Reanalizando vacantes y notas…'),
                const SizedBox(height: AppSpace.md),
              ],
              if (error != null) ...[
                _ErrorText(error!),
                const SizedBox(height: AppSpace.md),
              ],
              if (current.etiquetas.isNotEmpty) ...[
                _TagRow(ids: current.etiquetas),
                const SizedBox(height: AppSpace.md),
              ],
              if (current.resumen.isNotEmpty) ...[
                Text(
                  current.resumen,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        height: 1.45,
                      ),
                ),
                const SizedBox(height: AppSpace.md),
              ],
              if (current.fortalezas.isNotEmpty) ...[
                _BulletList(
                  icon: Icons.check_circle_outline,
                  color: successColor(brightness),
                  title: 'Señales positivas',
                  items: current.fortalezas,
                ),
                const SizedBox(height: AppSpace.md),
              ],
              if (current.riesgos.isNotEmpty) ...[
                _BulletList(
                  icon: Icons.warning_amber_outlined,
                  color: warningTextColor(brightness),
                  title: 'A tener en cuenta',
                  items: current.riesgos,
                ),
                const SizedBox(height: AppSpace.md),
              ],
              _RecommendationBlock(
                recomendacion: current.recomendacion,
                brightness: brightness,
              ),
              if (current.perfilVacantes.isNotEmpty) ...[
                const SizedBox(height: AppSpace.sm),
                _ExpandableSection(
                  title: 'Perfil de vacantes',
                  child: Text(current.perfilVacantes),
                ),
              ],
              if (current.procesoSeleccion.isNotEmpty) ...[
                _ExpandableSection(
                  title: 'Proceso de selección',
                  child: Text(current.procesoSeleccion),
                ),
              ],
              if (current.contactos.isNotEmpty) ...[
                _ExpandableSection(
                  title: 'Contactos',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final contacto in current.contactos)
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
                      current.fechaAnalisis == null
                          ? 'Análisis guardado'
                          : 'Analizado el '
                              '${formatDateValueShort(current.fechaAnalisis!)}',
                      style: AppType.label(context),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: (loading || offline) ? null : onAnalyze,
                    icon: const Icon(Icons.refresh, size: AppIconSize.row),
                    label: const Text('Reanalizar'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
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
    final brightness = Theme.of(context).brightness;
    return Wrap(
      spacing: AppSpace.xs + 2,
      runSpacing: AppSpace.xs + 2,
      children: [
        for (final id in ids)
          _TagChip(
            tag: insightTagByValue(id) ??
                CompanyInsightTag(
                  id: id,
                  label: id,
                  tone: CompanyInsightTone.neutral,
                ),
            brightness: brightness,
          ),
      ],
    );
  }
}

class _TagChip extends StatelessWidget {
  final CompanyInsightTag tag;
  final Brightness brightness;

  const _TagChip({required this.tag, required this.brightness});

  @override
  Widget build(BuildContext context) {
    final color = _toneColor(tag.tone, brightness);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: const BorderRadius.all(Radius.circular(AppRadius.chip)),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_tagIcon(tag.id), size: AppIconSize.chip, color: color),
          const SizedBox(width: 4),
          Text(
            tag.label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
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
    final color = _recommendationColor(recomendacion, brightness);
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
            _recommendationIcon(recomendacion),
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

Color _toneColor(CompanyInsightTone tone, Brightness brightness) {
  switch (tone) {
    case CompanyInsightTone.positive:
      return successColor(brightness);
    case CompanyInsightTone.negative:
      return warningTextColor(brightness);
    case CompanyInsightTone.neutral:
      return neutralColor(brightness);
  }
}

IconData _tagIcon(String id) {
  switch (id) {
    case 'no-respuesta':
      return Icons.notifications_off_outlined;
    case 'respuesta-lenta':
      return Icons.hourglass_bottom;
    case 'respuesta-rapida':
      return Icons.bolt_outlined;
    case 'con-feedback':
      return Icons.forum_outlined;
    case 'sin-feedback':
      return Icons.sms_failed_outlined;
    case 'proceso-agil':
      return Icons.speed_outlined;
    case 'proceso-largo':
      return Icons.timeline_outlined;
    case 'vacantes-estancadas':
      return Icons.pause_circle_outline;
    case 'reclutamiento-serio':
      return Icons.verified_user_outlined;
    case 'salario-transparente':
      return Icons.payments_outlined;
    case 'pide-prueba':
      return Icons.assignment_outlined;
    case 'publica-frecuente':
      return Icons.campaign_outlined;
    default:
      return Icons.label_outlined;
  }
}

IconData _recommendationIcon(CompanyRecommendation recomendacion) {
  switch (recomendacion) {
    case CompanyRecommendation.priorizar:
      return Icons.star_outline;
    case CompanyRecommendation.seguimientoNormal:
      return Icons.schedule_send_outlined;
    case CompanyRecommendation.bajaPrioridad:
      return Icons.low_priority;
    case CompanyRecommendation.precaucion:
      return Icons.warning_amber_outlined;
  }
}

Color _recommendationColor(
  CompanyRecommendation recomendacion,
  Brightness brightness,
) {
  switch (recomendacion) {
    case CompanyRecommendation.priorizar:
      return successColor(brightness);
    case CompanyRecommendation.seguimientoNormal:
      return infoColor(brightness);
    case CompanyRecommendation.bajaPrioridad:
      return neutralColor(brightness);
    case CompanyRecommendation.precaucion:
      return warningTextColor(brightness);
  }
}
