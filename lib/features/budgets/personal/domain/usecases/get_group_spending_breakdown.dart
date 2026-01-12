import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../entities/group_spending_breakdown.dart';
import '../repositories/personal_budget_repository.dart';

/// Use case to get group spending breakdown for a member.
/// Feature: 001-group-budget-wizard, Task: T048
///
/// Fetches the hierarchical "Spesa Gruppo" breakdown with subcategories.
class GetGroupSpendingBreakdown {
  const GetGroupSpendingBreakdown({required this.repository});

  final PersonalBudgetRepository repository;

  Future<Either<Failure, GroupSpendingBreakdown>> call(
    GetGroupSpendingBreakdownParams params,
  ) async {
    // Validate parameters
    if (params.userId.isEmpty) {
      return const Left(ValidationFailure('User ID cannot be empty'));
    }
    if (params.groupId.isEmpty) {
      return const Left(ValidationFailure('Group ID cannot be empty'));
    }

    // Fetch breakdown from repository
    return await repository.getGroupSpendingBreakdown(
      userId: params.userId,
      groupId: params.groupId,
      year: params.year,
      month: params.month,
    );
  }
}

/// Parameters for GetGroupSpendingBreakdown use case.
class GetGroupSpendingBreakdownParams extends Equatable {
  const GetGroupSpendingBreakdownParams({
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
