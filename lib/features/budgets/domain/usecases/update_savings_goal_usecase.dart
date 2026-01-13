import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/savings_goal_entity.dart';
import '../repositories/budget_repository.dart';

/// Use case for updating a user's savings goal
///
/// Implements FR-007 (savings goal < totalIncome validation)
///
/// Updates or creates the savings goal with validation against total income
class UpdateSavingsGoalUseCase {
  final BudgetRepository repository;

  UpdateSavingsGoalUseCase(this.repository);

  /// Update the savings goal for a user
  ///
  /// Parameters:
  /// - userId: The user whose goal to update
  /// - newAmount: The new savings goal amount in cents
  ///
  /// Returns:
  /// - Right(SavingsGoalEntity) on success
  /// - Left(ValidationFailure) if newAmount >= totalIncome
  /// - Left(Failure) on other errors
  ///
  /// Business Rules (FR-007):
  /// - Savings goal must be < totalIncome
  /// - Allows savings goal = 0
  /// - Resets originalAmount to null (user manual update)
  Future<Either<Failure, SavingsGoalEntity>> call({
    required String userId,
    required int newAmount,
  }) async {
    // FR-007: Validate savings goal < totalIncome
    final totalIncomeResult = await repository.getTotalIncome(userId);

    if (totalIncomeResult.isLeft()) {
      return totalIncomeResult.fold(
        (failure) => Left(failure),
        (_) => throw Exception('Unexpected success in error path'),
      );
    }

    final totalIncome = totalIncomeResult.getOrElse(() => 0);

    // FR-007: Savings goal validation
    if (newAmount >= totalIncome && totalIncome > 0) {
      return Left(ValidationFailure(
        'Savings goal ($newAmount) must be less than total income ($totalIncome)',
      ));
    }

    // Non-negative validation
    if (newAmount < 0) {
      return Left(ValidationFailure('Savings goal cannot be negative'));
    }

    // Update the savings goal
    // This resets originalAmount to null (manual user update)
    return await repository.updateSavingsGoalAmount(
      userId: userId,
      newAmount: newAmount,
    );
  }

  /// Validate savings goal amount against current total income
  ///
  /// Parameters:
  /// - userId: The user to validate for
  /// - newAmount: The proposed savings goal amount
  ///
  /// Returns:
  /// - Right(Unit) if valid
  /// - Left(ValidationFailure) if invalid
  ///
  /// Use for real-time form validation before calling the use case
  Future<Either<Failure, Unit>> validate({
    required String userId,
    required int newAmount,
  }) async {
    // Non-negative validation
    if (newAmount < 0) {
      return Left(ValidationFailure('Savings goal cannot be negative'));
    }

    // Get total income for validation
    final totalIncomeResult = await repository.getTotalIncome(userId);

    if (totalIncomeResult.isLeft()) {
      return totalIncomeResult.fold(
        (failure) => Left(failure),
        (_) => throw Exception('Unexpected success in error path'),
      );
    }

    final totalIncome = totalIncomeResult.getOrElse(() => 0);

    // FR-007: Savings goal < totalIncome validation
    if (newAmount >= totalIncome && totalIncome > 0) {
      return Left(ValidationFailure(
        'Savings goal must be less than total income',
      ));
    }

    return const Right(unit);
  }

  /// Calculate maximum allowed savings goal for a user
  ///
  /// Returns totalIncome - 1 (since savings must be < income)
  /// Returns 0 if totalIncome <= 0
  Future<Either<Failure, int>> getMaxAllowedSavings(String userId) async {
    final totalIncomeResult = await repository.getTotalIncome(userId);

    return totalIncomeResult.fold(
      (failure) => Left(failure),
      (totalIncome) {
        if (totalIncome <= 0) return const Right(0);
        return Right(totalIncome - 1);
      },
    );
  }
}
