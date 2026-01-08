import 'package:flutter/material.dart';

/// Card displayed when no budget is set, with call-to-action button
class NoBudgetSetCard extends StatelessWidget {
  const NoBudgetSetCard({
    super.key,
    required this.onSetBudget,
    this.budgetType = 'group',
  });

  final VoidCallback onSetBudget;
  final String budgetType; // 'group' or 'personal'

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isGroup = budgetType == 'group';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.account_balance_wallet_outlined,
              size: 48,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text(
              'Nessun Budget Impostato',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              isGroup
                  ? 'Imposta budget per categoria per monitorare le spese della famiglia. Il budget totale sarà calcolato automaticamente.'
                  : 'Imposta contributi nelle categorie di gruppo per tracciare la tua quota di spese condivise.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onSetBudget,
              icon: const Icon(Icons.category),
              label: Text(isGroup ? 'Imposta Budget per Categoria' : 'Imposta Contributi'),
            ),
          ],
        ),
      ),
    );
  }
}
