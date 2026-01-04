// Widget: Budget Context Widget for Expense Detail
// Feature: Italian Categories and Budget Management (004)
// Task: T059

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../budgets/presentation/providers/monthly_budget_stats_provider.dart';
import '../../../groups/presentation/providers/group_provider.dart';

/// Format cents amount to euro string
String _formatCents(int cents) {
  final euros = cents / 100.0;
  return '€${euros.toStringAsFixed(2)}';
}

/// Widget that displays budget context for an expense
/// Shows category budget status, remaining budget, and percentage used
class BudgetContextWidget extends ConsumerWidget {
  const BudgetContextWidget({
    super.key,
    required this.categoryId,
    required this.categoryName,
    required this.expenseAmount,
    required this.expenseDate,
  });

  final String? categoryId; // Nullable for orphaned expenses
  final String? categoryName;
  final int expenseAmount; // Amount in cents
  final DateTime expenseDate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    // Handle orphaned expenses (null category_id) - T065
    if (categoryId == null) {
      return Card(
        color: Colors.grey.shade100,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.grey.shade600),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Nessun budget assegnato',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final groupId = ref.watch(currentGroupIdProvider);

    // Fetch category budget stats for the expense's month (T061)
    final statsParams = MonthlyBudgetStatsParams(
      groupId: groupId,
      categoryId: categoryId!,
      year: expenseDate.year,
      month: expenseDate.month,
    );

    final budgetStatsAsync = ref.watch(monthlyBudgetStatsProvider(statsParams));

    return budgetStatsAsync.when(
      data: (stats) {
        // No budget set for this category
        if (stats == null) {
          return Card(
            color: Colors.blue.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.account_balance_wallet_outlined,
                          color: Colors.blue.shade700),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Budget di categoria',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Nessun budget impostato per "$categoryName"',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.blue.shade800,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // Special indicator for "Varie" category (T063)
        final isVarieCategory = categoryName?.toLowerCase() == 'varie';

        // Determine if this expense exceeded the budget (T064)
        final wasOverBudget = stats.isOverBudget;

        // Calculate color based on budget usage
        Color cardColor;
        Color iconColor;
        Color textColor;

        if (wasOverBudget) {
          cardColor = Colors.red.shade50;
          iconColor = Colors.red.shade700;
          textColor = Colors.red.shade900;
        } else if (stats.percentageUsed >= 80) {
          cardColor = Colors.orange.shade50;
          iconColor = Colors.orange.shade700;
          textColor = Colors.orange.shade900;
        } else {
          cardColor = Colors.green.shade50;
          iconColor = Colors.green.shade700;
          textColor = Colors.green.shade900;
        }

        return Card(
          color: cardColor,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Icon(Icons.account_balance_wallet_outlined, color: iconColor),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Budget di categoria',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          if (isVarieCategory) ...[
                            const SizedBox(height: 2),
                            Text(
                              'Budget generico',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: textColor.withOpacity(0.8),
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Budget stats (T062)
                Row(
                  children: [
                    Expanded(
                      child: _StatItem(
                        label: 'Budget mensile',
                        value: _formatCents(stats.budgetAmount),
                        color: textColor,
                      ),
                    ),
                    Expanded(
                      child: _StatItem(
                        label: 'Speso',
                        value: _formatCents(stats.spentAmount),
                        color: textColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Remaining budget (T062)
                Row(
                  children: [
                    Expanded(
                      child: _StatItem(
                        label: 'Rimanente',
                        value: _formatCents(stats.remainingAmount),
                        color: textColor,
                        isHighlight: true,
                      ),
                    ),
                    Expanded(
                      child: _StatItem(
                        label: 'Utilizzato',
                        value: '${stats.percentageUsed.toStringAsFixed(1)}%',
                        color: textColor,
                      ),
                    ),
                  ],
                ),

                // Over-budget warning (T064)
                if (wasOverBudget) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade300),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber_rounded,
                            color: Colors.red.shade700, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Il budget è stato superato in questo mese',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.red.shade900,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
      loading: () => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 12),
              Text(
                'Caricamento budget...',
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
      error: (error, stack) => const SizedBox.shrink(), // Hide on error
    );
  }
}

/// Internal widget for stat items
class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.label,
    required this.value,
    required this.color,
    this.isHighlight = false,
  });

  final String label;
  final String value;
  final Color color;
  final bool isHighlight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: color.withOpacity(0.8),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: isHighlight ? FontWeight.bold : FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}
