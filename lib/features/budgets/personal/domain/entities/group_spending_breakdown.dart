import 'package:equatable/equatable.dart';

import 'sub_category_spending.dart';

/// Group spending breakdown entity.
/// Feature: 001-group-budget-wizard, Task: T049
///
/// Represents the hierarchical "Spesa Gruppo" category with subcategories.
class GroupSpendingBreakdown extends Equatable {
  const GroupSpendingBreakdown({
    required this.totalAllocatedCents,
    required this.totalSpentCents,
    required this.subCategories,
  });

  final int totalAllocatedCents; // Total allocated across all subcategories
  final int totalSpentCents; // Total spent across all subcategories
  final List<SubCategorySpending> subCategories;

  /// Calculate remaining budget in cents.
  int get remainingCents => totalAllocatedCents - totalSpentCents;

  /// Calculate percentage spent (0.0 to 1.0+).
  double get percentageSpent {
    if (totalAllocatedCents == 0) return 0.0;
    return totalSpentCents / totalAllocatedCents;
  }

  /// Get progress color based on spending percentage.
  String get progressColor {
    final percentage = percentageSpent;
    if (percentage >= 1.0) return 'red';
    if (percentage >= 0.75) return 'orange';
    return 'green';
  }

  /// Check if any subcategory is over budget.
  bool get hasOverBudgetCategory {
    return subCategories.any((cat) => cat.percentageSpent > 1.0);
  }

  @override
  List<Object?> get props => [
        totalAllocatedCents,
        totalSpentCents,
        subCategories,
      ];
}
