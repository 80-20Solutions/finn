// Data Model: Monthly Budget Stats Model (calculated from RPC)
// Feature: Italian Categories and Budget Management (004)
// Related to: T045

import '../../domain/entities/monthly_budget_stats_entity.dart';

class MonthlyBudgetStatsModel extends MonthlyBudgetStatsEntity {
  const MonthlyBudgetStatsModel({
    required super.categoryId,
    required super.categoryName,
    required super.budgetAmount,
    required super.spentAmount,
    required super.remainingAmount,
    required super.percentageUsed,
    required super.isOverBudget,
    required super.month,
    required super.year,
  });

  /// Create MonthlyBudgetStatsModel from JSON (RPC response)
  factory MonthlyBudgetStatsModel.fromJson(Map<String, dynamic> json) {
    final budgetAmount = json['budget_amount'] as int? ?? 0;
    final spentAmount = json['spent_amount'] as int? ?? 0;
    final remainingAmount = json['remaining_amount'] as int? ?? 0;

    return MonthlyBudgetStatsModel(
      categoryId: json['category_id'] as String,
      categoryName: json['category_name'] as String,
      budgetAmount: budgetAmount,
      spentAmount: spentAmount,
      remainingAmount: remainingAmount,
      percentageUsed: (json['percentage_used'] as num?)?.toDouble() ?? 0.0,
      isOverBudget: json['is_over_budget'] as bool? ?? false,
      month: json['month'] as int,
      year: json['year'] as int,
    );
  }

  /// Convert to MonthlyBudgetStatsEntity
  MonthlyBudgetStatsEntity toEntity() => this;
}
