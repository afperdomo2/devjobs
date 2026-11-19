import 'package:flutter/material.dart';

import '../models/company_insight.dart';
import '../theme.dart';

/// Color de un tono de etiqueta: verde (positivo), ámbar (negativo),
/// gris (neutral). Deliberadamente distinto del fucsia de "por gestionar".
Color insightToneColor(CompanyInsightTone tone, Brightness brightness) {
  switch (tone) {
    case CompanyInsightTone.positive:
      return successColor(brightness);
    case CompanyInsightTone.negative:
      return warningTextColor(brightness);
    case CompanyInsightTone.neutral:
      return neutralColor(brightness);
  }
}

IconData insightTagIcon(String id) {
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

IconData insightRecommendationIcon(CompanyRecommendation recomendacion) {
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

Color insightRecommendationColor(
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

/// Chip de una etiqueta de comportamiento del análisis IA.
///
/// Resuelve el vocabulario cerrado por id ("no-respuesta" o su etiqueta
/// visible); los ids desconocidos caen en un chip neutro. Con [compact]
/// muestra el label corto (para listas); el detalle usa el label completo.
class InsightTagChip extends StatelessWidget {
  final String tagId;
  final bool compact;

  const InsightTagChip({super.key, required this.tagId, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final tag = insightTagByValue(tagId) ??
        CompanyInsightTag(
          id: tagId,
          label: tagId,
          tone: CompanyInsightTone.neutral,
        );
    final color = insightToneColor(tag.tone, brightness);

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
          Icon(insightTagIcon(tag.id), size: AppIconSize.chip, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              compact ? tag.compactLabel : tag.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Chip compacto con la recomendación del análisis IA
/// (Priorizar / Seguimiento normal / Precaución / Baja prioridad).
///
/// Con [compact] muestra el label corto ("Seguimiento", "Baja"…).
class InsightRecommendationChip extends StatelessWidget {
  final CompanyRecommendation recomendacion;
  final bool compact;

  const InsightRecommendationChip({
    super.key,
    required this.recomendacion,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final color = insightRecommendationColor(recomendacion, brightness);

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
          Icon(
            insightRecommendationIcon(recomendacion),
            size: AppIconSize.chip,
            color: color,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              compact ? recomendacion.shortLabel : recomendacion.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
