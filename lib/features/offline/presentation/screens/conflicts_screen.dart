import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// T100-T102: Conflict Resolution Screen
///
/// Features:
/// - List all expenses with conflicts
/// - Show local vs server version side-by-side
/// - Allow user to choose which version to keep
/// - Server-wins by default (FR-009)
class ConflictsScreen extends ConsumerWidget {
  const ConflictsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // For now, this is a placeholder since conflicts are auto-resolved with server-wins
    return Scaffold(
      appBar: AppBar(
        title: const Text('Conflitti di Sincronizzazione'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.check_circle_outline,
                size: 64,
                color: Colors.green.shade400,
              ),
              const SizedBox(height: 24),
              Text(
                'Nessun conflitto',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                'I conflitti vengono risolti automaticamente\ncon la versione del server.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade600,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// T101: Conflict detail dialog
class ConflictDetailDialog extends StatelessWidget {
  final Map<String, dynamic> localVersion;
  final Map<String, dynamic> serverVersion;
  final VoidCallback onAcceptServer;
  final VoidCallback onKeepLocal;

  const ConflictDetailDialog({
    required this.localVersion,
    required this.serverVersion,
    required this.onAcceptServer,
    required this.onKeepLocal,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Conflitto di Sincronizzazione'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'La spesa è stata modificata sia localmente che sul server.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            _buildVersionComparison(context),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: onKeepLocal,
          child: const Text('Mantieni Locale'),
        ),
        FilledButton(
          onPressed: onAcceptServer,
          child: const Text('Accetta Server'),
        ),
      ],
    );
  }

  Widget _buildVersionComparison(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildVersionCard(
          context,
          'Versione Locale',
          localVersion,
          Colors.blue.shade50,
        ),
        const SizedBox(height: 12),
        _buildVersionCard(
          context,
          'Versione Server',
          serverVersion,
          Colors.green.shade50,
        ),
      ],
    );
  }

  Widget _buildVersionCard(
    BuildContext context,
    String title,
    Map<String, dynamic> version,
    Color backgroundColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Text('Importo: €${version['amount']}'),
          Text('Data: ${version['date']}'),
          if (version['merchant'] != null)
            Text('Negozio: ${version['merchant']}'),
          if (version['notes'] != null) Text('Note: ${version['notes']}'),
        ],
      ),
    );
  }
}
