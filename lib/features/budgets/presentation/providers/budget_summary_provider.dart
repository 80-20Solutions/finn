import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/budget_summary_entity.dart';
import '../../domain/usecases/calculate_available_budget_usecase.dart';
import 'budget_repository_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

/// Use case provider for budget calculations
final calculateAvailableBudgetUseCaseProvider =
    Provider<CalculateAvailableBudgetUseCase>((ref) {
  return CalculateAvailableBudgetUseCase(
    ref.watch(budgetRepositoryProvider),
  );
});

/// Provider for watching budget summary
///
/// Provides real-time stream of complete budget summary
/// Automatically recomputes when income sources, savings goal, or
/// group expense assignments change
///
/// Implements FR-008 formula: availableBudget = totalIncome - savingsGoal - groupExpenseLimit
final budgetSummaryProvider =
    StreamProvider.autoDispose<BudgetSummaryEntity>((ref) {
  // Get current user ID from auth
  final authState = ref.watch(authProvider);
  final userId = authState.user?.id;

  if (userId == null) {
    // Return empty budget summary for unauthenticated users
    return Stream.value(BudgetSummaryEntity.fromComponents(
      userId: '',
      totalIncome: 0,
      savingsGoal: 0,
      totalGroupExpenses: 0,
      hasIncome: false,
      hasSavingsGoal: false,
      hasGroupAssignments: false,
    ));
  }

  // Watch budget summary from repository
  return ref.watch(budgetRepositoryProvider).watchBudgetSummary(userId);
});

/// Provider for available budget amount only
///
/// Extracts just the available budget integer from the summary
/// Useful for widgets that only need the single value
final availableBudgetProvider = Provider.autoDispose<AsyncValue<int>>((ref) {
  final summaryAsync = ref.watch(budgetSummaryProvider);

  return summaryAsync.when(
    data: (summary) => AsyncValue.data(summary.availableBudget),
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
  );
});

/// Provider for checking if budget is in deficit
///
/// Returns true if available budget is negative
/// Used for displaying warnings/alerts
final isInDeficitProvider = Provider.autoDispose<bool>((ref) {
  final summaryAsync = ref.watch(budgetSummaryProvider);

  return summaryAsync.when(
    data: (summary) => summary.isInDeficit,
    loading: () => false,
    error: (_, __) => false,
  );
});

/// Provider for checking if savings adjustment is needed
///
/// Returns true if group expenses exceed available budget
/// Triggers automatic savings goal adjustment per FR-015
final needsSavingsAdjustmentProvider = Provider.autoDispose<bool>((ref) {
  final summaryAsync = ref.watch(budgetSummaryProvider);

  return summaryAsync.when(
    data: (summary) => summary.needsSavingsAdjustment,
    loading: () => false,
    error: (_, __) => false,
  );
});

/// Provider for recommended savings goal
///
/// Calculates the maximum savings goal that would balance the budget
/// Formula: totalIncome - totalGroupExpenses
final recommendedSavingsGoalProvider = Provider.autoDispose<int>((ref) {
  final summaryAsync = ref.watch(budgetSummaryProvider);

  return summaryAsync.when(
    data: (summary) => summary.recommendedSavingsGoal,
    loading: () => 0,
    error: (_, __) => 0,
  );
});

/// Provider for budget status summary
///
/// Returns a human-readable status of the budget:
/// - "balanced": available budget = 0
/// - "surplus": available budget > 0
/// - "deficit": available budget < 0
final budgetStatusProvider = Provider.autoDispose<String>((ref) {
  final summaryAsync = ref.watch(budgetSummaryProvider);

  return summaryAsync.when(
    data: (summary) {
      if (summary.isBalanced) return 'balanced';
      if (summary.hasSurplus) return 'surplus';
      return 'deficit';
    },
    loading: () => 'loading',
    error: (_, __) => 'error',
  );
});

/// Provider for budget completeness check
///
/// Returns true if user has completed budget setup:
/// - Has at least one income source
/// - Has set a savings goal (optional but recommended)
final isBudgetCompleteProvider = Provider.autoDispose<bool>((ref) {
  final summaryAsync = ref.watch(budgetSummaryProvider);

  return summaryAsync.when(
    data: (summary) => summary.hasIncome, // Minimum requirement
    loading: () => false,
    error: (_, __) => false,
  );
});

/// Provider for budget breakdown percentages
///
/// Calculates percentage breakdown of income allocation:
/// - Savings percentage: (savingsGoal / totalIncome) * 100
/// - Group expenses percentage: (totalGroupExpenses / totalIncome) * 100
/// - Available percentage: (availableBudget / totalIncome) * 100
final budgetBreakdownPercentagesProvider =
    Provider.autoDispose<Map<String, double>>((ref) {
  final summaryAsync = ref.watch(budgetSummaryProvider);

  return summaryAsync.when(
    data: (summary) {
      if (summary.totalIncome == 0) {
        return {
          'savings': 0.0,
          'groupExpenses': 0.0,
          'available': 0.0,
        };
      }

      final savingsPercent = (summary.savingsGoal / summary.totalIncome) * 100;
      final groupExpensesPercent =
          (summary.totalGroupExpenses / summary.totalIncome) * 100;
      final availablePercent =
          (summary.availableBudget / summary.totalIncome) * 100;

      return {
        'savings': savingsPercent,
        'groupExpenses': groupExpensesPercent,
        'available': availablePercent,
      };
    },
    loading: () => {
      'savings': 0.0,
      'groupExpenses': 0.0,
      'available': 0.0,
    },
    error: (_, __) => {
      'savings': 0.0,
      'groupExpenses': 0.0,
      'available': 0.0,
    },
  );
});
