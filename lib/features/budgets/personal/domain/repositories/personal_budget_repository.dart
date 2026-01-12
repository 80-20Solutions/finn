import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/group_spending_breakdown.dart';
import '../entities/personal_budget.dart';

/// Personal budget repository interface.
/// Feature: 001-group-budget-wizard, Task: T048, T060
abstract class PersonalBudgetRepository {
  /// Get group spending breakdown for a member.
  ///
  /// Returns the hierarchical "Spesa Gruppo" breakdown with subcategories
  /// for the specified member, group, year, and month.
  Future<Either<Failure, GroupSpendingBreakdown>> getGroupSpendingBreakdown({
    required String userId,
    required String groupId,
    required int year,
    required int month,
  });

  /// Calculate personal budget including group allocation.
  ///
  /// Returns the complete budget breakdown:
  /// - Personal budget + Group allocation = Total budget
  /// - Personal spent + Group spent = Total spent
  ///
  /// Task: T060 (User Story 3)
  Future<Either<Failure, PersonalBudget>> calculatePersonalBudget({
    required String userId,
    required String groupId,
    required int year,
    required int month,
  });
}
