import 'package:flutter/material.dart';

import '../../../../core/config/strings_it.dart';
import '../../domain/entities/group_spending_breakdown.dart';
import 'group_sub_category_item.dart';

/// Group spending category widget (ExpansionTile parent).
/// Feature: 001-group-budget-wizard, Task: T051
///
/// Displays the hierarchical "Spesa Gruppo" parent category
/// with expandable subcategories.
class GroupSpendingCategory extends StatelessWidget {
  const GroupSpendingCategory({
    super.key,
    required this.breakdown,
  });

  final GroupSpendingBreakdown breakdown;

  @override
  Widget build(BuildContext context) {
    final percentage = (breakdown.percentageSpent * 100).round();
    final progressColor = _getProgressColor();

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: ExpansionTile(
        leading: Icon(
          Icons.lock_outline,
          color: Theme.of(context).colorScheme.secondary,
        ),
        title: Text(
          StringsIt.groupSpending,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            // Progress indicator
            LinearProgressIndicator(
              value: breakdown.percentageSpent > 1.0
                  ? 1.0
                  : breakdown.percentageSpent,
              color: progressColor,
              backgroundColor: progressColor.withOpacity(0.2),
            ),
            const SizedBox(height: 8),
            // Amounts and percentage
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_formatCents(breakdown.totalSpentCents)} / ${_formatCents(breakdown.totalAllocatedCents)} €',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                Text(
                  '$percentage%',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: progressColor,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ],
        ),
        children: [
          const Divider(),
          // Subcategory items
          if (breakdown.subCategories.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                StringsIt.noCategories,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            )
          else
            ...breakdown.subCategories.map(
              (subCategory) => GroupSubCategoryItem(
                subCategory: subCategory,
              ),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  /// Get progress color based on spending percentage.
  Color _getProgressColor() {
    final percentage = breakdown.percentageSpent;
    if (percentage >= 1.0) return Colors.red;
    if (percentage >= 0.75) return Colors.orange;
    return Colors.green;
  }

  /// Format cents to Italian currency format (€).
  String _formatCents(int cents) {
    final euros = cents / 100;
    if (euros >= 1000) {
      // Format with thousands separator
      final formatted = euros.toStringAsFixed(2);
      final parts = formatted.split('.');
      final integerPart = parts[0];
      final decimalPart = parts[1];

      // Add thousands separator
      final buffer = StringBuffer();
      final length = integerPart.length;
      for (int i = 0; i < length; i++) {
        if (i > 0 && (length - i) % 3 == 0) {
          buffer.write('.');
        }
        buffer.write(integerPart[i]);
      }

      return '${buffer.toString()},${decimalPart}';
    } else {
      return euros.toStringAsFixed(2).replaceAll('.', ',');
    }
  }
}
