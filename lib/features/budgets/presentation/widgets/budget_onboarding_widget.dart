// Widget: Budget Onboarding
// Guides new users through the category-only budget system
// Explains how budgets work and helps set up first category budget

import 'package:flutter/material.dart';

/// Onboarding widget for category-only budget system
///
/// Shows when user has no category budgets set.
/// Explains:
/// - Budget totals are calculated from categories
/// - How to set category budgets
/// - What the "Altro" system category is for
class BudgetOnboardingWidget extends StatelessWidget {
  const BudgetOnboardingWidget({
    this.onGetStarted,
    this.showDetailedGuide = false,
    super.key,
  });

  final VoidCallback? onGetStarted;
  final bool showDetailedGuide;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with Icon
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.school_outlined,
                    color: theme.colorScheme.onPrimaryContainer,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Benvenuto nei Budget!',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Organizza le tue spese per categoria',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // How it Works Section
            Text(
              'Come funziona',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            _FeatureRow(
              icon: Icons.category_outlined,
              title: 'Budget per Categoria',
              description:
                  'Imposta un budget per ogni categoria di spesa (es. Cibo, Trasporti, Svago)',
              iconColor: Colors.blue,
            ),
            const SizedBox(height: 12),

            _FeatureRow(
              icon: Icons.calculate_outlined,
              title: 'Totali Automatici',
              description:
                  'Il budget totale è calcolato automaticamente dalla somma dei budget di categoria',
              iconColor: Colors.green,
            ),
            const SizedBox(height: 12),

            _FeatureRow(
              icon: Icons.group_outlined,
              title: 'Budget di Gruppo',
              description:
                  'Condividi budget con la famiglia e imposta contributi individuali per categoria',
              iconColor: Colors.orange,
            ),

            if (showDetailedGuide) ...[
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 16),

              // Detailed Guide
              Text(
                'Primi Passi',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              _StepRow(
                step: 1,
                title: 'Scegli una categoria',
                description: 'Inizia con una categoria importante (es. Alimentari)',
              ),
              const SizedBox(height: 8),

              _StepRow(
                step: 2,
                title: 'Imposta il budget',
                description: 'Decidi quanto vuoi spendere in quella categoria questo mese',
              ),
              const SizedBox(height: 8),

              _StepRow(
                step: 3,
                title: 'Registra le spese',
                description: 'Ogni spesa verrà sottratta dal budget della sua categoria',
              ),
              const SizedBox(height: 8),

              _StepRow(
                step: 4,
                title: 'Monitora il progresso',
                description: 'Vedi in tempo reale quanto hai speso e quanto ti rimane',
              ),

              const SizedBox(height: 20),

              // Altro Category Info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: theme.colorScheme.outline.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Suggerimento: Categoria "Varie"',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Usa la categoria "Varie" per spese che non rientrano in categorie specifiche. È una categoria speciale che raccoglie tutte le spese non categorizzate.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Get Started Button
            if (onGetStarted != null)
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onGetStarted,
                  icon: const Icon(Icons.rocket_launch),
                  label: const Text('Inizia Ora'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Feature row widget
class _FeatureRow extends StatelessWidget {
  const _FeatureRow({
    required this.icon,
    required this.title,
    required this.description,
    required this.iconColor,
  });

  final IconData icon;
  final String title;
  final String description;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: iconColor,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Step row widget for detailed guide
class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.step,
    required this.title,
    required this.description,
  });

  final int step;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '$step',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
