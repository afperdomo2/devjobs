import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../helpers/date_formatter.dart';
import '../helpers/salary_formatter.dart';
import '../helpers/text_shortener.dart';
import '../models/job_application.dart';
import '../theme.dart';
import 'meta_chip.dart';
import 'status_chip.dart';

class ApplicationCard extends StatefulWidget {
  final JobApplication application;
  final VoidCallback onTap;
  final int pulseTrigger;

  const ApplicationCard({
    super.key,
    required this.application,
    required this.onTap,
    this.pulseTrigger = 0,
  });

  @override
  State<ApplicationCard> createState() => _ApplicationCardState();
}

class _ApplicationCardState extends State<ApplicationCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
  }

  @override
  void didUpdateWidget(ApplicationCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.pulseTrigger > oldWidget.pulseTrigger) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = widget.application;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        final baseColor = Theme.of(context).cardColor;
        final color = Color.lerp(
          baseColor,
          Theme.of(context).colorScheme.primary,
          math.sin(t * math.pi) * 0.15,
        );
        return Card(color: color, child: child);
      },
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      app.empresa,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  StatusChip(status: app.estado),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                app.vacante,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 8),
              Builder(builder: (_) {
                final chips = <Widget>[];
                void addChip(IconData icon, String label) {
                  if (label.trim().isEmpty) return;
                  chips.add(MetaChip(icon: icon, label: label));
                }

                if (app.plataforma.trim().isNotEmpty) {
                  addChip(Icons.language, app.plataforma);
                }
                final loc = _buildLocation(app.modalidad, app.ciudad);
                if (loc.isNotEmpty) {
                  addChip(Icons.location_on_outlined, loc);
                }
                final salario = extractSalario(app.salarioOfrecido);
                if (salario.isNotEmpty) {
                  addChip(Icons.attach_money_outlined, salario);
                }
                final contrato = shortContract(app.tipoContrato);
                if (contrato.isNotEmpty) {
                  addChip(Icons.work_outline, contrato);
                }

                if (chips.isEmpty) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: chips,
                  ),
                );
              }),
              Row(
                children: [
                  Icon(Icons.calendar_today,
                      size: 13, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(
                    formatDateShort(app.fechaPostulacion),
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                  const Spacer(),
                  Builder(builder: (_) {
                    final esFinal = app.isFinalizado;
                    final dias = esFinal ? app.diasProceso : app.diasSinNovedad;
                    if (dias == null) return const SizedBox.shrink();

                    final estancado = !esFinal && dias >= kUmbralDiasSinNovedad;
                    final color = estancado
                        ? (Theme.of(context).brightness == Brightness.dark
                            ? AppColorsDark.warning
                            : AppColors.warning)
                        : Theme.of(context).colorScheme.onSurfaceVariant;
                    // Finalizado → check + duración total; activo → campana +
                    // días desde la última novedad (se leen como una frase).
                    final icon = esFinal
                        ? Icons.check_circle_outline
                        : Icons.notifications_outlined;
                    final label = esFinal
                        ? formatDuracion(dias)
                        : formatSinNovedad(dias);

                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icon, size: 13, color: color),
                        const SizedBox(width: 3),
                        Text(
                          label,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: color,
                                fontWeight:
                                    estancado ? FontWeight.w600 : null,
                              ),
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _buildLocation(String modalidad, String ciudad) {
    final m = modalidad.trim();
    final c = ciudad.trim();
    if (m.isNotEmpty && c.isNotEmpty) return '$m · $c';
    if (m.isNotEmpty) return m;
    if (c.isNotEmpty) return c;
    return '';
  }
}