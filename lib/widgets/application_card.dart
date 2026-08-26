import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../helpers/date_formatter.dart';
import '../models/job_application.dart';
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
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        final baseColor = Theme.of(context).cardColor;
        final color =
            Color.lerp(baseColor, Theme.of(context).colorScheme.primary, math.sin(t * math.pi) * 0.15);
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
                    child: Text(widget.application.empresa,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                  StatusChip(status: widget.application.estado),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                widget.application.vacante,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Colors.grey[700]),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: _InfoChip(
                              icon: Icons.location_on, label: widget.application.ciudad),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _InfoChip(
                              icon: Icons.business_center,
                              label: widget.application.modalidad),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      formatDateShort(widget.application.fechaPostulacion),
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
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
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey),
        const SizedBox(width: 2),
        Flexible(
          child: Text(label,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall),
        ),
      ],
    );
  }
}
