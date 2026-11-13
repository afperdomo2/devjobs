import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/app_build_info.dart';
import '../services/build_info_service.dart';
import '../theme.dart';

/// Pantalla con la versión y la compilación que está corriendo la app.
///
/// El commit permite comparar la app instalada con el código: si no coincide
/// con `git log -1 --oneline`, falta compilar.
class AboutScreen extends StatefulWidget {
  /// Datos ya resueltos; en la app se leen de [BuildInfoService]. Se inyectan
  /// en los tests para no depender del plugin de la plataforma.
  final Future<AppBuildInfo>? buildInfo;

  const AboutScreen({super.key, this.buildInfo});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  late final Future<AppBuildInfo> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.buildInfo ?? BuildInfoService().load();
  }

  Future<void> _copy(AppBuildInfo info) async {
    await Clipboard.setData(ClipboardData(text: info.copyText));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Información copiada al portapapeles')),
    );
  }

  Future<void> _openRepository() async {
    try {
      final opened = await launchUrl(
        Uri.parse(kRepositoryUrl),
        mode: LaunchMode.externalApplication,
      );
      if (!opened && mounted) _showError('No se pudo abrir el enlace.');
    } catch (_) {
      if (mounted) _showError('No se pudo abrir el enlace.');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Acerca de')),
      body: FutureBuilder<AppBuildInfo>(
        future: _future,
        builder: (context, snapshot) {
          final info = snapshot.data;
          if (info == null) {
            return Center(
              child: snapshot.hasError
                  ? Text(
                      'No se pudo leer la compilación.',
                      style: AppType.label(context),
                    )
                  : const CircularProgressIndicator(),
            );
          }
          return _AboutBody(
            info: info,
            onCopy: () => _copy(info),
            onOpenRepository: _openRepository,
          );
        },
      ),
    );
  }
}

class _AboutBody extends StatelessWidget {
  final AppBuildInfo info;
  final VoidCallback onCopy;
  final VoidCallback onOpenRepository;

  const _AboutBody({
    required this.info,
    required this.onCopy,
    required this.onOpenRepository,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.all(AppSpace.lg),
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpace.lg),
          decoration: BoxDecoration(
            color: scheme.surfaceContainer,
            borderRadius: BorderRadius.circular(AppRadius.card),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(AppRadius.control),
                ),
                child: Icon(
                  Icons.work_outline,
                  color: scheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DevJobs',
                      style: AppType.cardTitle(context).copyWith(fontSize: 18),
                    ),
                    const SizedBox(height: AppSpace.xs),
                    Text(
                      info.versionLabel,
                      key: const Key('about-version'),
                      style: AppType.label(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpace.xl),
        Text('COMPILACIÓN', style: AppType.section(context)),
        const SizedBox(height: AppSpace.sm),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: scheme.outlineVariant),
            borderRadius: BorderRadius.circular(AppRadius.card),
          ),
          child: Column(
            children: [
              _InfoRow(
                label: 'Commit',
                value: info.commitLabel,
                rowKey: 'about-commit',
                emphasize: true,
              ),
              const Divider(height: 1),
              _InfoRow(
                label: 'Compilada',
                value: info.dateLabel,
                rowKey: 'about-date',
              ),
              const Divider(height: 1),
              _InfoRow(
                label: 'Plataforma',
                value: info.platform,
                rowKey: 'about-platform',
              ),
              const Divider(height: 1),
              _InfoRow(
                label: 'Canal',
                value: info.channel,
                rowKey: 'about-channel',
              ),
            ],
          ),
        ),
        if (info.dirty) ...[
          const SizedBox(height: AppSpace.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline,
                size: AppIconSize.chip,
                color: warningTextColor(Theme.of(context).brightness),
              ),
              const SizedBox(width: AppSpace.xs),
              Expanded(
                child: Text(
                  'Compilada con cambios sin commitear: el commit mostrado no '
                  'incluye esos cambios.',
                  style: AppType.label(context),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: AppSpace.xl),
        OutlinedButton.icon(
          key: const Key('about-copy'),
          onPressed: onCopy,
          icon: const Icon(Icons.copy_all_outlined),
          label: const Text('Copiar información'),
        ),
        const SizedBox(height: AppSpace.sm),
        TextButton.icon(
          key: const Key('about-repo'),
          onPressed: onOpenRepository,
          icon: const Icon(Icons.open_in_new),
          label: const Text('Ver código en GitHub'),
        ),
        const SizedBox(height: AppSpace.md),
        Text(
          'Compará el commit con "git log -1 --oneline". Si coincide, la app '
          'está igual que el código; si no, falta compilar.',
          style: AppType.label(context),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final String rowKey;
  final bool emphasize;

  const _InfoRow({
    required this.label,
    required this.value,
    required this.rowKey,
    this.emphasize = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.md,
        vertical: AppSpace.md,
      ),
      child: Row(
        children: [
          Expanded(child: Text(label, style: AppType.label(context))),
          const SizedBox(width: AppSpace.sm),
          Flexible(
            child: Text(
              value,
              key: Key(rowKey),
              textAlign: TextAlign.right,
              style: AppType.cardTitle(
                context,
              ).copyWith(letterSpacing: emphasize ? 0.5 : null),
            ),
          ),
        ],
      ),
    );
  }
}
