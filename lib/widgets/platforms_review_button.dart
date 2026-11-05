import 'package:flutter/material.dart';

import '../theme.dart';

/// Botón que abre el listado de plataformas con su última aplicación.
///
/// Es un acceso neutro de Inicio, no una alerta: no muestra conteos ni
/// estados de pendiente.
class PlatformsReviewButton extends StatelessWidget {
  final VoidCallback onPressed;

  const PlatformsReviewButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.language, size: AppIconSize.row),
        label: const Text('Revisar plataformas'),
      ),
    );
  }
}
