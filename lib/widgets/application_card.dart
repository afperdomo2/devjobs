import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../helpers/date_formatter.dart';
import '../helpers/salary_formatter.dart';
import '../helpers/text_shortener.dart';
import '../models/job_application.dart';
import '../theme.dart';
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
                  chips.add(_MetaChip(icon: icon, label: label));
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
                  if (app.diasProceso != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.warning.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.schedule,
                              size: 12,
                              color: warningTextColor(
                                  Theme.of(context).brightness)),
                          const SizedBox(width: 3),
                          Text(
                            '${app.diasProceso} ${app.diasProceso == 1 ? "día" : "días"}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: warningTextColor(
                                  Theme.of(context).brightness),
                            ),
                          ),
                        ],
                      ),
                    ),
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

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: scheme.outline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: scheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
