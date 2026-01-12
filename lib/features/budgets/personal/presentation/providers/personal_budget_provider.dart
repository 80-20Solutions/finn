import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/group_spending_breakdown.dart';
import '../../domain/entities/personal_budget.dart';
import '../../domain/usecases/calculate_personal_budget.dart';
import '../../domain/usecases/get_group_spending_breakdown.dart';

/// Personal budget provider with group spending breakdown.
/// Feature: 001-group-budget-wizard, Task: T054, T062
///
/// Manages personal budget state including the group spending breakdown.

/// State for personal budget view.
class PersonalBudgetState {
  const PersonalBudgetState({
    this.groupBreakdown,
    this.personalBudget,
    this.isLoading = false,
    this.errorMessage,
  });

  final GroupSpendingBreakdown? groupBreakdown;
  final PersonalBudget? personalBudget; // Task: T062
  final bool isLoading;
  final String? errorMessage;

  PersonalBudgetState copyWith({
    GroupSpendingBreakdown? groupBreakdown,
    PersonalBudget? personalBudget,
    bool? isLoading,
    String? errorMessage,
  }) {
    return PersonalBudgetState(
      groupBreakdown: groupBreakdown ?? this.groupBreakdown,
      personalBudget: personalBudget ?? this.personalBudget,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

/// Personal budget state notifier.
class PersonalBudgetNotifier extends StateNotifier<PersonalBudgetState> {
  PersonalBudgetNotifier({
    required this.getGroupSpendingBreakdown,
    required this.calculatePersonalBudget,
  }) : super(const PersonalBudgetState());

  final GetGroupSpendingBreakdown getGroupSpendingBreakdown;
  final CalculatePersonalBudget calculatePersonalBudget;

  /// Load complete budget data (personal budget + group breakdown).
  /// Task: T062
  Future<void> loadBudgetData({
    required String userId,
    required String groupId,
    required int year,
    required int month,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    // Load personal budget (includes group allocation)
    final budgetResult = await calculatePersonalBudget(
      CalculatePersonalBudgetParams(
        userId: userId,
        groupId: groupId,
        year: year,
        month: month,
      ),
    );

    // Load group breakdown for expandable view
    final breakdownResult = await getGroupSpendingBreakdown(
      GetGroupSpendingBreakdownParams(
        userId: userId,
        groupId: groupId,
        year: year,
        month: month,
      ),
    );

    // Handle results
    PersonalBudget? budget;
    GroupSpendingBreakdown? breakdown;
    String? error;

    budgetResult.fold(
      (failure) => error = failure.message,
      (result) => budget = result,
    );

    breakdownResult.fold(
      (failure) => error ??= failure.message,
      (result) => breakdown = result,
    );

    state = state.copyWith(
      isLoading: false,
      personalBudget: budget,
      groupBreakdown: breakdown,
      errorMessage: error,
    );
  }

  /// Load group spending breakdown for the current user.
  Future<void> loadGroupBreakdown({
    required String userId,
    required String groupId,
    required int year,
    required int month,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    final result = await getGroupSpendingBreakdown(
      GetGroupSpendingBreakdownParams(
        userId: userId,
        groupId: groupId,
        year: year,
        month: month,
      ),
    );

    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        errorMessage: failure.message,
      ),
      (breakdown) => state = state.copyWith(
        isLoading: false,
        groupBreakdown: breakdown,
        errorMessage: null,
      ),
    );
  }

  /// Refresh all budget data.
  Future<void> refresh({
    required String userId,
    required String groupId,
    required int year,
    required int month,
  }) async {
    await loadBudgetData(
      userId: userId,
      groupId: groupId,
      year: year,
      month: month,
    );
  }
}

/// Provider for personal budget state.
///
/// NOTE: Dependencies need to be wired up in main provider setup.
final personalBudgetProvider =
    StateNotifierProvider.family<PersonalBudgetNotifier, PersonalBudgetState, String>(
  (ref, userId) {
    // TODO: Wire up dependencies (GetGroupSpendingBreakdown use case)
    throw UnimplementedError(
      'PersonalBudgetProvider dependencies not yet wired up. '
      'Need to provide GetGroupSpendingBreakdown use case.',
    );
  },
);
