// Domain Entity: Monthly Budget Stats (calculated, not stored in DB)
// Feature: Italian Categories and Budget Management (004)
// Task: T015

import 'package:equatable/equatable.dart';

class MonthlyBudgetStatsEntity extends Equatable {
  final String categoryId;
  final String categoryName; // Italian category name
  final int budgetAmount; // Budget allocation in cents
  final int spentAmount; // Total spent in month in cents
  final int remainingAmount; // Can be negative if over-budget
  final double percentageUsed; // 0.0 to 100.0+ (can exceed 100)
  final bool isOverBudget; // True if spentAmount > budgetAmount
  final int month; // 1-12
  final int year; // e.g., 2026

  const MonthlyBudgetStatsEntity({
    required this.categoryId,
    required this.categoryName,
    required this.budgetAmount,
    required this.spentAmount,
    required this.remainingAmount,
    required this.percentageUsed,
    required this.isOverBudget,
    required this.month,
    required this.year,
  });

  @override
  List<Object?> get props => [
        categoryId,
        categoryName,
        budgetAmount,
        spentAmount,
        remainingAmount,
        percentageUsed,
        isOverBudget,
        month,
        year,
      ];

  @override
  bool? get stringify => true;
}
