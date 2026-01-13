import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/income_source_entity.dart';
import '../entities/savings_goal_entity.dart';
import '../entities/budget_summary_entity.dart';
import '../repositories/budget_repository.dart';

/// Use case for orchestrating the complete personal budget setup wizard
///
/// This use case handles the multi-step wizard flow for initial budget setup:
/// 1. Adding one or more income sources
/// 2. Setting a savings goal (optional)
/// 3. Computing and returning the final budget summary
///
/// Implements FR-001, FR-002 for guided setup flow
class SetupPersonalBudgetUseCase {
  final BudgetRepository repository;

  SetupPersonalBudgetUseCase(this.repository);

  /// Complete the wizard setup with income sources and optional savings goal
  ///
  /// Parameters:
  /// - userId: The user completing setup
  /// - incomeSources: List of income sources to add (at least one recommended)
  /// - savingsGoal: Optional savings goal (can be null per FR-022)
  ///
  /// Returns:
  /// - Right(BudgetSummaryEntity) on success with computed budget
  /// - Left(Failure) on any error during setup
  ///
  /// Business Rules:
  /// - Allows zero income sources per FR-022 (totalIncome = 0)
  /// - Savings goal must be < totalIncome if provided (FR-007)
  /// - All monetary values in cents (integer)
  Future<Either<Failure, BudgetSummaryEntity>> call({
    required String userId,
    required List<IncomeSourceEntity> incomeSources,
    SavingsGoalEntity? savingsGoal,
  }) async {
    try {
      // Step 1: Add all income sources (can be empty per FR-022)
      if (incomeSources.isNotEmpty) {
        final incomeResult = await repository.addIncomeSources(incomeSources);
        if (incomeResult.isLeft()) {
          return incomeResult.fold(
            (failure) => Left(failure),
            (_) => throw Exception('Unexpected success in error path'),
          );
        }
      }

      // Step 2: Calculate total income
      final totalIncomeResult = await repository.getTotalIncome(userId);
      if (totalIncomeResult.isLeft()) {
        return totalIncomeResult.fold(
          (failure) => Left(failure),
          (_) => throw Exception('Unexpected success in error path'),
        );
      }

      final totalIncome = totalIncomeResult.getOrElse(() => 0);

      // Step 3: Set savings goal if provided
      if (savingsGoal != null) {
        // FR-007: Validate savings goal < totalIncome
        if (savingsGoal.amount >= totalIncome && totalIncome > 0) {
          return Left(ValidationFailure(
            'Savings goal (${savingsGoal.amount}) must be less than total income ($totalIncome)',
          ));
        }

        final savingsResult = await repository.setSavingsGoal(savingsGoal);
        if (savingsResult.isLeft()) {
          return savingsResult.fold(
            (failure) => Left(failure),
            (_) => throw Exception('Unexpected success in error path'),
          );
        }
      }

      // Step 4: Get final budget summary
      final summaryResult = await repository.getBudgetSummary(userId);
      return summaryResult;
    } catch (e) {
      return Left(ServerFailure('Failed to complete budget setup: ${e.toString()}'));
    }
  }

  /// Validate that the setup can proceed
  ///
  /// Checks:
  /// - At least one income source OR explicitly allowing zero income
  /// - Savings goal < total income if both provided
  ///
  /// Returns validation errors if any
  Either<Failure, Unit> validateSetup({
    required List<IncomeSourceEntity> incomeSources,
    SavingsGoalEntity? savingsGoal,
  }) {
    final totalIncome = incomeSources.fold<int>(
      0,
      (sum, source) => sum + source.amount,
    );

    // FR-007: Savings goal validation
    if (savingsGoal != null && savingsGoal.amount >= totalIncome && totalIncome > 0) {
      return Left(ValidationFailure(
        'Savings goal cannot be greater than or equal to total income',
      ));
    }

    // FR-003: All income amounts must be non-negative (checked in entities)
    final hasNegativeIncome = incomeSources.any((source) => source.amount < 0);
    if (hasNegativeIncome) {
      return Left(ValidationFailure('Income amounts cannot be negative'));
    }

    return const Right(unit);
  }
}
