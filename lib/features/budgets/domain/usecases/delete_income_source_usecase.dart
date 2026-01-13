import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/budget_repository.dart';

/// Use case for deleting an income source
///
/// Implements cascade to budget recalculation:
/// - Removes income source from database
/// - Triggers automatic budget recalculation
/// - Updates totalIncome in budget summary
/// - May trigger savings adjustment if needed (handled by watchers)
///
/// Part of User Story 2: Multiple Income Source Management
class DeleteIncomeSourceUseCase {
  final BudgetRepository repository;

  DeleteIncomeSourceUseCase(this.repository);

  /// Delete an income source by ID
  ///
  /// The deletion cascades to:
  /// - Budget summary recalculation (totalIncome decreases)
  /// - Potential savings adjustment if budget becomes negative
  /// - UI updates through reactive streams
  ///
  /// Returns Unit on success, Failure on error
  Future<Either<Failure, Unit>> call(String incomeSourceId) async {
    // Validate ID is not empty
    if (incomeSourceId.trim().isEmpty) {
      return Left(
        ValidationFailure('Income source ID cannot be empty'),
      );
    }

    // Delete from repository
    try {
      final result = await repository.deleteIncomeSource(incomeSourceId);

      return result.fold(
        (failure) => Left(failure),
        (success) {
          // Deletion successful
          // Budget recalculation happens automatically via:
          // 1. Local Drift delete triggers
          // 2. BudgetSummaryProvider watching income sources
          // 3. Reactive stream updates UI
          return const Right(unit);
        },
      );
    } catch (e) {
      return Left(
        ServerFailure('Failed to delete income source: ${e.toString()}'),
      );
    }
  }

  /// Delete all income sources for a user
  ///
  /// Used for:
  /// - Resetting user's budget
  /// - User account deletion cleanup
  /// - Testing scenarios
  ///
  /// Returns Unit on success, Failure on error
  Future<Either<Failure, Unit>> deleteAllForUser(String userId) async {
    // Validate user ID is not empty
    if (userId.trim().isEmpty) {
      return Left(
        ValidationFailure('User ID cannot be empty'),
      );
    }

    try {
      // Get all income sources for user
      final sourcesResult = await repository.getIncomeSources(userId);

      return sourcesResult.fold(
        (failure) => Left(failure),
        (sources) async {
          // Delete each source
          for (final source in sources) {
            final deleteResult = await repository.deleteIncomeSource(source.id);

            // If any deletion fails, return that failure
            if (deleteResult.isLeft()) {
              return deleteResult.fold(
                (failure) => Left(failure),
                (_) => const Right(unit), // Won't happen since isLeft() is true
              );
            }
          }

          return const Right(unit);
        },
      );
    } catch (e) {
      return Left(
        ServerFailure(
          'Failed to delete income sources for user: ${e.toString()}',
        ),
      );
    }
  }
}
