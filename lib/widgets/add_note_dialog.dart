import 'package:flutter/material.dart';

/// Abre el diálogo de nota rápida y devuelve el texto, o null si cancela.
Future<String?> showAddNoteDialog(BuildContext context) {
  return showDialog<String>(
    context: context,
    builder: (_) => const AddNoteDialog(),
  );
}

class AddNoteDialog extends StatefulWidget {
  const AddNoteDialog({super.key});

  @override
  State<AddNoteDialog> createState() => _AddNoteDialogState();
}

class _AddNoteDialogState extends State<AddNoteDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    Navigator.pop(context, text);
  }

  @override
  Widget build(BuildContext context) {
    final canSave = _controller.text.trim().isNotEmpty;

    return AlertDialog(
      title: const Text('Agregar nota'),
      scrollable: true,
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLines: 4,
        textCapitalization: TextCapitalization.sentences,
        decoration: const InputDecoration(
          hintText: 'Ej. Llamada con reclutador, prueba pendiente...',
          alignLabelWithHint: true,
        ),
        onChanged: (_) => setState(() {}),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: canSave ? _save : null,
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
