import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/income_source_entity.dart';
import '../repositories/budget_repository.dart';

/// Use case for adding a single income source
///
/// Implements FR-003 (income amount validation) and FR-004 (income types)
///
/// Validates and adds a new income source to the user's budget
class AddIncomeSourceUseCase {
  final BudgetRepository repository;

  AddIncomeSourceUseCase(this.repository);

  /// Add a new income source
  ///
  /// Parameters:
  /// - incomeSource: The income source entity to add
  ///
  /// Returns:
  /// - Right(IncomeSourceEntity) with server-generated ID on success
  /// - Left(Failure) on validation or persistence error
  ///
  /// Validation Rules (FR-003, FR-004):
  /// - amount >= 0 (no negative income)
  /// - type must be one of: salary, freelance, investment, other, custom
  /// - if type = custom, customTypeName must be provided
  /// - if type != custom, customTypeName must be null
  Future<Either<Failure, IncomeSourceEntity>> call(
      IncomeSourceEntity incomeSource) async {
    // FR-003: Validate amount is non-negative
    if (incomeSource.amount < 0) {
      return Left(ValidationFailure('Income amount cannot be negative'));
    }

    // FR-004: Validate income type and custom name consistency
    if (incomeSource.type == IncomeType.custom) {
      if (incomeSource.customTypeName == null ||
          incomeSource.customTypeName!.trim().isEmpty) {
        return Left(ValidationFailure(
          'Custom income type requires a type name',
        ));
      }
    } else {
      if (incomeSource.customTypeName != null) {
        return Left(ValidationFailure(
          'Custom type name should only be provided for custom income type',
        ));
      }
    }

    // Validate using entity's own validation
    if (!incomeSource.isValid) {
      return Left(ValidationFailure('Income source data is invalid'));
    }

    // Add to repository
    return await repository.addIncomeSource(incomeSource);
  }

  /// Validate income source without persisting
  ///
  /// Useful for real-time form validation
  Either<Failure, Unit> validate(IncomeSourceEntity incomeSource) {
    // Amount validation
    if (incomeSource.amount < 0) {
      return Left(ValidationFailure('Income amount cannot be negative'));
    }

    // Type-specific validation
    if (incomeSource.type == IncomeType.custom) {
      if (incomeSource.customTypeName == null ||
          incomeSource.customTypeName!.trim().isEmpty) {
        return Left(ValidationFailure(
          'Custom income type requires a type name',
        ));
      }

      // Validate custom name length (max 100 chars per data model)
      if (incomeSource.customTypeName!.length > 100) {
        return Left(ValidationFailure(
          'Custom type name cannot exceed 100 characters',
        ));
      }
    }

    return const Right(unit);
  }
}
