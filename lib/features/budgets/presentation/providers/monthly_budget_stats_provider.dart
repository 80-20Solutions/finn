// Riverpod Provider: Monthly Budget Stats Provider
// Feature: Italian Categories and Budget Management (004)
// Task: T051

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/monthly_budget_stats_entity.dart';
import 'budget_repository_provider.dart';

/// Provider parameters for monthly budget stats
class MonthlyBudgetStatsParams {
  final String groupId;
  final String categoryId;
  final int year;
  final int month;

  const MonthlyBudgetStatsParams({
    required this.groupId,
    required this.categoryId,
    required this.year,
    required this.month,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MonthlyBudgetStatsParams &&
          runtimeType == other.runtimeType &&
          groupId == other.groupId &&
          categoryId == other.categoryId &&
          year == other.year &&
          month == other.month;

  @override
  int get hashCode =>
      groupId.hashCode ^
      categoryId.hashCode ^
      year.hashCode ^
      month.hashCode;
}

/// Provider for monthly category budget stats
/// Fetches budget statistics for a specific category and month
final monthlyBudgetStatsProvider = FutureProvider.family<
    MonthlyBudgetStatsEntity?, MonthlyBudgetStatsParams>(
  (ref, params) async {
    final repository = ref.watch(budgetRepositoryProvider);

    final result = await repository.getCategoryBudgetStats(
      groupId: params.groupId,
      categoryId: params.categoryId,
      year: params.year,
      month: params.month,
    );

    return result.fold(
      (failure) => null, // Return null on failure
      (stats) => stats as MonthlyBudgetStatsEntity?,
    );
  },
);

/// Provider for current month's budget stats (convenience provider)
final currentMonthBudgetStatsProvider = FutureProvider.family<
    MonthlyBudgetStatsEntity?, (String groupId, String categoryId)>(
  (ref, params) async {
    final now = DateTime.now();
    final statsParams = MonthlyBudgetStatsParams(
      groupId: params.$1,
      categoryId: params.$2,
      year: now.year,
      month: now.month,
    );

    return await ref.watch(monthlyBudgetStatsProvider(statsParams).future);
  },
);
