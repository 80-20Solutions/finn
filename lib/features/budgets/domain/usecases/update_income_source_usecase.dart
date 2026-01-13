import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/income_source_entity.dart';
import '../repositories/budget_repository.dart';

/// Use case for updating an existing income source
///
/// Implements FR-003, FR-004 validation:
/// - Amount must be >= 0
/// - Custom type requires customTypeName
/// - Updates trigger budget recalculation
///
/// Part of User Story 2: Multiple Income Source Management
class UpdateIncomeSourceUseCase {
  final BudgetRepository repository;

  UpdateIncomeSourceUseCase(this.repository);

  /// Update an existing income source with validation
  ///
  /// Validates:
  /// - Amount is non-negative (FR-003)
  /// - Custom type has a name (FR-004)
  /// - Income source exists
  ///
  /// Returns updated entity on success, Failure on error
  Future<Either<Failure, IncomeSourceEntity>> call(
    IncomeSourceEntity updatedSource,
  ) async {
    // Validate amount is non-negative (FR-003)
    if (updatedSource.amount < 0) {
      return Left(
        ValidationFailure('Income amount cannot be negative'),
      );
    }

    // Validate custom type has a name (FR-004)
    if (updatedSource.type == IncomeType.custom) {
      if (updatedSource.customTypeName == null ||
          updatedSource.customTypeName!.trim().isEmpty) {
        return Left(
          ValidationFailure('Custom income type requires a type name'),
        );
      }

      // Validate custom type name length (data model constraint)
      if (updatedSource.customTypeName!.length > 100) {
        return Left(
          ValidationFailure(
            'Custom type name must be 100 characters or less',
          ),
        );
      }
    }

    // Validate entity is valid
    if (!updatedSource.isValid) {
      return Left(
        ValidationFailure('Invalid income source'),
      );
    }

    // Update in repository
    try {
      return await repository.updateIncomeSource(updatedSource);
    } catch (e) {
      return Left(
        ServerFailure('Failed to update income source: ${e.toString()}'),
      );
    }
  }
}
