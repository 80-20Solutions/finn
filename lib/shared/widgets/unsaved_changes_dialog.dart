import 'package:flutter/material.dart';

/// Dialog to confirm discarding unsaved changes
class UnsavedChangesDialog extends StatelessWidget {
  const UnsavedChangesDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Modifiche non salvate'),
      content: const Text(
        'Hai modifiche non salvate. Vuoi uscire senza salvare?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Annulla'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.error,
          ),
          child: const Text('Esci senza salvare'),
        ),
      ],
    );
  }
}
