import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/budget_summary_entity.dart';
import '../repositories/budget_repository.dart';

/// Use case for calculating available budget
///
/// Implements FR-008 formula: availableBudget = totalIncome - savingsGoal - groupExpenseLimit
///
/// Computes the amount of money available for spending after accounting for
/// savings goals and group expense assignments
class CalculateAvailableBudgetUseCase {
  final BudgetRepository repository;

  CalculateAvailableBudgetUseCase(this.repository);

  /// Calculate available budget for a user
  ///
  /// Parameters:
  /// - userId: The user to calculate budget for
  ///
  /// Returns:
  /// - Right(int) with available budget amount in cents
  /// - Left(Failure) on calculation error
  ///
  /// Formula (FR-008):
  /// availableBudget = totalIncome - savingsGoal - totalGroupExpenses
  ///
  /// Notes:
  /// - Can be negative if group expenses + savings > income
  /// - Returns 0 if no income sources exist
  Future<Either<Failure, int>> call(String userId) async {
    return await repository.getAvailableBudget(userId);
  }

  /// Get complete budget summary with breakdown
  ///
  /// Returns full BudgetSummaryEntity with:
  /// - totalIncome (sum of all income sources)
  /// - savingsGoal (current goal amount)
  /// - totalGroupExpenses (sum of all spending limits)
  /// - availableBudget (calculated using FR-008 formula)
  /// - boolean flags for each component
  ///
  /// Use this for displaying detailed budget breakdowns in UI
  Future<Either<Failure, BudgetSummaryEntity>> getBudgetSummary(
      String userId) async {
    return await repository.getBudgetSummary(userId);
  }

  /// Check if budget is in deficit (available budget is negative)
  ///
  /// Returns:
  /// - Right(true) if available budget < 0 (deficit)
  /// - Right(false) if available budget >= 0 (balanced or surplus)
  /// - Left(Failure) on calculation error
  ///
  /// Use for displaying warnings when expenses exceed income
  Future<Either<Failure, bool>> isInDeficit(String userId) async {
    final summaryResult = await repository.getBudgetSummary(userId);

    return summaryResult.fold(
      (failure) => Left(failure),
      (summary) => Right(summary.isInDeficit),
    );
  }

  /// Check if savings goal needs adjustment due to group expenses
  ///
  /// Returns:
  /// - Right(true) if savings needs to be reduced to accommodate group expenses
  /// - Right(false) if current budget allocation is valid
  /// - Left(Failure) on calculation error
  ///
  /// Used by FR-015 for detecting when auto-adjustment is needed
  Future<Either<Failure, bool>> needsSavingsAdjustment(String userId) async {
    final summaryResult = await repository.getBudgetSummary(userId);

    return summaryResult.fold(
      (failure) => Left(failure),
      (summary) => Right(summary.needsSavingsAdjustment),
    );
  }

  /// Calculate recommended savings goal to balance budget
  ///
  /// Returns the maximum savings goal that would result in
  /// availableBudget = 0 (balanced budget)
  ///
  /// Formula: recommendedSavings = totalIncome - totalGroupExpenses
  ///
  /// Can be negative if group expenses > income (indicates deficit)
  Future<Either<Failure, int>> getRecommendedSavingsGoal(String userId) async {
    final summaryResult = await repository.getBudgetSummary(userId);

    return summaryResult.fold(
      (failure) => Left(failure),
      (summary) => Right(summary.recommendedSavingsGoal),
    );
  }
}
