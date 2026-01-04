// Riverpod Provider: Overall Budget Stats Provider
// Feature: Italian Categories and Budget Management (004)
// Task: T052

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/overall_group_budget_stats_entity.dart';
import 'budget_repository_provider.dart';

/// Provider parameters for overall group budget stats
class OverallBudgetStatsParams {
  final String groupId;
  final int year;
  final int month;

  const OverallBudgetStatsParams({
    required this.groupId,
    required this.year,
    required this.month,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OverallBudgetStatsParams &&
          runtimeType == other.runtimeType &&
          groupId == other.groupId &&
          year == other.year &&
          month == other.month;

  @override
  int get hashCode => groupId.hashCode ^ year.hashCode ^ month.hashCode;
}

/// Provider for overall group budget stats
/// Fetches overall budget statistics for the entire group for a specific month
final overallBudgetStatsProvider = FutureProvider.family<
    OverallGroupBudgetStatsEntity?, OverallBudgetStatsParams>(
  (ref, params) async {
    final repository = ref.watch(budgetRepositoryProvider);

    final result = await repository.getOverallGroupBudgetStats(
      groupId: params.groupId,
      year: params.year,
      month: params.month,
    );

    return result.fold(
      (failure) => null, // Return null on failure
      (stats) => stats as OverallGroupBudgetStatsEntity?,
    );
  },
);

/// Provider for current month's overall budget stats (convenience provider)
final currentMonthOverallStatsProvider =
    FutureProvider.family<OverallGroupBudgetStatsEntity?, String>(
  (ref, groupId) async {
    final now = DateTime.now();
    final statsParams = OverallBudgetStatsParams(
      groupId: groupId,
      year: now.year,
      month: now.month,
    );

    return await ref.watch(overallBudgetStatsProvider(statsParams).future);
  },
);
