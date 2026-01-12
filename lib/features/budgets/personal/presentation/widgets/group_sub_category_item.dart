import 'package:flutter/material.dart';

import '../../../../core/config/strings_it.dart';
import '../../domain/entities/sub_category_spending.dart';

/// Sub-category item widget (read-only display).
/// Feature: 001-group-budget-wizard, Task: T052
///
/// Displays a single subcategory row within the "Spesa Gruppo" breakdown.
/// Read-only (non-interactive) for group members.
class GroupSubCategoryItem extends StatelessWidget {
  const GroupSubCategoryItem({
    super.key,
    required this.subCategory,
  });

  final SubCategorySpending subCategory;

  @override
  Widget build(BuildContext context) {
    final percentage = (subCategory.percentageSpent * 100).round();
    final progressColor = _getProgressColor();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category name and icon
          Row(
            children: [
              // Category icon with color
              Icon(
                _getIconData(subCategory.icon),
                color: _parseColor(subCategory.color),
                size: 24,
              ),
              const SizedBox(width: 12),
              // Category name
              Expanded(
                child: Text(
                  subCategory.categoryName,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              // Percentage
              Text(
                '$percentage%',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: progressColor,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Progress indicator
          LinearProgressIndicator(
            value: subCategory.percentageSpent > 1.0
                ? 1.0
                : subCategory.percentageSpent,
            color: progressColor,
            backgroundColor: progressColor.withOpacity(0.2),
          ),
          const SizedBox(height: 8),

          // Amounts row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Spent / Allocated
              Text(
                '${_formatCents(subCategory.spentCents)} / ${_formatCents(subCategory.allocatedCents)} €',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              // Remaining
              Text(
                '${StringsIt.remaining}: ${_formatCents(subCategory.remainingCents)} €',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: subCategory.remainingCents < 0
                          ? Theme.of(context).colorScheme.error
                          : Theme.of(context).colorScheme.primary,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Get progress color based on spending percentage.
  Color _getProgressColor() {
    final percentage = subCategory.percentageSpent;
    if (percentage >= 1.0) return Colors.red;
    if (percentage >= 0.75) return Colors.orange;
    return Colors.green;
  }

  /// Parse hex color string to Color.
  Color _parseColor(String hexColor) {
    final hex = hexColor.replaceAll('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }

  /// Get IconData from icon name string.
  IconData _getIconData(String iconName) {
    switch (iconName.toLowerCase()) {
      case 'restaurant':
        return Icons.restaurant;
      case 'power':
        return Icons.power;
      case 'directions_car':
      case 'car':
        return Icons.directions_car;
      case 'home':
        return Icons.home;
      case 'shopping_cart':
      case 'cart':
        return Icons.shopping_cart;
      case 'medical_services':
      case 'health':
        return Icons.medical_services;
      case 'school':
        return Icons.school;
      case 'sports_soccer':
      case 'sports':
        return Icons.sports_soccer;
      case 'category':
      default:
        return Icons.category;
    }
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
