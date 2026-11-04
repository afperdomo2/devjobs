import 'package:flutter/material.dart';

import '../theme.dart';
import 'app_chip.dart';

class StatusChip extends StatelessWidget {
  final String status;

  const StatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    return AppChip(
      icon: _statusIcon(status),
      label: status,
      variant: AppChipVariant.status,
      color: statusColor(status, Theme.of(context).brightness),
    );
  }

  static IconData _statusIcon(String status) {
    final s = status.trim().toLowerCase();
    if (s.contains('enviada')) return Icons.send;
    if (s.contains('rechazada')) return Icons.cancel;
    if (s == 'sin respuesta') return Icons.hourglass_empty;
    if (s.contains('revisión') || s.contains('revision')) return Icons.visibility;
    if (s == 'entrevista agendada') return Icons.calendar_today;
    if (s == 'entrevista realizada') return Icons.people;
    if (s.contains('entrevista')) return Icons.people;
    if (s == 'prueba técnica' || s == 'prueba tecnica') return Icons.code;
    if (s.contains('oferta')) return Icons.check_circle;
    if (s == 'aceptada') return Icons.thumb_up;
    if (s == 'retirada') return Icons.remove_circle;
    return Icons.info_outline;
  }
}
