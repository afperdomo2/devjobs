import '../models/job_import.dart';
import 'text_shortener.dart';

const int kMaxDescriptionChars = 3000;
const int kMaxSummaryChars = 400;
const int kMaxBulletsPerSection = 6;
const int kMaxBulletChars = 160;

const String kSummaryHeading = 'Resumen';
const String kResponsibilitiesHeading = 'Responsabilidades';
const String kRequirementsHeading = 'Requisitos';
const String kBenefitsHeading = 'Beneficios';
const String kObservationsHeading = 'Observaciones';

/// Construye un resumen Markdown a partir de las secciones que devuelve la IA.
///
/// Si la IA no trajo secciones, usa [fallbackDescription] (normalmente la
/// descripción estructurada del JSON-LD) para no dejar el campo vacío.
String? buildJobDescriptionMarkdown(
  AiJobData? ai, {
  String? fallbackDescription,
}) {
  final markdown = ai == null ? '' : _fromAi(ai);
  if (markdown.trim().isNotEmpty) return _cap(markdown);
  return buildFallbackDescriptionMarkdown(fallbackDescription);
}

/// Fallback para cuando la IA falla: convierte una descripción plana en un
/// bloque Markdown sencillo, conservando viñetas y saltos de párrafo.
String? buildFallbackDescriptionMarkdown(String? description) {
  final text = description?.trim() ?? '';
  if (text.length < 40) return null;

  var body = text
      .replaceAll(RegExp(r'^• ', multiLine: true), '- ')
      .replaceAll(RegExp(r'\r\n?'), '\n')
      .replaceAll(RegExp(r'\n{3,}'), '\n\n')
      .trim();

  if (body.isEmpty) return null;
  return _cap('## Descripción\n\n$body');
}

String _fromAi(AiJobData ai) {
  final sections = <String>[];

  final summary = ai.resumen?.trim() ?? '';
  if (summary.isNotEmpty) {
    sections.add(
      '## $kSummaryHeading\n\n${truncate(summary, kMaxSummaryChars)}',
    );
  }

  _addList(sections, kResponsibilitiesHeading, ai.responsabilidades);
  _addList(sections, kRequirementsHeading, ai.requisitos);
  _addList(sections, kBenefitsHeading, ai.beneficios);
  _addList(sections, kObservationsHeading, ai.observaciones);

  return sections.join('\n\n');
}

void _addList(List<String> sections, String heading, List<String> items) {
  final bullets = _cleanBullets(items);
  if (bullets.isEmpty) return;

  final body = bullets.map((item) => '- $item').join('\n');
  sections.add('## $heading\n\n$body');
}

List<String> _cleanBullets(List<String> items) {
  final seen = <String>{};
  final result = <String>[];

  for (final raw in items) {
    final bullet = _formatBullet(raw);
    if (bullet.isEmpty) continue;
    if (!seen.add(bullet.toLowerCase())) continue;
    result.add(bullet);
    if (result.length >= kMaxBulletsPerSection) break;
  }

  return result;
}

String _formatBullet(String raw) {
  var text = raw
      .trim()
      .replaceAll(RegExp(r'\s*\n\s*'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ');
  if (text.isEmpty) return '';

  text = text.replaceFirst(RegExp(r'^[-•*]\s+'), '');
  text = truncate(text, kMaxBulletChars);
  if (text.contains('**')) return text;

  final separator = text.indexOf(': ');
  if (separator <= 0 || separator > 40) return text;

  final label = text.substring(0, separator);
  if (label.contains('http') || label.contains('www.')) return text;

  final rest = text.substring(separator + 2);
  if (rest.isEmpty) return text;
  return '**$label:** $rest';
}

String _cap(String markdown) {
  final text = markdown.trim();
  if (text.length <= kMaxDescriptionChars) return text;

  final cut = text.lastIndexOf('\n', kMaxDescriptionChars);
  final safeCut = cut > 0 ? cut : kMaxDescriptionChars;
  return '${text.substring(0, safeCut).trimRight()}\n\n…';
}

/// Heurística para decidir si un texto debe renderizarse como Markdown.
///
/// Sirve para no romper descripciones antiguas de texto plano.
bool looksLikeMarkdown(String text) {
  if (text.trim().isEmpty) return false;
  if (text.contains('**')) return true;
  return RegExp(r'^(#{1,4} |[-*] |\d+\. )', multiLine: true).hasMatch(text);
}
