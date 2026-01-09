// Widget: Virtual Group Expenses Category Tile
// Displays the virtual "Spese di Gruppo" category in personal budget view
// Shows user's total group expense contributions (NOT stored in database)

import 'package:flutter/material.dart';

import '../../domain/entities/virtual_group_expenses_category_entity.dart';

/// Tile displaying virtual "Spese di Gruppo" category
///
/// This category aggregates:
/// - User's budget contributions across all group categories
/// - User's spending in group expenses
/// - Breakdown by real category
///
/// **IMPORTANT:** This is a virtual category - it's NOT stored in the database.
/// It's calculated on-demand from user's contributions in group categories.
///
/// Appears ONLY in personal budget view, not in group budget view.
class VirtualGroupExpensesCategoryTile extends StatelessWidget {
  const VirtualGroupExpensesCategoryTile({
    required this.virtualCategory,
    this.onTap,
    super.key,
  });

  final VirtualGroupExpensesCategory virtualCategory;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasContributions = virtualCategory.hasContributions;
    final status = virtualCategory.status;

    // Status colors
    Color statusColor;
    IconData statusIcon;
    switch (status) {
      case 'danger':
        statusColor = Colors.red;
        statusIcon = Icons.warning_rounded;
        break;
      case 'warning':
        statusColor = Colors.orange;
        statusIcon = Icons.info_rounded;
        break;
      default:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle_rounded;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: [
                const Color(0xFFFF6B35).withOpacity(0.1),
                const Color(0xFFFF6B35).withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row
                Row(
                  children: [
                    // Virtual Category Badge
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF6B35),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.group,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Title and Badge
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                VirtualGroupExpensesCategory.displayName,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF6B35),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'GRUPPO',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${virtualCategory.categoryCount} ${virtualCategory.categoryCount == 1 ? 'categoria' : 'categorie'}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Status Icon
                    if (hasContributions)
                      Icon(
                        statusIcon,
                        color: statusColor,
                        size: 24,
                      ),
                  ],
                ),

                const SizedBox(height: 16),

                // Budget and Spending Row
                if (hasContributions) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Budget
                      _InfoColumn(
                        label: 'Budget',
                        value: virtualCategory.formattedBudget,
                        icon: Icons.account_balance_wallet_outlined,
                        color: theme.colorScheme.primary,
                      ),

                      // Spent
                      _InfoColumn(
                        label: 'Speso',
                        value: virtualCategory.formattedSpent,
                        icon: Icons.shopping_cart_outlined,
                        color: statusColor,
                      ),

                      // Remaining
                      _InfoColumn(
                        label: 'Rimasto',
                        value: virtualCategory.formattedRemaining,
                        icon: Icons.savings_outlined,
                        color: virtualCategory.isOverBudget
                            ? Colors.red
                            : Colors.green,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Progress Bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: virtualCategory.percentageUsed / 100,
                      minHeight: 8,
                      backgroundColor: theme.colorScheme.surfaceVariant,
                      valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Percentage Text
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${virtualCategory.percentageUsed.toStringAsFixed(1)}% utilizzato',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (virtualCategory.isOverBudget)
                        Text(
                          'Superato',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      else if (virtualCategory.isNearLimit)
                        Text(
                          'Vicino al limite',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),

                  // Info Footer
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 14,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Budget calcolato automaticamente dalla somma dei tuoi contributi nelle categorie di gruppo',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  // Empty State
                  Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 32,
                          color: theme.colorScheme.outline,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Nessun contributo di gruppo',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Imposta contributi nelle categorie di gruppo',
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
      ),
    );
  }
}

/// Internal widget for displaying info columns
class _InfoColumn extends StatelessWidget {
  const _InfoColumn({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Icon(
          icon,
          color: color,
          size: 20,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
