// Data Model: Overall Group Budget Stats Model (calculated from RPC)
// Feature: Italian Categories and Budget Management (004)
// Related to: T046

import '../../domain/entities/overall_group_budget_stats_entity.dart';

class OverallGroupBudgetStatsModel extends OverallGroupBudgetStatsEntity {
  const OverallGroupBudgetStatsModel({
    required super.totalBudgeted,
    required super.totalSpent,
    required super.totalRemaining,
    required super.percentageUsed,
    required super.categoriesOverBudget,
    required super.month,
    required super.year,
  });

  /// Create OverallGroupBudgetStatsModel from JSON (RPC response)
  factory OverallGroupBudgetStatsModel.fromJson(Map<String, dynamic> json) {
    return OverallGroupBudgetStatsModel(
      totalBudgeted: json['total_budgeted'] as int? ?? 0,
      totalSpent: json['total_spent'] as int? ?? 0,
      totalRemaining: json['total_remaining'] as int? ?? 0,
      percentageUsed: (json['percentage_used'] as num?)?.toDouble() ?? 0.0,
      categoriesOverBudget: json['categories_over_budget'] as int? ?? 0,
      month: json['month'] as int,
      year: json['year'] as int,
    );
  }

  /// Convert to OverallGroupBudgetStatsEntity
  OverallGroupBudgetStatsEntity toEntity() => this;
}
