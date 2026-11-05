import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:url_launcher/url_launcher.dart';

import '../helpers/job_description_markdown.dart';
import '../helpers/text_normalizer.dart';
import '../theme.dart';

/// Renderiza la descripción de una postulación.
///
/// Las descripciones nuevas vienen en Markdown (resumen por secciones). Las
/// antiguas son texto plano y se siguen mostrando tal cual para no romperlas.
class MarkdownDescription extends StatelessWidget {
  final String data;
  final void Function(Uri uri)? onTapLink;

  const MarkdownDescription({super.key, required this.data, this.onTapLink});

  @override
  Widget build(BuildContext context) {
    final text = data.trim();
    if (text.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    if (!looksLikeMarkdown(text)) {
      return Text(
        text,
        style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
      );
    }

    final bodyStyle = theme.textTheme.bodyMedium?.copyWith(height: 1.45);
    final styleSheet = MarkdownStyleSheet.fromTheme(theme).copyWith(
      p: bodyStyle,
      pPadding: const EdgeInsets.only(bottom: AppSpace.xs),
      h2: theme.textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w700,
        color: scheme.onSurface,
      ),
      listBullet: bodyStyle?.copyWith(color: scheme.primary),
      listIndent: 18,
      blockSpacing: AppSpace.sm,
      strong: const TextStyle(fontWeight: FontWeight.w700),
      em: const TextStyle(fontStyle: FontStyle.italic),
      a: TextStyle(color: scheme.primary, decoration: TextDecoration.underline),
      code: TextStyle(
        fontFamily: 'monospace',
        backgroundColor: scheme.surfaceContainerHighest,
      ),
    );

    return MarkdownBody(
      data: text,
      selectable: true,
      styleSheet: styleSheet,
      builders: {
        'h2': _SectionHeadingBuilder(
          iconColor: scheme.primary,
          textStyle: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: scheme.onSurface,
          ),
        ),
      },
      onTapLink: (text, href, title) {
        if (href == null) return;
        final uri = Uri.tryParse(href);
        if (uri == null) return;

        if (onTapLink != null) {
          onTapLink!(uri);
        } else {
          _openLink(context, uri);
        }
      },
    );
  }

  Future<void> _openLink(BuildContext context, Uri uri) async {
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir el enlace.')),
      );
    }
  }
}

class _SectionHeadingBuilder extends MarkdownElementBuilder {
  final Color iconColor;
  final TextStyle? textStyle;

  _SectionHeadingBuilder({required this.iconColor, this.textStyle});

  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    final title = element.textContent.trim();
    if (title.isEmpty) return null;

    return Padding(
      padding: const EdgeInsets.only(top: AppSpace.md, bottom: AppSpace.xs),
      child: Row(
        children: [
          Icon(_iconFor(title), size: AppIconSize.row, color: iconColor),
          const SizedBox(width: AppSpace.sm),
          Expanded(child: Text(title, style: textStyle ?? preferredStyle)),
        ],
      ),
    );
  }

  IconData _iconFor(String title) {
    return switch (normalizeText(title)) {
      'resumen' => Icons.summarize_outlined,
      'responsabilidades' => Icons.checklist_rtl,
      'requisitos' => Icons.rule,
      'beneficios' => Icons.redeem_outlined,
      'observaciones' => Icons.info_outline,
      'descripcion' => Icons.description_outlined,
      _ => Icons.article_outlined,
    };
  }
}
