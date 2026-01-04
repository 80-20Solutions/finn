// Domain Entity: Overall Group Budget Stats for dashboard (calculated, not stored)
// Feature: Italian Categories and Budget Management (004)
// Task: T016

import 'package:equatable/equatable.dart';

class OverallGroupBudgetStatsEntity extends Equatable {
  final int totalBudgeted; // Sum of all category budgets in cents
  final int totalSpent; // Sum of all expenses with categories in cents
  final int totalRemaining; // totalBudgeted - totalSpent (can be negative)
  final double percentageUsed; // (totalSpent / totalBudgeted) * 100
  final int categoriesOverBudget; // Count of categories with spent > budget
  final int month; // 1-12
  final int year; // e.g., 2026

  const OverallGroupBudgetStatsEntity({
    required this.totalBudgeted,
    required this.totalSpent,
    required this.totalRemaining,
    required this.percentageUsed,
    required this.categoriesOverBudget,
    required this.month,
    required this.year,
  });

  @override
  List<Object?> get props => [
        totalBudgeted,
        totalSpent,
        totalRemaining,
        percentageUsed,
        categoriesOverBudget,
        month,
        year,
      ];

  @override
  bool? get stringify => true;
}
