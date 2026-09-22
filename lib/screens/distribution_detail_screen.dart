import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../helpers/distribution.dart';
import '../models/job_application.dart';
import '../providers/app_state.dart';
import 'filtered_applications_screen.dart';

class DistributionDetailScreen extends StatelessWidget {
  final String field;
  final String label;
  final IconData icon;
  final Color color;

  const DistributionDetailScreen({
    super.key,
    required this.field,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final apps = context.watch<AppState>().applications;
    final counts = distributionCounts(apps, _selector(field));
    final total = counts.fold<int>(0, (sum, e) => sum + e.$2);

    return Scaffold(
      appBar: AppBar(title: Text(label)),
      body: counts.isEmpty
          ? const Center(child: Text('Sin datos para mostrar'))
          : ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(icon, size: 18, color: color),
                            const SizedBox(width: 6),
                            Text(
                              '$label · $total ${total == 1 ? 'postulación' : 'postulaciones'}',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        for (final (name, count) in counts)
                          _DetailRow(
                            name: name,
                            count: count,
                            total: total,
                            color: color,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => FilteredApplicationsScreen(
                                  title: label,
                                  field: field,
                                  value: name,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  static String Function(JobApplication) _selector(String field) {
    switch (field) {
      case 'ciudad':
        return (a) => a.ciudad;
      case 'modalidad':
        return (a) => a.modalidad;
      case 'plataforma':
        return (a) => a.plataforma;
      default:
        return (a) => '';
    }
  }
}

class _DetailRow extends StatelessWidget {
  final String name;
  final int count;
  final int total;
  final Color color;
  final VoidCallback onTap;

  const _DetailRow({
    required this.name,
    required this.count,
    required this.total,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final pct = total == 0 ? 0.0 : count / total;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '$count',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(
                  width: 44,
                  child: Text(
                    '${(pct * 100).round()}%',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.chevron_right, size: 18, color: color),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: pct,
                minHeight: 6,
                backgroundColor: color.withValues(alpha: 0.12),
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}