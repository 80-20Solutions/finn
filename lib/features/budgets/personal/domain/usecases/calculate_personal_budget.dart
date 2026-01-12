import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../entities/personal_budget.dart';
import '../repositories/personal_budget_repository.dart';

/// Use case to calculate personal budget including group allocation.
/// Feature: 001-group-budget-wizard, Task: T060
///
/// Calculates the member's total budget by summing:
/// - Personal budget (member's own budget)
/// - Group allocation (member's percentage of group budget)
class CalculatePersonalBudget {
  const CalculatePersonalBudget({required this.repository});

  final PersonalBudgetRepository repository;

  Future<Either<Failure, PersonalBudget>> call(
    CalculatePersonalBudgetParams params,
  ) async {
    // Validate parameters
    if (params.userId.isEmpty) {
      return const Left(ValidationFailure('User ID cannot be empty'));
    }
    if (params.groupId.isEmpty) {
      return const Left(ValidationFailure('Group ID cannot be empty'));
    }

    // Calculate budget from repository
    // Repository handles:
    // 1. Fetching personal budget
    // 2. Fetching group allocation (member's percentage * group budget)
    // 3. Summing total = personal + group
    // 4. Fetching spent amounts (personal + group)
    return await repository.calculatePersonalBudget(
      userId: params.userId,
      groupId: params.groupId,
      year: params.year,
      month: params.month,
    );
  }
}

/// Parameters for CalculatePersonalBudget use case.
class CalculatePersonalBudgetParams extends Equatable {
  const CalculatePersonalBudgetParams({
    required this.userId,
    required this.groupId,
    required this.year,
    required this.month,
  });

  final String userId;
  final String groupId;
  final int year;
  final int month;

  @override
  List<Object?> get props => [userId, groupId, year, month];
}
