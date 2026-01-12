import 'package:equatable/equatable.dart';

/// Personal budget entity with group allocation.
/// Feature: 001-group-budget-wizard, Task: T061
///
/// Represents a member's complete budget including both personal and group allocation.
class PersonalBudget extends Equatable {
  const PersonalBudget({
    required this.userId,
    required this.groupId,
    required this.year,
    required this.month,
    required this.personalBudgetCents,
    required this.groupAllocationCents,
    required this.totalBudgetCents,
    required this.personalSpentCents,
    required this.groupSpentCents,
    required this.totalSpentCents,
  });

  final String userId;
  final String groupId;
  final int year;
  final int month;

  // Budget amounts
  final int personalBudgetCents; // Member's personal budget
  final int groupAllocationCents; // Member's allocated share of group budget
  final int totalBudgetCents; // Personal + Group (automatically calculated)

  // Spent amounts
  final int personalSpentCents; // Spent on personal expenses
  final int groupSpentCents; // Spent on group expenses
  final int totalSpentCents; // Total spent (automatically calculated)

  /// Calculate remaining budget in cents.
  int get remainingCents => totalBudgetCents - totalSpentCents;

  /// Calculate remaining personal budget.
  int get personalRemainingCents => personalBudgetCents - personalSpentCents;

  /// Calculate remaining group budget.
  int get groupRemainingCents => groupAllocationCents - groupSpentCents;

  /// Calculate percentage spent (0.0 to 1.0+).
  double get percentageSpent {
    if (totalBudgetCents == 0) return 0.0;
    return totalSpentCents / totalBudgetCents;
  }

  /// Get progress color based on spending percentage.
  String get progressColor {
    final percentage = percentageSpent;
    if (percentage >= 1.0) return 'red';
    if (percentage >= 0.75) return 'orange';
    return 'green';
  }

  /// Check if over budget.
  bool get isOverBudget => totalSpentCents > totalBudgetCents;

  /// Check if personal budget is over.
  bool get isPersonalOverBudget => personalSpentCents > personalBudgetCents;

  /// Check if group budget is over.
  bool get isGroupOverBudget => groupSpentCents > groupAllocationCents;

  @override
  List<Object?> get props => [
        userId,
        groupId,
        year,
        month,
        personalBudgetCents,
        groupAllocationCents,
        totalBudgetCents,
        personalSpentCents,
        groupSpentCents,
        totalSpentCents,
      ];
}
