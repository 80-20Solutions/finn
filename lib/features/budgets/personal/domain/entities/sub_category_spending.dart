import 'package:equatable/equatable.dart';

/// Sub-category spending entity for group budget breakdown.
/// Feature: 001-group-budget-wizard, Task: T050
///
/// Represents a single category's spending within the group budget.
class SubCategorySpending extends Equatable {
  const SubCategorySpending({
    required this.categoryId,
    required this.categoryName,
    required this.allocatedCents,
    required this.spentCents,
    required this.icon,
    required this.color,
  });

  final String categoryId;
  final String categoryName;
  final int allocatedCents; // Member's allocated budget for this category
  final int spentCents; // Member's spent amount in this category
  final String icon;
  final String color; // Hex color (e.g., "#FF5722")

  /// Calculate remaining budget in cents.
  int get remainingCents => allocatedCents - spentCents;

  /// Calculate percentage spent (0.0 to 1.0+).
  double get percentageSpent {
    if (allocatedCents == 0) return 0.0;
    return spentCents / allocatedCents;
  }

  /// Get progress color based on spending percentage.
  String get progressColor {
    final percentage = percentageSpent;
    if (percentage >= 1.0) return 'red';
    if (percentage >= 0.75) return 'orange';
    return 'green';
  }

  @override
  List<Object?> get props => [
        categoryId,
        categoryName,
        allocatedCents,
        spentCents,
        icon,
        color,
      ];
}
