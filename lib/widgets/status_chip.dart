import 'package:flutter/material.dart';

class StatusChip extends StatelessWidget {
  final String status;

  const StatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final (color, icon) = _statusStyle(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            status,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  static (Color, IconData) _statusStyle(String status) {
    final s = status.trim().toLowerCase();
    if (s.contains('enviada')) return (Colors.blue, Icons.send);
    if (s.contains('rechazada')) return (Colors.red, Icons.cancel);
    if (s.contains('revisión') || s.contains('revision')) return (Colors.orange, Icons.visibility);
    if (s.contains('entrevista')) return (Colors.purple, Icons.people);
    if (s.contains('oferta')) return (Colors.green, Icons.check_circle);
    return (Colors.grey, Icons.info_outline);
  }
}
