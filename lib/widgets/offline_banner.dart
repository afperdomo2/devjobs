import 'package:flutter/material.dart';

import '../theme.dart';

class OfflineBanner extends StatelessWidget {
  final DateTime? lastUpdated;
  final VoidCallback? onRetry;

  const OfflineBanner({super.key, this.lastUpdated, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final subtitle = lastUpdated != null
        ? 'Datos guardados del ${_formatDate(lastUpdated!)}'
        : 'Mostrando datos guardados';

    return Material(
      color: AppColors.warning.withValues(alpha: 0.12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Icon(Icons.wifi_off, size: 18, color: AppColors.warningDark),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Sin conexión — modo solo lectura',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.warningDark,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 11, color: AppColors.warningDark),
                  ),
                ],
              ),
            ),
            if (onRetry != null)
              TextButton(
                onPressed: onRetry,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.warningDark,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(0, 32),
                ),
                child: const Text('Reintentar', style: TextStyle(fontSize: 12)),
              ),
          ],
        ),
      ),
    );
  }

  static String _formatDate(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$d/$m $h:$min';
  }
}

class ErrorStateView extends StatelessWidget {
  final String message;
  final bool isOffline;
  final VoidCallback onRetry;

  const ErrorStateView({
    super.key,
    required this.message,
    required this.isOffline,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isOffline ? Icons.wifi_off : Icons.error_outline,
              size: 48,
              color: AppColors.onMuted,
            ),
            const SizedBox(height: 16),
            Text(
              isOffline ? 'Sin conexión a internet' : 'No se pudieron cargar los datos',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(color: AppColors.onMuted, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}
