import 'package:equatable/equatable.dart';

/// Budget allocation entity representing a single category budget.
/// Feature: 001-group-budget-wizard, Task: T007
///
/// Used internally by wizard to manage individual category configurations
/// before persisting to category_budgets table.
class BudgetAllocation extends Equatable {
  const BudgetAllocation({
    required this.categoryId,
    required this.categoryName,
    required this.amountCents,
    this.icon,
    this.color,
  });

  /// Expense category ID
  final String categoryId;

  /// Italian category name (e.g., "Cibo e Spesa")
  final String categoryName;

  /// Budget amount in cents (e.g., 50000 = €500.00)
  final int amountCents;

  /// Optional Material icon name
  final String? icon;

  /// Optional hex color code
  final String? color;

  /// Convert cents to euro string (e.g., "500,00 €")
  String get amountEuro {
    final euros = amountCents / 100;
    return '${euros.toStringAsFixed(2).replaceAll('.', ',')} €';
  }

  /// Validate amount is positive
  bool get isValid => amountCents > 0;

  /// Create a copy with updated fields
  BudgetAllocation copyWith({
    String? categoryId,
    String? categoryName,
    int? amountCents,
    String? icon,
    String? color,
  }) {
    return BudgetAllocation(
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      amountCents: amountCents ?? this.amountCents,
      icon: icon ?? this.icon,
      color: color ?? this.color,
    );
  }

  @override
  List<Object?> get props => [categoryId, categoryName, amountCents, icon, color];

  @override
  String toString() {
    return 'BudgetAllocation(category: $categoryName, amount: $amountEuro)';
  }
}
