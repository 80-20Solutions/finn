// Widget: Calculated Budget Overview Card
// Displays calculated budget totals (replaces manual budget cards)
// Shows group and personal budget totals calculated from categories

import 'package:flutter/material.dart';

import '../../domain/entities/computed_budget_totals_entity.dart';

/// Card widget displaying calculated budget totals
///
/// Shows:
/// - Total group budget (SUM of category budgets)
/// - Total personal budget (SUM of user contributions)
/// - Number of categories with budgets
/// - Breakdown information
class CalculatedBudgetOverviewCard extends StatelessWidget {
  const CalculatedBudgetOverviewCard({
    required this.computedTotals,
    this.showGroupBudget = true,
    this.showPersonalBudget = true,
    this.onTap,
    super.key,
  });

  final ComputedBudgetTotals computedTotals;
  final bool showGroupBudget;
  final bool showPersonalBudget;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasGroupBudgets = computedTotals.hasGroupBudgets;
    final hasPersonalBudgets = computedTotals.hasPersonalBudgets;

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(
                    Icons.calculate_outlined,
                    color: theme.colorScheme.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Budget Totali',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Calcolati',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Group Budget Section
              if (showGroupBudget) ...[
                _BudgetSection(
                  label: 'Budget di Gruppo',
                  amount: computedTotals.totalGroupBudget,
                  icon: Icons.group,
                  iconColor: Colors.orange,
                  categoryCount: computedTotals.categoryCount,
                  isEmpty: !hasGroupBudgets,
                ),
                if (showPersonalBudget && hasPersonalBudgets)
                  const Divider(height: 24),
              ],

              // Personal Budget Section
              if (showPersonalBudget) ...[
                _BudgetSection(
                  label: 'Budget Personale',
                  amount: computedTotals.totalPersonalBudget,
                  icon: Icons.person,
                  iconColor: Colors.blue,
                  categoryCount: computedTotals.contributionCount,
                  isEmpty: !hasPersonalBudgets,
                  isContribution: true,
                ),
              ],

              // Info Footer
              if (hasGroupBudgets || hasPersonalBudgets) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'I totali sono calcolati automaticamente dalla somma dei budget di categoria',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Empty State
              if (!hasGroupBudgets && !hasPersonalBudgets) ...[
                const SizedBox(height: 8),
                Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.category_outlined,
                        size: 48,
                        color: theme.colorScheme.outline,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Nessun budget impostato',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Inizia creando budget per categoria',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Internal widget for displaying a budget section
class _BudgetSection extends StatelessWidget {
  const _BudgetSection({
    required this.label,
    required this.amount,
    required this.icon,
    required this.iconColor,
    required this.categoryCount,
    required this.isEmpty,
    this.isContribution = false,
  });

  final String label;
  final int amount;
  final IconData icon;
  final Color iconColor;
  final int categoryCount;
  final bool isEmpty;
  final bool isContribution;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final amountText = '€${(amount / 100).toStringAsFixed(2)}';
    final countLabel = isContribution ? 'contributi' : 'categorie';

    return Row(
      children: [
        // Icon
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

        // Label and Details
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 4),
              if (!isEmpty)
                Text(
                  '$categoryCount $countLabel',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
            ],
          ),
        ),

        // Amount
        Text(
          isEmpty ? '€0,00' : amountText,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: isEmpty
                ? theme.colorScheme.outline
                : theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}
