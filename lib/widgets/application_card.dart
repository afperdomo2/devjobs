import 'package:flutter/material.dart';

import '../helpers/date_formatter.dart';
import '../models/job_application.dart';
import 'status_chip.dart';

class ApplicationCard extends StatelessWidget {
  final JobApplication application;
  final VoidCallback onTap;

  const ApplicationCard({super.key, required this.application, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(application.empresa,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                  StatusChip(status: application.estado),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                application.vacante,
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
                              icon: Icons.location_on, label: application.ciudad),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _InfoChip(
                              icon: Icons.business_center,
                              label: application.modalidad),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      formatDateShort(application.fechaPostulacion),
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
