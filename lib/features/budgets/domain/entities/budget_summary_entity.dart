import 'package:equatable/equatable.dart';

/// Domain entity representing a computed budget summary
///
/// This is a read-only computed entity that aggregates:
/// - Total monthly income from all sources
/// - Current savings goal
/// - Total group expense assignments (spending limits)
/// - Calculated available budget
///
/// Formula: availableBudget = totalIncome - savingsGoal - totalGroupExpenses
///
/// This entity is never persisted directly; it's computed from other entities.
class BudgetSummaryEntity extends Equatable {
  final String userId;
  final int totalIncome; // Sum of all income sources in cents
  final int savingsGoal; // Current savings goal in cents (0 if not set)
  final int totalGroupExpenses; // Sum of all group spending limits in cents
  final int availableBudget; // Calculated: totalIncome - savingsGoal - totalGroupExpenses
  final bool hasIncome; // Whether user has set up any income sources
  final bool hasSavingsGoal; // Whether user has set a savings goal
  final bool hasGroupAssignments; // Whether user has any group expense assignments
  final DateTime computedAt; // When this summary was computed

  const BudgetSummaryEntity({
    required this.userId,
    required this.totalIncome,
    required this.savingsGoal,
    required this.totalGroupExpenses,
    required this.availableBudget,
    required this.hasIncome,
    required this.hasSavingsGoal,
    required this.hasGroupAssignments,
    required this.computedAt,
  });

  /// Check if budget is in deficit (negative available budget)
  bool get isInDeficit => availableBudget < 0;

  /// Check if budget is balanced (available budget is exactly 0)
  bool get isBalanced => availableBudget == 0;

  /// Check if there's surplus available
  bool get hasSurplus => availableBudget > 0;

  /// Check if user needs to reduce savings goal due to group expenses
  bool get needsSavingsAdjustment {
    return isInDeficit && hasSavingsGoal && hasGroupAssignments;
  }

  /// Calculate the minimum savings goal to balance budget (can be negative)
  int get recommendedSavingsGoal {
    return totalIncome - totalGroupExpenses;
  }

  /// Factory constructor to create summary from components
  factory BudgetSummaryEntity.fromComponents({
    required String userId,
    required int totalIncome,
    required int savingsGoal,
    required int totalGroupExpenses,
    required bool hasIncome,
    required bool hasSavingsGoal,
    required bool hasGroupAssignments,
  }) {
    final availableBudget = totalIncome - savingsGoal - totalGroupExpenses;
    return BudgetSummaryEntity(
      userId: userId,
      totalIncome: totalIncome,
      savingsGoal: savingsGoal,
      totalGroupExpenses: totalGroupExpenses,
      availableBudget: availableBudget,
      hasIncome: hasIncome,
      hasSavingsGoal: hasSavingsGoal,
      hasGroupAssignments: hasGroupAssignments,
      computedAt: DateTime.now(),
    );
  }

  /// Create a copy with updated fields
  BudgetSummaryEntity copyWith({
    String? userId,
    int? totalIncome,
    int? savingsGoal,
    int? totalGroupExpenses,
    int? availableBudget,
    bool? hasIncome,
    bool? hasSavingsGoal,
    bool? hasGroupAssignments,
    DateTime? computedAt,
  }) {
    return BudgetSummaryEntity(
      userId: userId ?? this.userId,
      totalIncome: totalIncome ?? this.totalIncome,
      savingsGoal: savingsGoal ?? this.savingsGoal,
      totalGroupExpenses: totalGroupExpenses ?? this.totalGroupExpenses,
      availableBudget: availableBudget ?? this.availableBudget,
      hasIncome: hasIncome ?? this.hasIncome,
      hasSavingsGoal: hasSavingsGoal ?? this.hasSavingsGoal,
      hasGroupAssignments: hasGroupAssignments ?? this.hasGroupAssignments,
      computedAt: computedAt ?? this.computedAt,
    );
  }

  @override
  List<Object?> get props => [
        userId,
        totalIncome,
        savingsGoal,
        totalGroupExpenses,
        availableBudget,
        hasIncome,
        hasSavingsGoal,
        hasGroupAssignments,
        computedAt,
      ];
}
