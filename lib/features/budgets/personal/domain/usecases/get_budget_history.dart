import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../entities/personal_budget.dart';
import '../repositories/personal_budget_repository.dart';

/// Use case to get budget history for reporting.
/// Feature: 001-group-budget-wizard, Task: T067
///
/// Retrieves historical budget data across multiple months for:
/// - Trend analysis
/// - Spending patterns
/// - Budget effectiveness reporting
class GetBudgetHistory {
  const GetBudgetHistory({required this.repository});

  final PersonalBudgetRepository repository;

  Future<Either<Failure, List<PersonalBudget>>> call(
    GetBudgetHistoryParams params,
  ) async {
    // Validate parameters
    if (params.userId.isEmpty) {
      return const Left(ValidationFailure('User ID cannot be empty'));
    }
    if (params.groupId.isEmpty) {
      return const Left(ValidationFailure('Group ID cannot be empty'));
    }
    if (params.startYear <= 0 || params.startMonth < 1 || params.startMonth > 12) {
      return const Left(ValidationFailure('Invalid start date'));
    }
    if (params.endYear <= 0 || params.endMonth < 1 || params.endMonth > 12) {
      return const Left(ValidationFailure('Invalid end date'));
    }

    // Validate date range
    final startDate = DateTime(params.startYear, params.startMonth);
    final endDate = DateTime(params.endYear, params.endMonth);
    if (endDate.isBefore(startDate)) {
      return const Left(
        ValidationFailure('End date must be after or equal to start date'),
      );
    }

    // Fetch budget history from repository
    // TODO: Implement when repository method is ready
    throw UnimplementedError(
      'GetBudgetHistory not yet implemented. '
      'Requires PersonalBudgetRepository.getBudgetHistory method.',
    );
  }
}

/// Parameters for GetBudgetHistory use case.
class GetBudgetHistoryParams extends Equatable {
  const GetBudgetHistoryParams({
    required this.userId,
    required this.groupId,
    required this.startYear,
    required this.startMonth,
    required this.endYear,
    required this.endMonth,
  });

  final String userId;
  final String groupId;
  final int startYear;
  final int startMonth;
  final int endYear;
  final int endMonth;

  /// Get number of months in this range.
  int get monthCount {
    final start = DateTime(startYear, startMonth);
    final end = DateTime(endYear, endMonth);
    return ((end.year - start.year) * 12) + (end.month - start.month) + 1;
  }

  @override
  List<Object?> get props => [
        userId,
        groupId,
        startYear,
        startMonth,
        endYear,
        endMonth,
      ];
}
