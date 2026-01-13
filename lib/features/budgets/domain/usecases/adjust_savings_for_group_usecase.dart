import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/savings_goal_entity.dart';
import '../entities/budget_summary_entity.dart';
import '../repositories/budget_repository.dart';

/// Use case for automatically adjusting savings when group expenses exceed available budget
///
/// Implements FR-015:
/// - When group expenses > available budget, auto-reduce savings goal
/// - Maintains minimum viable budget: totalIncome >= groupExpenses + adjustedSavings
/// - Tracks original savings amount for restoration
/// - Triggers notification to inform user (FR-016)
///
/// Part of User Story 3: Group Membership and Expense Assignment
class AdjustSavingsForGroupUseCase {
  final BudgetRepository repository;

  AdjustSavingsForGroupUseCase(this.repository);

  /// Automatically adjust savings goal to accommodate group expenses
  ///
  /// Formula:
  /// - If totalIncome - savingsGoal - groupExpenses < 0:
  ///   - adjustedSavings = totalIncome - groupExpenses
  ///   - If adjustedSavings < 0: set to 0
  ///
  /// Returns:
  /// - Right(SavingsAdjustment) with old and new amounts if adjustment made
  /// - Right(null) if no adjustment needed
  /// - Left(Failure) on error
  Future<Either<Failure, SavingsAdjustment?>> call({
    required String userId,
  }) async {
    // Validate user ID
    if (userId.trim().isEmpty) {
      return Left(ValidationFailure('User ID cannot be empty'));
    }

    try {
      // Get current budget summary
      final summaryResult = await repository.getBudgetSummary(userId);

      return await summaryResult.fold(
        (failure) => Left(failure),
        (summary) async {
          // Check if adjustment is needed
          if (!summary.needsSavingsAdjustment) {
            return const Right(null); // No adjustment needed
          }

          // Get current savings goal
          final savingsResult = await repository.getSavingsGoal(userId);

          return await savingsResult.fold(
            (failure) => Left(failure),
            (currentSavings) async {
              if (currentSavings == null) {
                return Left(
                  ValidationFailure(
                    'Cannot adjust savings: no savings goal exists',
                  ),
                );
              }

              // Calculate new savings amount
              // Formula: newSavings = max(0, totalIncome - groupExpenses)
              final recommendedSavings = summary.recommendedSavingsGoal;

              // Store original amount if this is first adjustment
              final originalAmount = currentSavings.isAdjusted
                  ? currentSavings.originalAmount
                  : currentSavings.amount;

              // Create adjusted savings goal
              final adjustedSavings = SavingsGoalEntity(
                id: currentSavings.id,
                userId: userId,
                amount: recommendedSavings,
                originalAmount: originalAmount,
                adjustedAt: DateTime.now(),
                createdAt: currentSavings.createdAt,
                updatedAt: DateTime.now(),
              );

              // Update in repository
              final updateResult = await repository.updateSavingsGoal(
                adjustedSavings,
              );

              return updateResult.fold(
                (failure) => Left(failure),
                (updatedGoal) => Right(
                  SavingsAdjustment(
                    originalAmount: currentSavings.amount,
                    adjustedAmount: recommendedSavings,
                    reason: SavingsAdjustmentReason.groupExpensesExceeded,
                    adjustedAt: DateTime.now(),
                  ),
                ),
              );
            },
          );
        },
      );
    } catch (e) {
      return Left(
        ServerFailure('Failed to adjust savings: ${e.toString()}'),
      );
    }
  }

  /// Restore original savings goal if possible
  ///
  /// Used when:
  /// - User manually adjusts after auto-adjustment
  /// - Group expenses are reduced
  /// - User leaves group
  ///
  /// Returns restored savings goal on success
  Future<Either<Failure, SavingsGoalEntity>> restoreOriginalSavings({
    required String userId,
  }) async {
    // Validate user ID
    if (userId.trim().isEmpty) {
      return Left(ValidationFailure('User ID cannot be empty'));
    }

    try {
      // Get current savings goal
      final savingsResult = await repository.getSavingsGoal(userId);

      return await savingsResult.fold(
        (failure) => Left(failure),
        (currentSavings) async {
          if (currentSavings == null) {
            return Left(
              ValidationFailure('No savings goal to restore'),
            );
          }

          if (!currentSavings.isAdjusted) {
            return Right(currentSavings); // Already at original amount
          }

          // Check if restoration is possible without going into deficit
          final summaryResult = await repository.getBudgetSummary(userId);

          return await summaryResult.fold(
            (failure) => Left(failure),
            (summary) async {
              // Calculate what available budget would be with original savings
              final availableWithOriginal = summary.totalIncome -
                  currentSavings.originalAmount -
                  summary.totalGroupExpenses;

              if (availableWithOriginal < 0) {
                return Left(
                  ValidationFailure(
                    'Cannot restore original savings: would create deficit of ${availableWithOriginal.abs()} cents',
                  ),
                );
              }

              // Restore original amount
              final restoredSavings = SavingsGoalEntity(
                id: currentSavings.id,
                userId: userId,
                amount: currentSavings.originalAmount,
                originalAmount: currentSavings.originalAmount,
                adjustedAt: null, // Clear adjustment timestamp
                createdAt: currentSavings.createdAt,
                updatedAt: DateTime.now(),
              );

              return await repository.updateSavingsGoal(restoredSavings);
            },
          );
        },
      );
    } catch (e) {
      return Left(
        ServerFailure('Failed to restore savings: ${e.toString()}'),
      );
    }
  }
}

/// Data class for savings adjustment information
class SavingsAdjustment {
  final int originalAmount;
  final int adjustedAmount;
  final SavingsAdjustmentReason reason;
  final DateTime adjustedAt;

  SavingsAdjustment({
    required this.originalAmount,
    required this.adjustedAmount,
    required this.reason,
    required this.adjustedAt,
  });

  int get difference => originalAmount - adjustedAmount;

  bool get isReduction => adjustedAmount < originalAmount;

  bool get isIncrease => adjustedAmount > originalAmount;
}

/// Reason for savings adjustment
enum SavingsAdjustmentReason {
  groupExpensesExceeded,
  manualAdjustment,
  incomeReduced,
}
